//
//  EnemyPattern.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// Enemy attack patterns with configurable config
enum EnemyPattern: CaseIterable {
    case singleShot
    case tripleShot
    case circleShot
    case aimedShot
    case spiralShot
    
    /// Get the pattern's bullet spawn commands with config
    func getBulletCommands(from position: CGPoint, targetPosition: CGPoint? = nil, config: PatternConfig = PatternConfig()) -> [BulletSpawnCommand] {
        switch self {
        case .singleShot:
            return makeSingleShot(position: position, config: config)
        case .tripleShot:
            return makeTripleShot(position: position, config: config)
        case .circleShot:
            return makeCircleShot(position: position, config: config)
        case .aimedShot:
            return makeAimedShot(position: position, targetPosition: targetPosition, config: config)
        case .spiralShot:
            return makeSpiralShot(position: position, config: config)
        }
    }
    
    // MARK: - Pattern Implementations
    
    private func makeSingleShot(position: CGPoint, config: PatternConfig) -> [BulletSpawnCommand] {
        return [
            BulletSpawnCommand(
                position: position,
                velocity: CGVector(dx: 0, dy: -config.physics.speed),
                bulletType: .enemyBullet,
                physics: config.physics,
                visual: config.visual,
                behavior: config.behavior
            )
        ]
    }
    
    private func makeTripleShot(position: CGPoint, config: PatternConfig) -> [BulletSpawnCommand] {
        let spread = config.spread
        let speed = config.physics.speed
        return [
            makeBulletCommand(position: position, velocity: CGVector(dx: 0, dy: -speed), config: config),
            makeBulletCommand(position: position, velocity: CGVector(dx: -spread, dy: -speed * 0.8), config: config),
            makeBulletCommand(position: position, velocity: CGVector(dx: spread, dy: -speed * 0.8), config: config)
        ]
    }
    
    private func makeCircleShot(position: CGPoint, config: PatternConfig) -> [BulletSpawnCommand] {
        var commands: [BulletSpawnCommand] = []
        let bulletCount = config.bulletCount
        let speed = config.physics.speed
        
        for i in 0..<bulletCount {
            let angle = (CGFloat.pi * 2 * CGFloat(i)) / CGFloat(bulletCount)
            let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
            commands.append(makeBulletCommand(position: position, velocity: velocity, config: config))
        }
        return commands
    }
    
    private func makeAimedShot(position: CGPoint, targetPosition: CGPoint?, config: PatternConfig) -> [BulletSpawnCommand] {
        guard let target = targetPosition else {
            return EnemyPattern.singleShot.getBulletCommands(from: position, config: config)
        }
        
        let velocity = MathUtility.velocity(from: position, to: target, speed: config.physics.speed)
        return [makeBulletCommand(position: position, velocity: velocity, config: config)]
    }
    
    private func makeSpiralShot(position: CGPoint, config: PatternConfig) -> [BulletSpawnCommand] {
        var commands: [BulletSpawnCommand] = []
        let bulletCount = config.bulletCount
        let baseSpeed = config.physics.speed
        
        for i in 0..<bulletCount {
            let angle = (CGFloat.pi * 2 * CGFloat(i)) / CGFloat(bulletCount) + CGFloat.pi * 0.5
            let speed = baseSpeed + CGFloat(i) * config.spiralSpeed
            let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
            commands.append(makeBulletCommand(position: position, velocity: velocity, config: config))
        }
        return commands
    }
    
    private func makeBulletCommand(position: CGPoint, velocity: CGVector, config: PatternConfig) -> BulletSpawnCommand {
        return BulletSpawnCommand(
            position: position,
            velocity: velocity,
            bulletType: .enemyBullet,
            physics: config.physics,
            visual: config.visual,
            behavior: config.behavior
        )
    }
}
