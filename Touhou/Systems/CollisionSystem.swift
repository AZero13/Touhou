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
    private weak var engine: GameEngine!
    
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
        static let enemy: CGFloat = 9.0
        static let item: CGFloat = 6.0
        static let generic: CGFloat = 5.0
    }
    
    func initialize(engine: GameEngine) {
        self.engine = engine
    }
    
    func update(deltaTime: TimeInterval) {
        // Skip all collision/graze checks when time is frozen
        if engine.isTimeFrozen {
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
            
            if bulletComp.bulletType == .laser,
               let laser = bullet.component(ofType: LaserComponent.self),
               let laserTransform = bullet.component(ofType: TransformComponent.self) {
                handlePlayerLaser(laserEntity: bullet, laser: laser, laserTransform: laserTransform, enemies: enemies)
                continue
            }
            
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
            
            if bulletComp.bulletType == .laser,
               let laser = bullet.component(ofType: LaserComponent.self),
               let laserTransform = bullet.component(ofType: TransformComponent.self),
               let playerTransform = player.component(ofType: TransformComponent.self) {
                handleEnemyLaser(laserEntity: bullet, laser: laser, laserTransform: laserTransform, player: player, playerTransform: playerTransform)
                continue
            }
            
            if checkCollision(entityA: bullet, entityB: player) {
                handleCollision(entityA: bullet, entityB: player)
            } else if checkGraze(bullet: bullet, player: player) {
                // Graze detected (no collision). Award graze via event
                engine.fireEvent(GrazeEvent(bulletEntity: bullet, grazeValue: 1))
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
        
        // Check player collecting items
        let items = engine.entityManager.getEntities(with: ItemComponent.self)
        for item in items {
            if checkCollision(entityA: item, entityB: player) {
                handleItemCollection(item: item, player: player)
            }
        }

        
    }
    
    func handleEvent(_ event: GameEvent) {
        // No events to handle
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
            
            // Immediately mark bullet for destruction (before processing damage), except lasers
            if bullet.bulletType != .laser {
                engine.entityManager.markForDestruction(bulletEntity)
            }
            
            // Fire collision event (damage will be processed by HealthSystem)
            engine.fireEvent(CollisionOccurredEvent(
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
                engine.entityManager.markForDestruction(bulletEntity)
                return
            }
            
            // Capture position BEFORE marking for destruction
            let hitPosition = bulletEntity.component(ofType: TransformComponent.self)?.position ?? CGPoint.zero
            
            // Mark bullet for destruction unless it's a laser (lasers persist)
            if bullet.bulletType != .laser {
                engine.entityManager.markForDestruction(bulletEntity)
            }
            
            // Fire collision event
            engine.fireEvent(CollisionOccurredEvent(
                entityA: bulletEntity,
                entityB: target,
                collisionType: .enemyBulletHitPlayer,
                hitPosition: hitPosition
            ))
        }
    }
    
    private func handlePlayerLaser(laserEntity: GKEntity, laser: LaserComponent, laserTransform: TransformComponent, enemies: [GKEntity]) {
        for enemy in enemies {
            guard let enemyTransform = enemy.component(ofType: TransformComponent.self) else { continue }
            let radius = getCollisionRadius(for: enemy)
            if checkLaserHit(laser: laser, laserTransform: laserTransform, targetPosition: enemyTransform.position, targetRadius: radius) {
                if laser.canDamage(enemy) {
                    engine.fireEvent(CollisionOccurredEvent(
                        entityA: laserEntity,
                        entityB: enemy,
                        collisionType: .playerBulletHitEnemy,
                        hitPosition: enemyTransform.position
                    ))
                }
            }
        }
    }
    
    private func handleEnemyLaser(laserEntity: GKEntity, laser: LaserComponent, laserTransform: TransformComponent, player: GKEntity, playerTransform: TransformComponent) {
        let playerRadius = getCollisionRadius(for: player)
        let grazePadding: CGFloat = 12.0
        
        if checkLaserHit(laser: laser, laserTransform: laserTransform, targetPosition: playerTransform.position, targetRadius: playerRadius) {
            if laser.canDamage(player) {
                engine.fireEvent(CollisionOccurredEvent(
                    entityA: laserEntity,
                    entityB: player,
                    collisionType: .enemyBulletHitPlayer,
                    hitPosition: playerTransform.position
                ))
            }
        } else if checkLaserHit(laser: laser, laserTransform: laserTransform, targetPosition: playerTransform.position, targetRadius: playerRadius + grazePadding) {
            engine.fireEvent(GrazeEvent(bulletEntity: laserEntity, grazeValue: 1))
        }
    }
    
    private func checkLaserHit(laser: LaserComponent, laserTransform: TransformComponent, targetPosition: CGPoint, targetRadius: CGFloat) -> Bool {
        let origin = laserTransform.position
        let dir = CGVector(dx: cos(laser.angle), dy: sin(laser.angle))
        let toTarget = CGVector(dx: targetPosition.x - origin.x, dy: targetPosition.y - origin.y)
        
        let proj = toTarget.dx * dir.dx + toTarget.dy * dir.dy
        if proj < -targetRadius || proj > laser.length + targetRadius {
            return false
        }
        
        let perp = abs(toTarget.dx * dir.dy - toTarget.dy * dir.dx)
        let halfWidth = laser.width * 0.5
        return perp <= (halfWidth + targetRadius)
    }
    
    private func handleEnemyTouchPlayer(enemy: GKEntity, player: GKEntity) {
        // TH06: Only damage player if they're vulnerable (not invulnerable/dead/spawning)
        if player.component(ofType: HealthComponent.self)?.isInvulnerable == true {
            return
        }
        
        let hitPosition = enemy.component(ofType: TransformComponent.self)?.position ?? CGPoint.zero
        
        engine.fireEvent(CollisionOccurredEvent(
            entityA: enemy,
            entityB: player,
            collisionType: .enemyTouchPlayer,
            hitPosition: hitPosition
        ))
    }
    
    private func handleItemCollection(item: GKEntity, player: GKEntity) {
        guard let itemComp = item.component(ofType: ItemComponent.self),
              let transform = item.component(ofType: TransformComponent.self) else {
            return
        }
        
        // Fire item collected event (for sound effect)
        engine.fireEvent(ItemCollectedEvent(itemType: itemComp.itemType, position: transform.position))
        
        // Fire power-up collected event (for scoring and power increase)
        // This event is already handled by ScoreSystem and PowerSystem
        engine.fireEvent(PowerUpCollectedEvent(itemType: itemComp.itemType, value: itemComp.value, position: transform.position))
        
        // Mark item for destruction
        engine.entityManager.markForDestruction(item)
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
        cachedBullets = engine.entityManager.getEntities(with: BulletComponent.self)
        cachedEnemies = engine.entityManager.getEntities(with: EnemyComponent.self)
        cachedPlayer = engine.entityManager.getPlayerEntity()
    }
}
