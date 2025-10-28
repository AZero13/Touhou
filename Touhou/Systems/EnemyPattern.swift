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
enum EnemyPattern: String, CaseIterable {
    case singleShot = "single_shot"
    case tripleShot = "triple_shot"
    case circleShot = "circle_shot"
    case aimedShot = "aimed_shot"
    case spiralShot = "spiral_shot"
    
    /// Get the pattern's bullet spawn commands with config
    func getBulletCommands(from position: CGPoint, targetPosition: CGPoint? = nil, config: BulletConfig = BulletConfig()) -> [BulletSpawnCommand] {
        switch self {
        case .singleShot:
            return [
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: 0, dy: -config.speed),
                    bulletType: "enemy_bullet",
                    damage: config.damage
                )
            ]
            
        case .tripleShot:
            let spread = config.spread
            return [
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: 0, dy: -config.speed),
                    bulletType: "enemy_bullet",
                    damage: config.damage
                ),
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: -spread, dy: -config.speed * 0.8),
                    bulletType: "enemy_bullet",
                    damage: config.damage
                ),
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: spread, dy: -config.speed * 0.8),
                    bulletType: "enemy_bullet",
                    damage: config.damage
                )
            ]
            
        case .circleShot:
            var commands: [BulletSpawnCommand] = []
            let bulletCount = config.bulletCount
            let speed = config.speed
            
            for i in 0..<bulletCount {
                let angle = (CGFloat.pi * 2 * CGFloat(i)) / CGFloat(bulletCount)
                let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                
                commands.append(BulletSpawnCommand(
                    position: position,
                    velocity: velocity,
                    bulletType: "enemy_bullet",
                    damage: config.damage
                ))
            }
            return commands
            
        case .aimedShot:
            guard let target = targetPosition else {
                // Fallback to single shot if no target
                return EnemyPattern.singleShot.getBulletCommands(from: position, config: config)
            }
            
            let dx = target.x - position.x
            let dy = target.y - position.y
            let distance = sqrt(dx * dx + dy * dy)
            let speed = config.speed
            
            if distance > 0 {
                let velocity = CGVector(
                    dx: (dx / distance) * speed,
                    dy: (dy / distance) * speed
                )
                
                return [
                    BulletSpawnCommand(
                        position: position,
                        velocity: velocity,
                        bulletType: "enemy_bullet",
                        damage: config.damage
                    )
                ]
            }
            return []
            
        case .spiralShot:
            var commands: [BulletSpawnCommand] = []
            let bulletCount = config.bulletCount
            let baseSpeed = config.speed
            
            for i in 0..<bulletCount {
                let angle = (CGFloat.pi * 2 * CGFloat(i)) / CGFloat(bulletCount) + CGFloat.pi * 0.5 // Start pointing down
                let speed = baseSpeed + CGFloat(i) * config.spiralSpeed
                let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                
                commands.append(BulletSpawnCommand(
                    position: position,
                    velocity: velocity,
                    bulletType: "enemy_bullet",
                    damage: config.damage
                ))
            }
            return commands
        }
    }
}

/// Bullet configuration for enemy attacks
struct BulletConfig {
    let speed: CGFloat
    let damage: Int
    let bulletCount: Int
    let spread: CGFloat
    let spiralSpeed: CGFloat
    
    init(speed: CGFloat = 150, damage: Int = 1, bulletCount: Int = 8, spread: CGFloat = 50, spiralSpeed: CGFloat = 10) {
        self.speed = speed
        self.damage = damage
        self.bulletCount = bulletCount
        self.spread = spread
        self.spiralSpeed = spiralSpeed
    }
}

/// Bullet spawn command for enemy patterns
struct BulletSpawnCommand {
    let position: CGPoint
    let velocity: CGVector
    let bulletType: String
    let damage: Int
    let delay: TimeInterval
    
    init(position: CGPoint, velocity: CGVector, bulletType: String, damage: Int, delay: TimeInterval = 0) {
        self.position = position
        self.velocity = velocity
        self.bulletType = bulletType
        self.damage = damage
        self.delay = delay
    }
}
