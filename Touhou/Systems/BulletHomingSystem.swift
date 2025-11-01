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
                    let toTarget = CGVector(dx: targetPosition.x - transform.position.x,
                                             dy: targetPosition.y - transform.position.y)
                    let angle = atan2(toTarget.dy, toTarget.dx) + bullet.rotationOffset
                    let speed = sqrt(transform.velocity.dx * transform.velocity.dx + transform.velocity.dy * transform.velocity.dy)
                    transform.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                    bullet.retargetedCount += 1
                    bullet.retargetTimer += max(0, interval)
                }
                continue
            }
            
            // Continuous steering fallback (uses homingStrength and maxTurnRate)
            guard let homingStrength = bullet.homingStrength,
                  let maxTurnRate = bullet.maxTurnRate else { continue }

            // Calculate direction to target
            let directionToTarget = CGVector(
                dx: targetPosition.x - transform.position.x,
                dy: targetPosition.y - transform.position.y
            )
            
            // Normalize direction
            let distance = sqrt(directionToTarget.dx * directionToTarget.dx + directionToTarget.dy * directionToTarget.dy)
            guard distance > 0 else { continue }
            
            let normalizedDirection = CGVector(
                dx: directionToTarget.dx / distance,
                dy: directionToTarget.dy / distance
            )
            
            // Calculate desired velocity
            let speed = sqrt(transform.velocity.dx * transform.velocity.dx + transform.velocity.dy * transform.velocity.dy)
            let desiredVelocity = CGVector(
                dx: normalizedDirection.dx * speed,
                dy: normalizedDirection.dy * speed
            )
            
            // Gradually turn towards target (limited by maxTurnRate)
            let currentDirection = CGVector(
                dx: transform.velocity.dx / speed,
                dy: transform.velocity.dy / speed
            )
            
            // Calculate angle difference
            let currentAngle = atan2(currentDirection.dy, currentDirection.dx)
            let targetAngle = atan2(desiredVelocity.dy, desiredVelocity.dx)
            var angleDiff = targetAngle - currentAngle
            
            // Normalize angle difference to [-π, π]
            while angleDiff > .pi { angleDiff -= 2 * .pi }
            while angleDiff < -.pi { angleDiff += 2 * .pi }
            
            // Limit turn rate
            let maxTurnThisFrame = maxTurnRate * deltaTime
            let actualTurn = min(maxTurnThisFrame, abs(angleDiff)) * (angleDiff >= 0 ? 1 : -1)
            
            // Apply homing strength
            let turnAmount = actualTurn * homingStrength
            
            // Rotate velocity vector
            let newAngle = currentAngle + turnAmount
            transform.velocity = CGVector(
                dx: cos(newAngle) * speed,
                dy: sin(newAngle) * speed
            )
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
                
                let distance = sqrt(
                    pow(enemyTransform.position.x - position.x, 2) +
                    pow(enemyTransform.position.y - position.y, 2)
                )
                
                if distance < nearestDistance {
                    nearestDistance = distance
                    nearestEnemy = enemy
                }
            }
            
            return nearestEnemy?.component(ofType: TransformComponent.self)?.position
        } else {
            // Enemy bullets home towards player
            let players = entityManager.getEntities(with: PlayerComponent.self)
            return players.first?.component(ofType: TransformComponent.self)?.position
        }
    }
}
