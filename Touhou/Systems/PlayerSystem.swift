//
//  PlayerSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// PlayerSystem - handles all player logic (input, movement, shooting, lifecycle)
final class PlayerSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    private var playerEntity: GKEntity?
    private var lastShotTime: TimeInterval = 0
    
    private enum Tuning {
        static let unfocusedSpeed: CGFloat = 270    // units per second
        static let focusedSpeed: CGFloat = 135      // units per second
        static let shotInterval: TimeInterval = 0.1 // 10 shots per second
        static let spawnYOffset: CGFloat = 50       // distance above bottom edge
        static let grazeHitbox: CGFloat = 30
        static let playerHitbox: CGFloat = 2.5
        static let shotOffsetY: CGFloat = 20
        static let sideShotOffsetX: CGFloat = 10
        static let bombClearEnemyBullets: Bool = true
    }
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
        
        // Create initial player entity
        spawnPlayer()
    }
    
    func update(deltaTime: TimeInterval) {
        // Ensure player exists after stage transitions or restarts
        if playerEntity == nil {
            spawnPlayer()
        } else if let player = playerEntity,
                  !entityManager.getAllEntities().contains(player) {
            spawnPlayer()
        }
        guard playerEntity != nil else { return }
        
        // Skip all player actions if time is frozen
        if GameFacade.shared.isFrozen() {
            return
        }
        
        // Get current input
        let input = InputManager.shared.getCurrentInput()
        
        // Handle movement
        handleMovement(input: input, deltaTime: deltaTime)
        
        // Handle shooting
        handleShooting(input: input, currentTime: CACurrentMediaTime())
        
        // Handle bomb
        handleBomb(input: input)
    }
    
    func handleEvent(_ event: GameEvent) {
        // Ensure player lifecycle across state transitions
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
            // Starting a new run (stage 1): reset bombs and score
            if e.stageId == 1, let entity = playerEntity,
               let player = entity.component(ofType: PlayerComponent.self) {
                player.bombs = 3
                player.score = 0
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
        // No HealthComponent - player just has lives, not HP
        
        playerEntity = entity
    }
    
    private func handleMovement(input: InputState, deltaTime: TimeInterval) {
        guard let playerEntity = playerEntity,
              let transform = playerEntity.component(ofType: TransformComponent.self),
              let player = playerEntity.component(ofType: PlayerComponent.self) else { return }
        
        // Calculate movement speed based on focus mode (units per second)
        let speed: CGFloat = player.isFocused ? Tuning.focusedSpeed : Tuning.unfocusedSpeed
        
        // Apply movement (time-based)
        let movement = CGVector(
            dx: input.movement.dx * speed * deltaTime,
            dy: input.movement.dy * speed * deltaTime
        )
        
        transform.position.x += movement.dx
        transform.position.y += movement.dy
        
        // Clamp to logical play area bounds
        let area = GameFacade.playArea
        transform.position.x = max(area.minX, min(area.maxX, transform.position.x))
        transform.position.y = max(area.minY, min(area.maxY, transform.position.y))
        
        // Update focus state
        player.isFocused = input.focus.isPressed
    }
    
    private func handleShooting(input: InputState, currentTime: TimeInterval) {
        guard let playerEntity = playerEntity,
              let transform = playerEntity.component(ofType: TransformComponent.self) else { return }
        
        if input.shoot.isPressed && currentTime - lastShotTime > Tuning.shotInterval {
            lastShotTime = currentTime
            
            // Reimu A shoots 3 bullets: 1 straight + 2 homing at angles via EntityFacade
            let game = GameFacade.shared
            
            // Center bullet (straight up)
            game.entities.spawnBullet(
                position: CGPoint(x: transform.position.x, y: transform.position.y + Tuning.shotOffsetY),
                velocity: CGVector(dx: 0, dy: 200),
                bulletType: .amulet,
                ownedByPlayer: true,
                physics: PhysicsConfig(speed: 200, damage: 1),
                visual: VisualConfig(size: .small, shape: .circle, color: .red, hasTrail: false, trailLength: 3),
                behavior: BehaviorConfig(homingStrength: nil, maxTurnRate: nil, delay: 0)
            )
            
            // Left homing bullet
            game.entities.spawnBullet(
                position: CGPoint(x: transform.position.x - Tuning.sideShotOffsetX, y: transform.position.y + Tuning.shotOffsetY),
                velocity: CGVector(dx: -50, dy: 180),
                bulletType: .homingAmulet,
                ownedByPlayer: true,
                physics: PhysicsConfig(speed: 180, damage: 1),
                visual: VisualConfig(size: .small, shape: .circle, color: .red, hasTrail: false, trailLength: 3),
                behavior: BehaviorConfig()
            )
            
            // Right homing bullet
            game.entities.spawnBullet(
                position: CGPoint(x: transform.position.x + Tuning.sideShotOffsetX, y: transform.position.y + Tuning.shotOffsetY),
                velocity: CGVector(dx: 50, dy: 180),
                bulletType: .homingAmulet,
                ownedByPlayer: true,
                physics: PhysicsConfig(speed: 180, damage: 1),
                visual: VisualConfig(size: .small, shape: .circle, color: .red, hasTrail: false, trailLength: 3),
                behavior: BehaviorConfig()
            )
        }
    }
    
    private func handleBomb(input: InputState) {
        guard let entity = playerEntity,
              let player = entity.component(ofType: PlayerComponent.self) else { return }
        guard input.bomb.justPressed else { return }
        guard player.bombs > 0 else { return }
        
        // Activate bomb via facade
        GameFacade.shared.combat.activateBomb(playerEntity: entity)
        
        // Clear enemy bullets immediately
        if Tuning.bombClearEnemyBullets {
            BulletUtility.clearEnemyBullets(entityManager: entityManager)
        }
    }
}
