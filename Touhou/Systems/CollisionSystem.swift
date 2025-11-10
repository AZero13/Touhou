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
    
    // MARK: - Cached Entity Queries
    
    /// Cached entity arrays (refreshed each update to avoid stale data)
    private var cachedBullets: [GKEntity] = []
    private var cachedEnemies: [GKEntity] = []
    private var cachedPlayer: GKEntity?
    
    // MARK: - Constants
    
    /// Default collision radii for different entity types
    private enum CollisionRadius {
        static let player: CGFloat = 8.0
        static let bullet: CGFloat = 3.0
        static let enemy: CGFloat = 12.0
        static let item: CGFloat = 6.0
        static let generic: CGFloat = 5.0
    }
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Skip all collision/graze checks when time is frozen
        if GameFacade.shared.isTimeFrozen {
            return
        }
        
        // Cache entity queries once per update (entities may change during frame, but collision checks are atomic)
        // Refresh cache each update to ensure we have current entities
        refreshEntityCache()
        
        guard let player = cachedPlayer else { return }
        let bullets = cachedBullets
        let enemies = cachedEnemies
        
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
            
            if checkCollision(entityA: bullet, entityB: player) {
                handleCollision(entityA: bullet, entityB: player)
            } else if checkGraze(bullet: bullet, player: player) {
                // Graze detected (no collision). Award graze via event
                eventBus.fire(GrazeEvent(bulletEntity: bullet, grazeValue: 1))
            }
        }
        
        // Check enemies touching player directly (TH06: only non-boss enemies can damage on touch)
        for enemy in enemies {
            // Skip bosses - they don't damage player on touch (TH06 behavior)
            if enemy.component(ofType: BossComponent.self) != nil {
                continue
            }
            
            if checkCollision(entityA: enemy, entityB: player) {
                handleEnemyTouchPlayer(enemy: enemy, player: player)
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
                return hitbox.playerHitbox ?? CollisionRadius.player
            } else if entity.component(ofType: BulletComponent.self) != nil {
                return hitbox.bulletHitbox ?? CollisionRadius.bullet
            } else if entity.component(ofType: EnemyComponent.self) != nil {
                return hitbox.enemyHitbox ?? CollisionRadius.enemy
            } else if entity.component(ofType: ItemComponent.self) != nil {
                return hitbox.itemCollectionZone ?? CollisionRadius.item
            }
        }
        
        // Fallback to defaults based on entity type
        if entity.component(ofType: PlayerComponent.self) != nil {
            return CollisionRadius.player
        } else if entity.component(ofType: BulletComponent.self) != nil {
            return CollisionRadius.bullet
        } else if entity.component(ofType: EnemyComponent.self) != nil {
            return CollisionRadius.enemy
        } else if entity.component(ofType: ItemComponent.self) != nil {
            return CollisionRadius.item
        }
        
        return CollisionRadius.generic
    }
    
    private func handleCollision(entityA: GKEntity, entityB: GKEntity) {
        // Find the damaging entity (bullet) and target
        let (bulletEntity, target): (GKEntity, GKEntity)
        
        if entityA.component(ofType: BulletComponent.self) != nil {
            (bulletEntity, target) = (entityA, entityB)
        } else if entityB.component(ofType: BulletComponent.self) != nil {
            (bulletEntity, target) = (entityB, entityA)
        } else {
            return // No bullet involved
        }
        
        // bulletEntity guaranteed to have BulletComponent at this point
        let bullet = bulletEntity.component(ofType: BulletComponent.self)!
        
        // Player bullet hits enemy
        if bullet.ownedByPlayer && target.component(ofType: EnemyComponent.self) != nil {
            // Capture position BEFORE marking for destruction
            let hitPosition = bulletEntity.component(ofType: TransformComponent.self)?.position ?? CGPoint.zero
            
            // Immediately mark bullet for destruction (before processing damage)
            entityManager.markForDestruction(bulletEntity)
            
            // Fire collision event (damage will be processed by HealthSystem)
            eventBus.fire(CollisionOccurredEvent(
                entityA: bulletEntity,
                entityB: target,
                collisionType: .playerBulletHitEnemy,
                hitPosition: hitPosition
            ))
        }
        
        // Enemy bullet hits player
        if !bullet.ownedByPlayer && target.component(ofType: PlayerComponent.self) != nil {
            // TH06: Check if player is invulnerable before taking damage
            if let playerHealth = target.component(ofType: HealthComponent.self),
               playerHealth.isInvulnerable {
                // Player is invulnerable - bullet doesn't damage but still gets destroyed
                entityManager.markForDestruction(bulletEntity)
                return
            }
            
            // Capture position BEFORE marking for destruction
            let hitPosition = bulletEntity.component(ofType: TransformComponent.self)?.position ?? CGPoint.zero
            
            // Mark bullet for destruction
            entityManager.markForDestruction(bulletEntity)
            
            // Fire collision event
            eventBus.fire(CollisionOccurredEvent(
                entityA: bulletEntity,
                entityB: target,
                collisionType: .enemyBulletHitPlayer,
                hitPosition: hitPosition
            ))
        }
    }
    
    private func handleEnemyTouchPlayer(enemy: GKEntity, player: GKEntity) {
        // TH06: Only damage player if they're vulnerable (not invulnerable/dead/spawning)
        if player.component(ofType: HealthComponent.self)?.isInvulnerable == true {
            return
        }
        
        let hitPosition = enemy.component(ofType: TransformComponent.self)?.position ?? CGPoint.zero
        
        eventBus.fire(CollisionOccurredEvent(
            entityA: enemy,
            entityB: player,
            collisionType: .enemyTouchPlayer,
            hitPosition: hitPosition
        ))
    }

    private func checkGraze(bullet: GKEntity, player: GKEntity) -> Bool {
        // TH06: No graze during bomb (when invulnerable)
        if let playerHealth = player.component(ofType: HealthComponent.self),
           playerHealth.isInvulnerable {
            return false
        }
        
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
    
    // MARK: - Cache Management
    
    /// Refresh cached entity queries (called once per update)
    private func refreshEntityCache() {
        cachedBullets = entityManager.getEntities(with: BulletComponent.self)
        cachedEnemies = entityManager.getEntities(with: EnemyComponent.self)
        cachedPlayer = entityManager.getPlayerEntity()
    }
}
