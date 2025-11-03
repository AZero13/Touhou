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
            
        case .tripleShot:
            let spread = config.spread
            return [
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: 0, dy: -config.physics.speed),
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: config.visual,
                    behavior: config.behavior
                ),
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: -spread, dy: -config.physics.speed * 0.8),
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: config.visual,
                    behavior: config.behavior
                ),
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: spread, dy: -config.physics.speed * 0.8),
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: config.visual,
                    behavior: config.behavior
                )
            ]
            
        case .circleShot:
            var commands: [BulletSpawnCommand] = []
            let bulletCount = config.bulletCount
            let speed = config.physics.speed
            
            for i in 0..<bulletCount {
                let angle = (CGFloat.pi * 2 * CGFloat(i)) / CGFloat(bulletCount)
                let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                
                commands.append(BulletSpawnCommand(
                    position: position,
                    velocity: velocity,
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: config.visual,
                    behavior: config.behavior
                ))
            }
            return commands
            
        case .aimedShot:
            guard let target = targetPosition else {
                // Fallback to single shot if no target
                return EnemyPattern.singleShot.getBulletCommands(from: position, config: config)
            }
            
            let speed = config.physics.speed
            let velocity = MathUtility.velocity(from: position, to: target, speed: speed)
            
            return [
                BulletSpawnCommand(
                    position: position,
                    velocity: velocity,
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: config.visual,
                    behavior: config.behavior
                )
            ]
            
        case .spiralShot:
            var commands: [BulletSpawnCommand] = []
            let bulletCount = config.bulletCount
            let baseSpeed = config.physics.speed
            
            for i in 0..<bulletCount {
                let angle = (CGFloat.pi * 2 * CGFloat(i)) / CGFloat(bulletCount) + CGFloat.pi * 0.5 // Start pointing down
                let speed = baseSpeed + CGFloat(i) * config.spiralSpeed
                let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                
                commands.append(BulletSpawnCommand(
                    position: position,
                    velocity: velocity,
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: config.visual,
                    behavior: config.behavior
                ))
            }
            return commands
        }
    }
}
