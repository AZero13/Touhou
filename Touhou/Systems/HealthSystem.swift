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
        let damageableEntities = entityManager.getEntities(with: HealthComponent.self)
        
        for entity in damageableEntities {
            guard let healthComponent = entity.component(ofType: HealthComponent.self) else { continue }
            
            // Decrease invulnerability timer
            if healthComponent.invulnerabilityTimer > 0 {
                healthComponent.invulnerabilityTimer -= deltaTime
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        if let collisionEvent = event as? CollisionOccurredEvent {
            print("📨 HealthSystem received collision event: \(collisionEvent.collisionType)")
            handleCollisionEvent(collisionEvent)
        }
    }
    
    
    private func handleCollisionEvent(_ event: CollisionOccurredEvent) {
        switch event.collisionType {
        case .playerBulletHitEnemy:
            handleEnemyHit(event.entityB) // entityB is the enemy
        case .enemyBulletHitPlayer, .enemyTouchPlayer:
            handlePlayerHit(event.entityB) // entityB is the player
        }
    }
    
    private func handleEnemyHit(_ enemyEntity: GKEntity) {
        // Use command queue to apply damage deterministically
        GameFacade.shared.getCommandQueue().enqueue(.applyDamage(entity: enemyEntity, amount: 1))
    }
    
    private func handlePlayerHit(_ playerEntity: GKEntity) {
        // Enqueue life decrement; queue will handle events and respawn
        GameFacade.shared.getCommandQueue().enqueue(.adjustLives(delta: -1))
    }
    
}
