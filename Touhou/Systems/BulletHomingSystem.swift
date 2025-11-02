//
//  BulletHomingSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// BulletHomingSystem - handles homing bullet behavior
final class BulletHomingSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Get all homing bullets
        let bulletEntities = entityManager.getEntities(with: BulletComponent.self)
        
        for entity in bulletEntities {
            guard let bullet = entity.component(ofType: BulletComponent.self),
                  let transform = entity.component(ofType: TransformComponent.self) else { continue }
            
            // Respect freeze/time scaling: skip steering if frozen
            if let mods = entity.component(ofType: BulletMotionModifiersComponent.self), mods.timeScale <= 0 {
                continue
            }
            
            // Find nearest target
            let target = findNearestTarget(for: bullet, from: transform.position)
            guard let targetPosition = target else { continue }
            
            // If TH06-style retargeting is configured, do discrete snaps and skip continuous steering
            if let interval = bullet.retargetInterval {
                bullet.retargetTimer -= deltaTime
                if bullet.retargetTimer <= 0 {
                    if let maxTimes = bullet.maxRetargets {
                        if bullet.retargetedCount >= maxTimes {
                            continue
                        }
                    }
                    let angle = MathUtility.angle(from: transform.position, to: targetPosition) + bullet.rotationOffset
                    let speed = MathUtility.magnitude(transform.velocity)
                    transform.velocity = MathUtility.velocity(angle: angle, speed: speed)
                    bullet.retargetedCount += 1
                    bullet.retargetTimer += max(0, interval)
                }
                continue
            }
            
            // Continuous steering fallback (uses homingStrength and maxTurnRate)
            guard let homingStrength = bullet.homingStrength,
                  let maxTurnRate = bullet.maxTurnRate else { continue }

            // Calculate desired velocity towards target
            let speed = MathUtility.magnitude(transform.velocity)
            let desiredVelocity = MathUtility.velocity(from: transform.position, to: targetPosition, speed: speed)
            
            // Calculate angle difference
            let currentAngle = MathUtility.angle(of: transform.velocity)
            let targetAngle = MathUtility.angle(of: desiredVelocity)
            let angleDiff = MathUtility.angleDifference(from: currentAngle, to: targetAngle)
            
            // Limit turn rate
            let maxTurnThisFrame = maxTurnRate * deltaTime
            let actualTurn = min(maxTurnThisFrame, abs(angleDiff)) * (angleDiff >= 0 ? 1 : -1)
            
            // Apply homing strength
            let turnAmount = actualTurn * homingStrength
            
            // Rotate velocity vector
            let newAngle = currentAngle + turnAmount
            transform.velocity = MathUtility.velocity(angle: newAngle, speed: speed)
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        // No events to handle
    }
    
    // MARK: - Private Methods
    
    private func findNearestTarget(for bullet: BulletComponent, from position: CGPoint) -> CGPoint? {
        if bullet.ownedByPlayer {
            // Player bullets home towards enemies
            let enemies = entityManager.getEntities(with: EnemyComponent.self)
            var nearestEnemy: GKEntity?
            var nearestDistance: CGFloat = CGFloat.greatestFiniteMagnitude
            
            for enemy in enemies {
                guard let enemyTransform = enemy.component(ofType: TransformComponent.self) else { continue }
                
                let distance = MathUtility.distance(from: position, to: enemyTransform.position)
                
                if distance < nearestDistance {
                    nearestDistance = distance
                    nearestEnemy = enemy
                }
            }
            
            return nearestEnemy?.component(ofType: TransformComponent.self)?.position
        } else {
            // Enemy bullets home towards player
            return PlayerUtility.getPosition(entityManager: entityManager)
        }
    }
}
