//
//  PlayerSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// PlayerSystem - handles all player logic (input, movement, shooting, lifecycle)
class PlayerSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    private var playerEntity: GKEntity?
    private var lastShotTime: TimeInterval = 0
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
        
        // Create initial player entity
        spawnPlayer()
    }
    
    func update(deltaTime: TimeInterval) {
        guard playerEntity != nil else { return }
        
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
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func spawnPlayer() {
        let entity = entityManager.createEntity()
        
        // Add components
        let playerComponent = PlayerComponent()
        print("🎮 Player created with lives: \(playerComponent.lives)")
        
        entity.addComponent(playerComponent)
        entity.addComponent(TransformComponent(position: CGPoint(x: 192, y: 50))) // Center bottom
        entity.addComponent(HitboxComponent(playerHitbox: 2.5, grazeZone: 30))
        // No HealthComponent - player just has lives, not HP
        
        playerEntity = entity
    }
    
    private func handleMovement(input: InputState, deltaTime: TimeInterval) {
        guard let playerEntity = playerEntity,
              let transform = playerEntity.component(ofType: TransformComponent.self),
              let player = playerEntity.component(ofType: PlayerComponent.self) else { return }
        
        // Calculate movement speed based on focus mode (units per second)
        let speed: CGFloat = player.isFocused ? 135 : 270 // 2.25 * 60fps, 4.5 * 60fps
        
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
        
        if input.shoot.isPressed && currentTime - lastShotTime > 0.1 { // 10 shots per second
            lastShotTime = currentTime
            
            // Reimu A shoots 3 bullets: 1 straight + 2 homing at angles
            
            // 1. Center bullet (straight up, non-homing)
            let centerBullet = entityManager.createEntity()
            centerBullet.addComponent(BulletComponent(
                ownedByPlayer: true,
                bulletType: "amulet",
                damage: 1
                // No homing properties = straight shot
            ))
            centerBullet.addComponent(TransformComponent(
                position: CGPoint(x: transform.position.x, y: transform.position.y + 20),
                velocity: CGVector(dx: 0, dy: 200) // Straight up (units per second)
            ))
            
            // 2. Left homing bullet
            let leftBullet = entityManager.createEntity()
            leftBullet.addComponent(BulletComponent(
                ownedByPlayer: true,
                bulletType: "homing_amulet",
                damage: 1,
                homingStrength: 0.15, // Based on touhou06 reference
                maxTurnRate: 1.2 // radians per second
            ))
            leftBullet.addComponent(TransformComponent(
                position: CGPoint(x: transform.position.x - 10, y: transform.position.y + 20),
                velocity: CGVector(dx: -50, dy: 180) // Angle left (units per second)
            ))
            
            // 3. Right homing bullet
            let rightBullet = entityManager.createEntity()
            rightBullet.addComponent(BulletComponent(
                ownedByPlayer: true,
                bulletType: "homing_amulet",
                damage: 1,
                homingStrength: 0.15, // Based on touhou06 reference
                maxTurnRate: 1.2 // radians per second
            ))
            rightBullet.addComponent(TransformComponent(
                position: CGPoint(x: transform.position.x + 10, y: transform.position.y + 20),
                velocity: CGVector(dx: 50, dy: 180) // Angle right (units per second)
            ))
        }
    }
    
    private func handleBomb(input: InputState) {
        guard let entity = playerEntity,
              let player = entity.component(ofType: PlayerComponent.self) else { return }
        guard input.bomb.justPressed else { return }
        guard player.bombs > 0 else { return }
        
        player.bombs -= 1
        eventBus.fire(BombsChangedEvent(newTotal: player.bombs))
        eventBus.fire(BombActivatedEvent(playerEntity: entity))
        
        // Clear enemy bullets immediately
        let bullets = entityManager.getEntities(with: BulletComponent.self)
        for b in bullets {
            if let comp = b.component(ofType: BulletComponent.self), !comp.ownedByPlayer {
                entityManager.markForDestruction(b)
            }
        }
    }
}
