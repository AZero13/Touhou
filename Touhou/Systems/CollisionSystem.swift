//
//  CollisionSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// CollisionSystem - handles collision detection between entities
final class CollisionSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Skip all collision/graze checks when time is frozen
        if GameFacade.shared.isFrozen() {
            return
        }
        
        // Get all bullets and all enemies separately
        let bullets = entityManager.getEntities(with: BulletComponent.self)
        let enemies = entityManager.getEntities(with: EnemyComponent.self)
        let players = entityManager.getEntities(with: PlayerComponent.self)
        
        // Check player bullets vs enemies
        for bullet in bullets {
            guard let bulletComp = bullet.component(ofType: BulletComponent.self),
                  bulletComp.ownedByPlayer else { continue }
            
            for enemy in enemies {
                if checkCollision(entityA: bullet, entityB: enemy) {
                    handleCollision(entityA: bullet, entityB: enemy)
                }
            }
        }
        
        // Check enemy bullets vs player
        for bullet in bullets {
            guard let bulletComp = bullet.component(ofType: BulletComponent.self),
                  !bulletComp.ownedByPlayer else { continue }
            
            for player in players {
                    if checkCollision(entityA: bullet, entityB: player) {
                    handleCollision(entityA: bullet, entityB: player)
                    } else if checkGraze(bullet: bullet, player: player) {
                        // Graze detected (no collision). Award graze via event
                        eventBus.fire(GrazeEvent(bulletEntity: bullet, grazeValue: 1))
                }
            }
        }
        
        // Check enemies touching player directly
        for enemy in enemies {
            for player in players {
                if checkCollision(entityA: enemy, entityB: player) {
                    handleEnemyTouchPlayer(enemy: enemy, player: player)
                }
            }
        }

        
    }
    
    func handleEvent(_ event: GameEvent) {
        // Handle events as needed
    }
    
    // MARK: - Private Methods
    
    private func checkCollision(entityA: GKEntity, entityB: GKEntity) -> Bool {
        guard let transformA = entityA.component(ofType: TransformComponent.self),
              let transformB = entityB.component(ofType: TransformComponent.self) else {
            return false
        }
        
        // Calculate distance between entities
        let dx = transformA.position.x - transformB.position.x
        let dy = transformA.position.y - transformB.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Determine collision radii based on entity types
        let radiusA = getCollisionRadius(for: entityA)
        let radiusB = getCollisionRadius(for: entityB)
        
        return distance < (radiusA + radiusB)
    }
    
    private func getCollisionRadius(for entity: GKEntity) -> CGFloat {
        // Prefer HitboxComponent if present for accurate collision detection
        if let hitbox = entity.component(ofType: HitboxComponent.self) {
            if entity.component(ofType: PlayerComponent.self) != nil {
                return hitbox.playerHitbox ?? 8.0  // Use playerHitbox if specified
            } else if entity.component(ofType: BulletComponent.self) != nil {
                return hitbox.bulletHitbox ?? 3.0  // Use bulletHitbox if specified
            } else if entity.component(ofType: EnemyComponent.self) != nil {
                return hitbox.enemyHitbox ?? 12.0  // Use enemyHitbox if specified
            } else if entity.component(ofType: ItemComponent.self) != nil {
                return hitbox.itemCollectionZone ?? 6.0  // Use itemCollectionZone if specified
            }
        }
        
        // Fallback to defaults based on entity type
        if entity.component(ofType: PlayerComponent.self) != nil {
            return 8.0  // Player radius default
        } else if entity.component(ofType: BulletComponent.self) != nil {
            return 3.0  // Bullet radius default
        } else if entity.component(ofType: EnemyComponent.self) != nil {
            return 12.0  // Enemy radius default
        } else if entity.component(ofType: ItemComponent.self) != nil {
            return 6.0  // Item radius default
        }
        
        return 5.0  // Generic default radius
    }
    
    private func handleCollision(entityA: GKEntity, entityB: GKEntity) {
        // Find the damaging entity (bullet) and target using protocol
        let damagingEntity: GKEntity?
        let targetEntity: GKEntity?
        
        if entityA.component(ofType: BulletComponent.self) != nil {
            damagingEntity = entityA
            targetEntity = entityB
        } else if entityB.component(ofType: BulletComponent.self) != nil {
            damagingEntity = entityB
            targetEntity = entityA
        } else {
            return // No damaging entity involved
        }
        
        guard let bullet = damagingEntity?.component(ofType: BulletComponent.self),
              let target = targetEntity else { return }
        
        // Player bullet hits enemy
        if bullet.ownedByPlayer && target.component(ofType: EnemyComponent.self) != nil {
            // Immediately mark bullet for destruction (before processing damage)
            entityManager.markForDestruction(damagingEntity!)
            
            // Fire collision event (damage will be processed by HealthSystem)
            eventBus.fire(CollisionOccurredEvent(
                entityA: damagingEntity!,
                entityB: targetEntity!,
                collisionType: .playerBulletHitEnemy
            ))
        }
        
        // Enemy bullet hits player
        if !bullet.ownedByPlayer && target.component(ofType: PlayerComponent.self) != nil {
            // Mark bullet for destruction
            entityManager.markForDestruction(damagingEntity!)
            
            // Fire collision event
            eventBus.fire(CollisionOccurredEvent(
                entityA: damagingEntity!,
                entityB: targetEntity!,
                collisionType: .enemyBulletHitPlayer
            ))
        }
    }
    
    private func handleEnemyTouchPlayer(enemy: GKEntity, player: GKEntity) {
        // Fire collision event for enemy touching player
        eventBus.fire(CollisionOccurredEvent(
            entityA: enemy,
            entityB: player,
            collisionType: .enemyTouchPlayer
        ))
    }

    private func checkGraze(bullet: GKEntity, player: GKEntity) -> Bool {
        guard let bulletTransform = bullet.component(ofType: TransformComponent.self),
              let playerTransform = player.component(ofType: TransformComponent.self) else {
            return false
        }
        
        // Player graze radius: prefer HitboxComponent.grazeZone, fallback to default
        let defaultGraze: CGFloat = 30.0
        let playerGraze = player.component(ofType: HitboxComponent.self)?.grazeZone ?? defaultGraze
        let bulletRadius: CGFloat = getCollisionRadius(for: bullet)
        let playerRadius: CGFloat = getCollisionRadius(for: player)
        
        let dx = bulletTransform.position.x - playerTransform.position.x
        let dy = bulletTransform.position.y - playerTransform.position.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Consider graze when within graze ring but outside collision
        return distance < (playerGraze + bulletRadius) && distance >= (playerRadius + bulletRadius)
    }
}
