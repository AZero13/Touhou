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
        // Ensure player exists after stage transitions or restarts
        if playerEntity == nil {
            spawnPlayer()
        } else if let player = playerEntity,
                  !entityManager.getAllEntities().contains(player) {
            spawnPlayer()
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        switch event {
        case is GameResumedEvent:
            // After unpausing, guarantee the player entity exists
            if playerEntity == nil {
                spawnPlayer()
            } else if let player = playerEntity,
                      !entityManager.getAllEntities().contains(player) {
                spawnPlayer()
            }
        case let e as StageStartedEvent:
            // New stage: ensure player is present and reset position to start
            if playerEntity == nil {
                spawnPlayer()
            } else if let player = playerEntity,
                      !entityManager.getAllEntities().contains(player) {
                spawnPlayer()
            }
            if let entity = playerEntity,
               let transform = entity.component(ofType: TransformComponent.self) {
                let area = GameFacade.playArea
                transform.position = CGPoint(x: area.midX, y: area.minY + Tuning.spawnYOffset)
            }
            // Starting a new run (stage 1): reset lives, bombs, and score
            if e.stageId == 1, let entity = playerEntity,
               let player = entity.component(ofType: PlayerComponent.self) {
                player.lives = 3
                player.bombs = 3
                player.score = 0
                eventBus.fire(LivesChangedEvent(newTotal: player.lives))
                eventBus.fire(BombsChangedEvent(newTotal: player.bombs))
                eventBus.fire(ScoreChangedEvent(newTotal: player.score))
            }
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func spawnPlayer() {
        let entity = entityManager.createEntity()
        
        // Add components
        let playerComponent = PlayerComponent()
        print("Player created with lives: \(playerComponent.lives)")
        
        entity.addComponent(playerComponent)
        let area = GameFacade.playArea
        let spawnPosition = CGPoint(x: area.midX, y: area.minY + Tuning.spawnYOffset)
        entity.addComponent(TransformComponent(position: spawnPosition))
        entity.addComponent(HitboxComponent(playerHitbox: Tuning.playerHitbox, grazeZone: Tuning.grazeHitbox))
        
        // Register with component systems after entity is fully set up
        GameFacade.shared.registerEntity(entity)
        
        playerEntity = entity
    }
}

