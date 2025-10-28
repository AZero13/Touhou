//
//  HealthSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// HealthSystem - handles health and death logic
class HealthSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Update invulnerability timers for enemies
        let entitiesWithHealth = entityManager.getEntities(with: HealthComponent.self)
        
        for entity in entitiesWithHealth {
            guard let health = entity.component(ofType: HealthComponent.self) else { continue }
            
            // Decrease invulnerability timer
            if health.invulnerabilityTimer > 0 {
                health.invulnerabilityTimer -= deltaTime
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        if let collisionEvent = event as? CollisionOccurredEvent {
            print("📨 HealthSystem received collision event: \(collisionEvent.collisionType)")
            handleCollisionEvent(collisionEvent)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleCollisionEvent(_ event: CollisionOccurredEvent) {
        switch event.collisionType {
        case "player_bullet_hit_enemy":
            handleEnemyHit(event.entityB) // entityB is the enemy
            
        case "enemy_bullet_hit_player":
            handlePlayerHit(event.entityB) // entityB is the player
            
        case "enemy_touch_player":
            handlePlayerHit(event.entityB) // entityB is the player
            
        default:
            break
        }
    }
    
    private func handleEnemyHit(_ enemyEntity: GKEntity) {
        guard let health = enemyEntity.component(ofType: HealthComponent.self),
              let enemy = enemyEntity.component(ofType: EnemyComponent.self) else { return }
        
        print("💥 Enemy took damage! Health: \(health.current)")
        
        // Apply damage
        health.current -= 1
        
        // Check if enemy dies
        if health.current <= 0 {
            print("💀 Enemy died!")
            
            // Fire enemy death event
            eventBus.fire(EnemyDiedEvent(
                entity: enemyEntity,
                scoreValue: enemy.scoreValue,
                dropTable: enemy.dropTable
            ))
            
            // Mark enemy for destruction
            entityManager.markForDestruction(enemyEntity)
        }
    }
    
    private func handlePlayerHit(_ playerEntity: GKEntity) {
        guard let player = playerEntity.component(ofType: PlayerComponent.self) else { return }
        
        print("💥 Player hit! Lives before: \(player.lives)")
        
        // Decrease lives
        player.lives -= 1
        
        print("💥 Player hit! Lives after: \(player.lives)")
        
        // Check if player dies
        if player.lives <= 0 {
            print("💀 Player died! Game over!")
            
            // Fire game over event
            eventBus.fire(GameOverEvent(finalScore: player.score))
        } else {
            print("🔄 Player respawning... Lives remaining: \(player.lives)")
            
            // Respawn player immediately
            respawnPlayer(playerEntity)
        }
    }
    
    private func respawnPlayer(_ playerEntity: GKEntity) {
        guard let transform = playerEntity.component(ofType: TransformComponent.self) else { 
            print("❌ Failed to respawn player - missing transform component")
            return 
        }
        
        print("🔄 Respawning player at bottom center")
        
        // Reset position to bottom center
        transform.position = CGPoint(x: 192, y: 50)
        
        // Fire respawn event
        eventBus.fire(PlayerRespawnedEvent(entity: playerEntity))
        
        print("✅ Player respawned successfully")
    }
}