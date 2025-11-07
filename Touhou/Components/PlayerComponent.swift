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
    var grazeInStage: Int // Graze count for current stage (resets each stage)
    
    // Visual size (matches the rendered sprite radius)
    var visualRadius: CGFloat = 8.0
    
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
        self.grazeInStage = 0
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
        
        // Clamp to logical play area bounds (accounting for player visual radius)
        let area = GameFacade.playArea
        transform.position.x = max(area.minX + visualRadius, min(area.maxX - visualRadius, transform.position.x))
        transform.position.y = max(area.minY + visualRadius, min(area.maxY - visualRadius, transform.position.y))
        
        // Update focus state
        isFocused = input.focus.isPressed
    }
    
    private func handleShooting(input: InputState, currentTime: TimeInterval) {
        guard let transform = entity?.component(ofType: TransformComponent.self) else { return }
        guard input.shoot.isPressed && currentTime - lastShotTime > Tuning.shotInterval else { return }
        
        lastShotTime = currentTime
        let game = GameFacade.shared
        
        // TH06: Bullet patterns change based on power level
        let powerRank = PowerSystem.getPowerRank(power: power)
        spawnBulletsForPowerRank(powerRank: powerRank, transform: transform, game: game)
    }
    
    /// Spawn bullets based on current power rank (TH06-style power system)
    private func spawnBulletsForPowerRank(powerRank: Int, transform: TransformComponent, game: GameFacade) {
        // Simplified power-based patterns (can be expanded later with full TH06 data)
        switch powerRank {
        case 0: // Power < 8
            // Rank 0: Single center bullet
            game.entities.spawnBullet(
                position: CGPoint(x: transform.position.x, y: transform.position.y + Tuning.shotOffsetY),
                velocity: CGVector(dx: 0, dy: 200),
                bulletType: .amulet,
                ownedByPlayer: true,
                physics: PhysicsConfig(speed: 200, damage: 1),
                visual: VisualConfig(size: .small, shape: .circle, color: .red, hasTrail: false, trailLength: 3),
                behavior: BehaviorConfig()
            )
            
        case 1: // Power 8-15
            // Rank 1: Center + 2 side homing bullets
            spawnBasicHomingPattern(transform: transform, game: game)
            
        case 2: // Power 16-31
            // Rank 2: Center + wider spread
            spawnBasicHomingPattern(transform: transform, game: game)
            // Add slight angle spread to center
            game.entities.spawnBullet(
                position: CGPoint(x: transform.position.x, y: transform.position.y + Tuning.shotOffsetY),
                velocity: CGVector(dx: 0, dy: 200),
                bulletType: .amulet,
                ownedByPlayer: true,
                physics: PhysicsConfig(speed: 200, damage: 1),
                visual: VisualConfig(size: .small, shape: .circle, color: .red, hasTrail: false, trailLength: 3),
                behavior: BehaviorConfig()
            )
            
        case 3...4: // Power 32-63
            // Rank 3-4: More bullets, wider spread
            spawnBasicHomingPattern(transform: transform, game: game)
            // Additional angled shots
            game.entities.spawnBullet(
                position: CGPoint(x: transform.position.x - 8, y: transform.position.y + Tuning.shotOffsetY),
                velocity: CGVector(dx: -30, dy: 190),
                bulletType: .amulet,
                ownedByPlayer: true,
                physics: PhysicsConfig(speed: 190, damage: 1),
                visual: VisualConfig(size: .small, shape: .circle, color: .red, hasTrail: false, trailLength: 3),
                behavior: BehaviorConfig()
            )
            game.entities.spawnBullet(
                position: CGPoint(x: transform.position.x + 8, y: transform.position.y + Tuning.shotOffsetY),
                velocity: CGVector(dx: 30, dy: 190),
                bulletType: .amulet,
                ownedByPlayer: true,
                physics: PhysicsConfig(speed: 190, damage: 1),
                visual: VisualConfig(size: .small, shape: .circle, color: .red, hasTrail: false, trailLength: 3),
                behavior: BehaviorConfig()
            )
            
        case 5...6: // Power 64-95
            // Rank 5-6: Even more bullets
            spawnBasicHomingPattern(transform: transform, game: game)
            // Wide spread pattern
            for offset in [-12, -6, 0, 6, 12] {
                let offsetFloat = CGFloat(offset)
                game.entities.spawnBullet(
                    position: CGPoint(x: transform.position.x + offsetFloat, y: transform.position.y + Tuning.shotOffsetY),
                    velocity: CGVector(dx: offsetFloat * 2, dy: 200 - abs(offsetFloat) * 2),
                    bulletType: .amulet,
                    ownedByPlayer: true,
                    physics: PhysicsConfig(speed: 200, damage: 1),
                    visual: VisualConfig(size: .small, shape: .circle, color: .red, hasTrail: false, trailLength: 3),
                    behavior: BehaviorConfig()
                )
            }
            
        case 7...: // Power 96-128 (max power)
            // Rank 7-8: Maximum firepower
            spawnBasicHomingPattern(transform: transform, game: game)
            // Maximum spread pattern
            for offset in [-16, -12, -8, -4, 0, 4, 8, 12, 16] {
                let angle = Double(offset) * 0.05 // Slight angle based on offset
                game.entities.spawnBullet(
                    position: CGPoint(x: transform.position.x + CGFloat(offset), y: transform.position.y + Tuning.shotOffsetY),
                    velocity: CGVector(dx: CGFloat(sin(angle) * 200), dy: CGFloat(cos(angle) * 200)),
                    bulletType: offset == 0 ? .amulet : .homingAmulet,
                    ownedByPlayer: true,
                    physics: PhysicsConfig(speed: 200, damage: 1),
                    visual: VisualConfig(size: .small, shape: .circle, color: offset == 0 ? .red : .blue, hasTrail: false, trailLength: 3),
                    behavior: BehaviorConfig()
                )
            }
            
        default:
            // Fallback to basic pattern
            spawnBasicHomingPattern(transform: transform, game: game)
        }
    }
    
    /// Spawn basic homing pattern (center + 2 side homing bullets)
    private func spawnBasicHomingPattern(transform: TransformComponent, game: GameFacade) {
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
            visual: VisualConfig(size: .small, shape: .circle, color: .blue, hasTrail: false, trailLength: 3),
            behavior: BehaviorConfig()
        )
        
        // Right homing bullet
        game.entities.spawnBullet(
            position: CGPoint(x: transform.position.x + Tuning.sideShotOffsetX, y: transform.position.y + Tuning.shotOffsetY),
            velocity: CGVector(dx: 50, dy: 180),
            bulletType: .homingAmulet,
            ownedByPlayer: true,
            physics: PhysicsConfig(speed: 180, damage: 1),
            visual: VisualConfig(size: .small, shape: .circle, color: .blue, hasTrail: false, trailLength: 3),
            behavior: BehaviorConfig()
        )
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
