//
//  EnemyPattern.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// Enemy attack patterns (like th06)
enum EnemyPattern: String, CaseIterable {
    case singleShot = "single_shot"
    case tripleShot = "triple_shot"
    case circleShot = "circle_shot"
    case aimedShot = "aimed_shot"
    case spiralShot = "spiral_shot"
    
    /// Get the pattern's bullet spawn commands
    func getBulletCommands(from position: CGPoint, targetPosition: CGPoint? = nil) -> [BulletSpawnCommand] {
        switch self {
        case .singleShot:
            return [
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: 0, dy: -150),
                    bulletType: "enemy_bullet",
                    damage: 1
                )
            ]
            
        case .tripleShot:
            return [
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: 0, dy: -150),
                    bulletType: "enemy_bullet",
                    damage: 1
                ),
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: -50, dy: -120),
                    bulletType: "enemy_bullet",
                    damage: 1
                ),
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: 50, dy: -120),
                    bulletType: "enemy_bullet",
                    damage: 1
                )
            ]
            
        case .circleShot:
            var commands: [BulletSpawnCommand] = []
            let bulletCount = 8
            let speed: CGFloat = 100
            
            for i in 0..<bulletCount {
                let angle = (CGFloat.pi * 2 * CGFloat(i)) / CGFloat(bulletCount)
                let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                
                commands.append(BulletSpawnCommand(
                    position: position,
                    velocity: velocity,
                    bulletType: "enemy_bullet",
                    damage: 1
                ))
            }
            return commands
            
        case .aimedShot:
            guard let target = targetPosition else {
                // Fallback to single shot if no target
                return EnemyPattern.singleShot.getBulletCommands(from: position)
            }
            
            let dx = target.x - position.x
            let dy = target.y - position.y
            let distance = sqrt(dx * dx + dy * dy)
            let speed: CGFloat = 120
            
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
                        damage: 1
                    )
                ]
            }
            return []
            
        case .spiralShot:
            var commands: [BulletSpawnCommand] = []
            let bulletCount = 6
            let baseSpeed: CGFloat = 80
            
            for i in 0..<bulletCount {
                let angle = (CGFloat.pi * 2 * CGFloat(i)) / CGFloat(bulletCount) + CGFloat.pi * 0.5 // Start pointing down
                let speed = baseSpeed + CGFloat(i) * 10 // Slightly increasing speed
                let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                
                commands.append(BulletSpawnCommand(
                    position: position,
                    velocity: velocity,
                    bulletType: "enemy_bullet",
                    damage: 1
                ))
            }
            return commands
        }
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
