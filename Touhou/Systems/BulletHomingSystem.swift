//
//  BulletHomingSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

final class BulletHomingSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(context: GameRuntimeContext) {
        self.entityManager = context.entityManager
        self.eventBus = context.eventBus
    }
    
    func update(deltaTime: TimeInterval, context: GameRuntimeContext) {
        let bulletEntities = entityManager.getEntities(with: BulletComponent.self)
        
        for entity in bulletEntities {
            guard let bullet = entity.component(ofType: BulletComponent.self),
                  let transform = entity.component(ofType: TransformComponent.self) else { continue }
            
            if let mods = entity.component(ofType: BulletMotionModifiersComponent.self), mods.timeScale <= 0 {
                continue
            }
            
            let target = findNearestTarget(for: bullet, from: transform.position)
            guard let targetPosition = target else { continue }
            
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
            
            guard let homingStrength = bullet.homingStrength,
                  let maxTurnRate = bullet.maxTurnRate else { continue }

            let speed = MathUtility.magnitude(transform.velocity)
            let desiredVelocity = MathUtility.velocity(from: transform.position, to: targetPosition, speed: speed)
            
            let currentAngle = MathUtility.angle(of: transform.velocity)
            let targetAngle = MathUtility.angle(of: desiredVelocity)
            let angleDiff = MathUtility.angleDifference(from: currentAngle, to: targetAngle)
            
            let maxTurnThisFrame = maxTurnRate * deltaTime
            let actualTurn = min(maxTurnThisFrame, abs(angleDiff)) * (angleDiff >= 0 ? 1 : -1)
            
            let turnAmount = actualTurn * homingStrength
            
            let newAngle = currentAngle + turnAmount
            transform.velocity = MathUtility.velocity(angle: newAngle, speed: speed)
        }
    }
    
    func handleEvent(_ event: GameEvent, context: GameRuntimeContext) {
        // No events to handle
    }
    
    func handleEvent(_ event: GameEvent) {
        // Fallback for non-GameSystem listeners (shouldn't be called)
        fatalError("BulletHomingSystem.handleEvent without context should not be called")
    }
    
    private func findNearestTarget(for bullet: BulletComponent, from position: CGPoint) -> CGPoint? {
        if bullet.ownedByPlayer {
            let enemies = entityManager.getEntities(with: EnemyComponent.self)
            var nearestEnemy: GKEntity?
            var nearestDistanceSq: CGFloat = CGFloat.greatestFiniteMagnitude
            
            for enemy in enemies {
                guard let enemyTransform = enemy.component(ofType: TransformComponent.self) else { continue }
                let distanceSq = MathUtility.distanceSquared(from: position, to: enemyTransform.position)
                if distanceSq < nearestDistanceSq {
                    nearestDistanceSq = distanceSq
                    nearestEnemy = enemy
                }
            }
            
            return nearestEnemy?.component(ofType: TransformComponent.self)?.position
        } else {
            return PlayerUtility.getPosition(entityManager: entityManager)
        }
    }
}
