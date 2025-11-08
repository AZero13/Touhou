//
//  HealthSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// HealthSystem - handles health and death logic
final class HealthSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Update invulnerability timers for all damageable entities
        // Use getAllComponents to directly get health components without entity iteration
        for healthComponent in entityManager.getAllComponents(HealthComponent.self) {
            // Decrease invulnerability timer
            if healthComponent.invulnerabilityTimer > 0 {
                healthComponent.invulnerabilityTimer -= deltaTime
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        switch event {
        case let collisionEvent as CollisionOccurredEvent:
            handleCollisionEvent(collisionEvent)
            
        case let died as EnemyDiedEvent:
            // Handle item drops when enemy dies
            handleEnemyDeath(died)
            
        default:
            // Ignore other events
            break
        }
    }
    
    
    private func handleCollisionEvent(_ event: CollisionOccurredEvent) {
        switch event.collisionType {
        case .playerBulletHitEnemy:
            // entityA is the bullet, entityB is the enemy - use captured position from event
            handleEnemyHit(event.entityB, hitPosition: event.hitPosition)
        case .enemyBulletHitPlayer, .enemyTouchPlayer:
            handlePlayerHit(event.entityB) // entityB is the player
        }
    }
    
    private func handleEnemyHit(_ enemyEntity: GKEntity, hitPosition: CGPoint) {
        // Fire hit effect event for visuals with the actual collision point
        eventBus.fire(EnemyHitEvent(enemyEntity: enemyEntity, hitPosition: hitPosition))
        
        // Use combat facade to apply damage
        GameFacade.shared.combat.damage(enemyEntity, amount: 1)
    }
    
    private func handlePlayerHit(_ playerEntity: GKEntity) {
        // Use combat facade to adjust lives
        GameFacade.shared.combat.adjustLives(delta: -1)
    }
    
    private func handleEnemyDeath(_ event: EnemyDiedEvent) {
        let isBoss = event.entity.component(ofType: BossComponent.self) != nil
        
        // Boss death: convert all bullets to points (TH06 behavior)
        if isBoss {
            BulletUtility.convertBulletsToPoints(entityManager: entityManager)
            // Fire event for attraction, handled by ItemAttractionSystem
            eventBus.fire(AttractItemsEvent(itemTypes: [.point, .pointBullet]))
        } else {
            // Regular enemy death: spawn item drop
            if let itemType = event.dropItem,
               let transform = event.entity.component(ofType: TransformComponent.self) {
                // Initial upward velocity - brief pop then fall
                GameFacade.shared.entities.spawnItem(type: itemType, at: transform.position, velocity: CGVector(dx: 0, dy: 40))
            }
        }
    }
    
}
