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
    case rumiaShot
    case rumiaShot2  // Second spell (Sub5)
    
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
        case .rumiaShot:
            return makeRumiaShot(position: position, config: config)
        case .rumiaShot2:
            return makeRumiaShot2(position: position, config: config)
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
    
    private func makeRumiaShot(position: CGPoint, config: PatternConfig) -> [BulletSpawnCommand] {
        var commands: [BulletSpawnCommand] = []
        let speed = config.physics.speed
        
        // Multiple downward streams of red circular bullets (like Sub4 called multiple times with angle offsets)
        // Sub8 calls Sub4 with angles: 0.0, 0.06544985, 0.1308997, 0.19634955, 0.2617994 (radians)
        // These are approximately: 0°, 3.75°, 7.5°, 11.25°, 15°
        let streamAngles: [CGFloat] = [0.0, 0.06544985, 0.1308997, 0.19634955, 0.2617994]
        let bulletsPerStream = 8  // Easy difficulty (8 bullets per stream)
        let streamSpacing: CGFloat = 8  // Vertical spacing between bullets in each stream
        
        for (streamIndex, angleOffset) in streamAngles.enumerated() {
            // Each stream is offset horizontally to spread them out
            let horizontalOffset = CGFloat(streamIndex - 2) * 20  // Spread streams horizontally
            
            for i in 0..<bulletsPerStream {
                // Position bullets in a vertical line for each stream
                let bulletPosition = CGPoint(
                    x: position.x + horizontalOffset,
                    y: position.y - CGFloat(i) * streamSpacing
                )
                
                // Velocity: straight down with slight angle offset
                // For downward: dx = sin(angle) * speed, dy = -cos(angle) * speed
                let velocity = CGVector(
                    dx: sin(angleOffset) * speed,
                    dy: -cos(angleOffset) * speed
                )
                
                commands.append(BulletSpawnCommand(
                    position: bulletPosition,
                    velocity: velocity,
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: VisualConfig(size: .small, shape: .circle, color: .red),
                    behavior: config.behavior
                ))
            }
        }
        
        // Scattered yellow square bullets across various angles (all going downward)
        let scatteredBulletCount = 12
        let spreadAngle: CGFloat = .pi * 0.6  // Spread from -30° to +30° from vertical down
        
        for i in 0..<scatteredBulletCount {
            // Angle ranges from -spreadAngle/2 to +spreadAngle/2 (centered on downward)
            let angle = -spreadAngle / 2 + (spreadAngle * CGFloat(i) / CGFloat(scatteredBulletCount - 1))
            // For downward spread: sin(angle) for x, -cos(angle) for y (negative for down)
            let velocity = CGVector(dx: sin(angle) * speed, dy: -cos(angle) * speed)
            
            // Slight random offset for more scatter
            let scatterOffset = CGFloat.random(in: -15...15)
            let bulletPosition = CGPoint(
                x: position.x + scatterOffset,
                y: position.y
            )
            
            commands.append(BulletSpawnCommand(
                position: bulletPosition,
                velocity: velocity,
                bulletType: .enemyBullet,
                physics: config.physics,
                visual: VisualConfig(size: .small, shape: .square, color: .yellow),
                behavior: config.behavior
            ))
        }
        
        return commands
    }
    
    private func makeRumiaShot2(position: CGPoint, config: PatternConfig) -> [BulletSpawnCommand] {
        var commands: [BulletSpawnCommand] = []
        let speed = config.physics.speed
        
        // Sub5 pattern: Rotating waves of bullets
        // First wave: bullets with angle starting at 3.0 radians, rotating
        // Second wave: bullets with angle starting at 2π (6.2831855), rotating to π (3.1415927)
        // The pattern spawns bullets in two waves with different bullet types
        
        // First wave (bullet type 0): 4-8-12-24 bullets depending on difficulty
        let firstWaveCount = 8  // Normal difficulty
        let firstWaveAngle = 3.0  // Starting angle
        let firstWaveAngleStep = 0.5  // Angle increment per bullet
        
        for i in 0..<firstWaveCount {
            let angle = firstWaveAngle + CGFloat(i) * firstWaveAngleStep
            let velocity = CGVector(
                dx: sin(angle) * speed * 0.7,
                dy: -cos(angle) * speed * 0.7
            )
            commands.append(BulletSpawnCommand(
                position: position,
                velocity: velocity,
                bulletType: .enemyBullet,
                physics: config.physics,
                visual: VisualConfig(size: .small, shape: .circle, color: .red),
                behavior: config.behavior
            ))
        }
        
        // Second wave (bullet type 2): Same count, different angle range
        // Angle goes from 2π (6.2831855) to π (3.1415927)
        let secondWaveAngleStart: CGFloat = 6.2831855  // 2π
        let secondWaveAngleEnd: CGFloat = 3.1415927  // π
        let secondWaveAngleRange = secondWaveAngleEnd - secondWaveAngleStart
        
        for i in 0..<firstWaveCount {
            let angle = secondWaveAngleStart + (secondWaveAngleRange * CGFloat(i) / CGFloat(firstWaveCount - 1))
            let velocity = CGVector(
                dx: sin(angle) * speed * 0.7,
                dy: -cos(angle) * speed * 0.7
            )
            commands.append(BulletSpawnCommand(
                position: position,
                velocity: velocity,
                bulletType: .enemyBullet,
                physics: config.physics,
                visual: VisualConfig(size: .small, shape: .square, color: .yellow),
                behavior: config.behavior
            ))
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
