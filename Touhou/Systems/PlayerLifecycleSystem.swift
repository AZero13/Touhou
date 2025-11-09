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
        // Sync playerEntity reference with EntityManager
        syncPlayerEntity()
        
        // Safety fallback: only spawn recovery if player is missing during stable gameplay
        // Don't spawn if we're likely in a stage transition (events haven't processed yet)
        // Events are processed after systems update, so if StageStartedEvent just fired,
        // we should wait for it to process rather than spawning recovery
        if playerEntity == nil {
            // Only spawn recovery if we've been in this stage for at least one frame
            // This avoids spawning right after stage start when events haven't processed yet
            // We can detect this by checking if player was missing last frame too
            // For now, just spawn - the spawn methods check for existing player anyway
            // But log a warning to help debug if this happens unexpectedly
            print("Warning: Player missing during gameplay (stage \(GameFacade.shared.currentStage)), spawning as recovery")
            spawnPlayerRecovery()
        }
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
            // This ensures we have the latest reference from EntityManager
            syncPlayerEntity()
            
            // Stage 1 = new run: spawn player if missing, reset stats
            if e.stageId == 1 {
                if playerEntity == nil {
                    spawnPlayer()
                }
                // Always reset stats on stage 1 (new run)
                resetPlayerStats()
            } else {
                // Subsequent stages: player should persist from previous stage
                // Just reset position and stage-specific stats
                if let entity = playerEntity {
                    resetPlayerPosition(entity: entity)
                    if let player = entity.component(ofType: PlayerComponent.self) {
                        player.grazeInStage = 0
                    }
                } else {
                    // Player missing on non-stage-1: this is unexpected but recoverable
                    // Spawn player (preserves stats across stages, but player was destroyed somehow)
                    print("Warning: Player missing on stage \(e.stageId), spawning recovery player")
                    spawnPlayer()
                    // Don't reset stats - player should have stats from previous stage
                    // But since entity was destroyed, we can't preserve them
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
    
    /// Sync playerEntity reference with EntityManager
    /// - Updates reference if player exists in EntityManager
    /// - Clears reference (sets to nil) if player doesn't exist in EntityManager
    /// - Returns true if player exists, false if missing
    @discardableResult
    private func syncPlayerEntity() -> Bool {
        if let existingPlayer = entityManager.getPlayerEntity() {
            // Player exists - update reference if it's different
            if playerEntity !== existingPlayer {
                playerEntity = existingPlayer
            }
            return true
        } else {
            // Player doesn't exist - clear reference
            playerEntity = nil
            return false
        }
    }
    
    /// Spawn player with default stats (for new runs or stage 1)
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
    
    /// Spawn player as recovery during gameplay
    /// This is a safety fallback called from update() if player is missing
    /// Note: This might be called in the same frame as StageStartedEvent, but
    /// the duplicate check in spawnPlayer() prevents issues
    private func spawnPlayerRecovery() {
        // Use same spawn logic as normal spawn
        spawnPlayer()
        
        // Fire events to update UI with default stats
        // (spawnPlayer() doesn't fire events - they're fired by resetPlayerStats() for stage 1,
        // but recovery spawn happens outside event handler context)
        if let player = playerEntity?.component(ofType: PlayerComponent.self) {
            eventBus.fire(LivesChangedEvent(newTotal: player.lives))
            eventBus.fire(BombsChangedEvent(newTotal: player.bombs))
            eventBus.fire(ScoreChangedEvent(newTotal: player.score))
            eventBus.fire(PowerLevelChangedEvent(newTotal: player.power))
        }
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

