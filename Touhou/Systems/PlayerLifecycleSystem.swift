//
//  PlayerLifecycleSystem.swift
//
//  Created by Rose on 11/02/25.
//

import Foundation
import GameplayKit

/// PlayerLifecycleSystem - handles player spawning and lifecycle management
final class PlayerLifecycleSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    private var playerEntity: GKEntity?
    
    private enum Tuning {
        static let spawnYOffset: CGFloat = 50
        static let grazeHitbox: CGFloat = 30
        static let playerHitbox: CGFloat = 2.5
    }
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        syncPlayerEntity()
    }
    
    func handleEvent(_ event: GameEvent) {
        switch event {
        case let e as PlayerRespawnedEvent:
            // Player respawned (e.g., after losing a life) - reset position and set invulnerability
            resetPlayerPosition(entity: e.entity)
            if let playerHealth = e.entity.component(ofType: HealthComponent.self) {
                playerHealth.invulnerabilityTimer = 2.0
            }
        case let e as StageStartedEvent:
            // Sync playerEntity reference before handling stage start
            syncPlayerEntity()
            
            // Stage 1 = new run: spawn player if missing, reset stats
            if e.stageId == 1 {
                if playerEntity == nil {
                    spawnPlayer()
                }
                resetPlayerStats()
            } else {
                // Subsequent stages: player should exist, just reset position
                if let entity = playerEntity {
                    resetPlayerPosition(entity: entity)
                    if let player = entity.component(ofType: PlayerComponent.self) {
                        player.grazeInStage = 0
                    }
                } else {
                    // Player missing on non-stage-1: spawn as recovery
                    print("Warning: Player missing on stage \(e.stageId), spawning")
                    spawnPlayer()
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    /// Reset player stats to initial values (for new run - stage 1 only)
    private func resetPlayerStats() {
        guard let entity = playerEntity,
              let player = entity.component(ofType: PlayerComponent.self) else {
            print("Warning: Cannot reset player stats - player entity or component missing")
            return
        }

        player.lives = 3
        player.bombs = 3
        player.score = 0
        player.power = 0
        player.powerItemCountForScore = 0
        eventBus.fire(LivesChangedEvent(newTotal: player.lives))
        eventBus.fire(BombsChangedEvent(newTotal: player.bombs))
        eventBus.fire(ScoreChangedEvent(newTotal: player.score))
        eventBus.fire(PowerLevelChangedEvent(newTotal: player.power))
    }
    
    /// Sync playerEntity reference with EntityManager (handles cases where player exists but reference is stale)
    private func syncPlayerEntity() {
        if let existingPlayer = entityManager.getPlayerEntity() {
            if playerEntity !== existingPlayer {
                playerEntity = existingPlayer
            }
        }
    }
    
    private func spawnPlayer() {
        // Check if player already exists in EntityManager (shouldn't happen)
        if let existingPlayer = entityManager.getPlayerEntity() {
            print("Warning: Player already exists in EntityManager, using existing player")
            playerEntity = existingPlayer
            return
        }
        
        let entity = entityManager.createEntity()
        
        let playerComponent = PlayerComponent()
        entity.addComponent(playerComponent)
        resetPlayerPosition(entity: entity)
        entity.addComponent(HitboxComponent(playerHitbox: Tuning.playerHitbox, grazeZone: Tuning.grazeHitbox))
        
        // Add HealthComponent to track invulnerability
        entity.addComponent(HealthComponent(health: 1, maxHealth: 1, invulnerabilityTimer: 2.0))
        playerEntity = entity
        GameFacade.shared.registerEntity(entity)
    }
    
    private func resetPlayerPosition(entity: GKEntity) {
        let area = GameFacade.playArea
        let spawnPosition = CGPoint(x: area.midX, y: area.minY + Tuning.spawnYOffset)
        if let existingTransform = entity.component(ofType: TransformComponent.self) {
            existingTransform.position = spawnPosition
        } else {
            entity.addComponent(TransformComponent(position: spawnPosition))
        }
    }
}

