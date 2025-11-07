//
//  PlayerLifecycleSystem.swift
//  Touhou
//
//  Created by Assistant on 11/02/25.
//

import Foundation
import GameplayKit

/// PlayerLifecycleSystem - handles player spawning and lifecycle management
/// Update logic is now in PlayerComponent.update(deltaTime:)
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
        
        // Don't spawn player here - GameFacade is still initializing!
        // Player will be spawned on first update() call
    }
    
    func update(deltaTime: TimeInterval) {
        // Ensure player exists - only spawn if truly missing
        // Player should persist across stages (power is preserved)
        if playerEntity == nil {
            spawnPlayer()
        } else if let player = playerEntity,
                  !entityManager.getAllEntities().contains(player) {
            // Player was destroyed (shouldn't happen between stages)
            // Preserve power if possible, but this shouldn't happen in normal gameplay
            let oldPower = player.component(ofType: PlayerComponent.self)?.power ?? 0
            spawnPlayer()
            // Try to restore power if we had it (shouldn't be needed, but safety check)
            if oldPower > 0, let newPlayer = playerEntity?.component(ofType: PlayerComponent.self) {
                newPlayer.power = oldPower
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        switch event {
        case let e as PlayerRespawnedEvent:
            // Player respawned (e.g., after losing a life) - reset position and set invulnerability
            resetPlayerPosition(entity: e.entity)
            // TH06: Player is invulnerable after respawning (same as initial spawn)
            if let playerHealth = e.entity.component(ofType: HealthComponent.self) {
                playerHealth.invulnerabilityTimer = 2.0
            }
        case let e as StageStartedEvent:
            // New stage: reset position to start
            if let entity = playerEntity {
                resetPlayerPosition(entity: entity)
                // Reset graze count for new stage (TH06 behavior)
                if let player = entity.component(ofType: PlayerComponent.self) {
                    player.grazeInStage = 0
                }
            }
            // Stage 1 = new run: reset stats
            if e.stageId == 1 {
                resetPlayerStats()
            }
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    /// Reset player stats to initial values (for new run - stage 1 only)
    private func resetPlayerStats() {
        guard let entity = playerEntity,
              let player = entity.component(ofType: PlayerComponent.self) else { return }
        // TH06: Reset all stats on new run (stage 1)
        player.lives = 3
        player.bombs = 3
        player.score = 0
        player.power = 0  // Reset power only on new run
        player.powerItemCountForScore = 0
        eventBus.fire(LivesChangedEvent(newTotal: player.lives))
        eventBus.fire(BombsChangedEvent(newTotal: player.bombs))
        eventBus.fire(ScoreChangedEvent(newTotal: player.score))
        eventBus.fire(PowerLevelChangedEvent(newTotal: player.power))
    }
    
    private func spawnPlayer() {
        let entity = entityManager.createEntity()
        
        // Add components
        let playerComponent = PlayerComponent()
        print("Player created with lives: \(playerComponent.lives)")
        
        entity.addComponent(playerComponent)
        resetPlayerPosition(entity: entity)
        entity.addComponent(HitboxComponent(playerHitbox: Tuning.playerHitbox, grazeZone: Tuning.grazeHitbox))
        
        // Add HealthComponent to track invulnerability (player doesn't have health, but needs invulnerability state)
        // TH06: Player is invulnerable for a period after spawning/respawning
        entity.addComponent(HealthComponent(current: 1, max: 1, invulnerabilityTimer: 2.0))
        
        // Register with component systems after entity is fully set up
        GameFacade.shared.registerEntity(entity)
        
        playerEntity = entity
    }
    
    /// Reset player position to starting spawn position
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

