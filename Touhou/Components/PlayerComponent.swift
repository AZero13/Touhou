//
//  PlayerComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit
import CoreGraphics

/// PlayerComponent - handles player state, input, movement, and shooting
final class PlayerComponent: GKComponent {
    var power: Int
    var lives: Int
    var bombs: Int
    var isFocused: Bool
    var score: Int
    var powerItemCountForScore: Int // For tracking power items collected when at full power
    
    // Internal state for update logic
    private var lastShotTime: TimeInterval = 0
    
    private enum Tuning {
        static let unfocusedSpeed: CGFloat = 270
        static let focusedSpeed: CGFloat = 135
        static let shotInterval: TimeInterval = 0.1
        static let shotOffsetY: CGFloat = 20
        static let sideShotOffsetX: CGFloat = 10
        static let bombClearEnemyBullets: Bool = true
    }
    
    init(power: Int = 0, lives: Int = 3, bombs: Int = 3, isFocused: Bool = false, score: Int = 0) {
        self.power = power
        self.lives = lives
        self.bombs = bombs
        self.isFocused = isFocused
        self.score = score
        self.powerItemCountForScore = 0
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - GameplayKit Update
    
    override func update(deltaTime: TimeInterval) {
        guard entity != nil else { return }
        
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
    
    // MARK: - Private Methods
    
    private func handleMovement(input: InputState, deltaTime: TimeInterval) {
        guard let transform = entity?.component(ofType: TransformComponent.self) else { return }
        
        // Calculate movement speed based on focus mode
        let speed: CGFloat = isFocused ? Tuning.focusedSpeed : Tuning.unfocusedSpeed
        
        // Apply movement
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
        isFocused = input.focus.isPressed
    }
    
    private func handleShooting(input: InputState, currentTime: TimeInterval) {
        guard let transform = entity?.component(ofType: TransformComponent.self) else { return }
        
        if input.shoot.isPressed && currentTime - lastShotTime > Tuning.shotInterval {
            lastShotTime = currentTime
            
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
        guard let entity = entity else { return }
        guard input.bomb.justPressed else { return }
        guard bombs > 0 else { return }
        
        // Activate bomb via facade
        GameFacade.shared.combat.activateBomb(playerEntity: entity)
        
        // Bomb clearing is handled in CombatFacade.activateBomb()
    }
}
