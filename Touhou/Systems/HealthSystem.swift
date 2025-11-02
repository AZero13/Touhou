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
        } else if let died = event as? EnemyDiedEvent {
            // Handle item drops when enemy dies
            handleEnemyDeath(died)
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
        // Use combat facade to apply damage
        GameFacade.shared.combat.damage(enemyEntity, amount: 1)
    }
    
    private func handlePlayerHit(_ playerEntity: GKEntity) {
        // Use combat facade to adjust lives
        GameFacade.shared.combat.adjustLives(delta: -1)
    }
    
    private func handleEnemyDeath(_ event: EnemyDiedEvent) {
        // Spawn item drop if enemy has one
        if let itemType = event.dropItem,
           let transform = event.entity.component(ofType: TransformComponent.self) {
            GameFacade.shared.entities.spawnItem(type: itemType, at: transform.position, velocity: CGVector(dx: 0, dy: -50))
        }
    }
    
}
