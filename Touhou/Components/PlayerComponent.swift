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
    
    // MARK: - Constants
    
    private enum Tuning {
        static let unfocusedSpeed: CGFloat = 270
        static let focusedSpeed: CGFloat = 135
        static let shotInterval: TimeInterval = 0.1
        static let shotOffsetY: CGFloat = 20
        static let sideShotOffsetX: CGFloat = 10
        static let bombClearEnemyBullets: Bool = true
    }
    
    /// Constants for player bullet patterns
    private enum BulletPattern {
        static let defaultSpeed: CGFloat = 200
        static let homingSpeed: CGFloat = 180
        static let defaultDamage: Int = 1
        static let sideShotVelocityX: CGFloat = 50
        static let sideShotVelocityY: CGFloat = 180
        
        // Spread pattern offsets for different power ranks
        static let rank3Offsets: [CGFloat] = [-8, 8]
        static let rank5Offsets: [CGFloat] = [-12, -6, 0, 6, 12]
        static let rank7Offsets: [CGFloat] = [-16, -12, -8, -4, 0, 4, 8, 12, 16]
        
        // Angle calculations for max power pattern
        static let maxPowerAngleMultiplier: Double = 0.05
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
        switch powerRank {
        case 0:
            spawnRank0Pattern(transform: transform, game: game)
        case 1:
            spawnRank1Pattern(transform: transform, game: game)
        case 2:
            spawnRank2Pattern(transform: transform, game: game)
        case 3...4:
            spawnRank3Pattern(transform: transform, game: game)
        case 5...6:
            spawnRank5Pattern(transform: transform, game: game)
        case 7...:
            spawnRank7Pattern(transform: transform, game: game)
        default:
            spawnBasicHomingPattern(transform: transform, game: game)
        }
    }
    
    // MARK: - Power Rank Bullet Patterns
    
    /// Rank 0: Single center bullet (Power < 8)
    private func spawnRank0Pattern(transform: TransformComponent, game: GameFacade) {
        spawnCenterBullet(transform: transform, game: game)
    }
    
    /// Rank 1: Center + 2 side homing bullets (Power 8-15)
    private func spawnRank1Pattern(transform: TransformComponent, game: GameFacade) {
        spawnBasicHomingPattern(transform: transform, game: game)
    }
    
    /// Rank 2: Center + wider spread (Power 16-31)
    private func spawnRank2Pattern(transform: TransformComponent, game: GameFacade) {
        spawnBasicHomingPattern(transform: transform, game: game)
        spawnCenterBullet(transform: transform, game: game)
    }
    
    /// Rank 3-4: More bullets, wider spread (Power 32-63)
    private func spawnRank3Pattern(transform: TransformComponent, game: GameFacade) {
        spawnBasicHomingPattern(transform: transform, game: game)
        for offset in BulletPattern.rank3Offsets {
            spawnAngledBullet(transform: transform, offset: offset, game: game)
        }
    }
    
    /// Rank 5-6: Even more bullets (Power 64-95)
    private func spawnRank5Pattern(transform: TransformComponent, game: GameFacade) {
        spawnBasicHomingPattern(transform: transform, game: game)
        for offset in BulletPattern.rank5Offsets {
            spawnSpreadBullet(transform: transform, offset: offset, game: game)
        }
    }
    
    /// Rank 7-8: Maximum firepower (Power 96-128)
    private func spawnRank7Pattern(transform: TransformComponent, game: GameFacade) {
        spawnBasicHomingPattern(transform: transform, game: game)
        for offset in BulletPattern.rank7Offsets {
            spawnMaxPowerBullet(transform: transform, offset: offset, game: game)
        }
    }
    
    // MARK: - Bullet Spawning Helpers
    
    /// Spawn a single center bullet (straight up)
    private func spawnCenterBullet(transform: TransformComponent, game: GameFacade) {
        let position = CGPoint(x: transform.position.x, y: transform.position.y + Tuning.shotOffsetY)
        let velocity = CGVector(dx: 0, dy: BulletPattern.defaultSpeed)
        spawnPlayerBullet(position: position, velocity: velocity, bulletType: .amulet, game: game)
    }
    
    /// Spawn an angled bullet (for rank 3 pattern)
    private func spawnAngledBullet(transform: TransformComponent, offset: CGFloat, game: GameFacade) {
        let position = CGPoint(x: transform.position.x + offset, y: transform.position.y + Tuning.shotOffsetY)
        let velocity = CGVector(dx: offset * 3.75, dy: BulletPattern.homingSpeed) // -30/8 = 3.75
        spawnPlayerBullet(position: position, velocity: velocity, bulletType: .amulet, game: game)
    }
    
    /// Spawn a spread bullet (for rank 5 pattern)
    private func spawnSpreadBullet(transform: TransformComponent, offset: CGFloat, game: GameFacade) {
        let position = CGPoint(x: transform.position.x + offset, y: transform.position.y + Tuning.shotOffsetY)
        let velocity = CGVector(dx: offset * 2, dy: BulletPattern.defaultSpeed - abs(offset) * 2)
        spawnPlayerBullet(position: position, velocity: velocity, bulletType: .amulet, game: game)
    }
    
    /// Spawn a max power bullet (for rank 7 pattern)
    private func spawnMaxPowerBullet(transform: TransformComponent, offset: CGFloat, game: GameFacade) {
        let position = CGPoint(x: transform.position.x + offset, y: transform.position.y + Tuning.shotOffsetY)
        let angle = Double(offset) * BulletPattern.maxPowerAngleMultiplier
        let velocity = CGVector(
            dx: CGFloat(sin(angle) * Double(BulletPattern.defaultSpeed)),
            dy: CGFloat(cos(angle) * Double(BulletPattern.defaultSpeed))
        )
        let bulletType: BulletComponent.BulletType = offset == 0 ? .amulet : .homingAmulet
        let color: BulletColor = offset == 0 ? .red : .blue
        spawnPlayerBullet(position: position, velocity: velocity, bulletType: bulletType, color: color, game: game)
    }
    
    /// Spawn a player bullet with standard configuration
    private func spawnPlayerBullet(
        position: CGPoint,
        velocity: CGVector,
        bulletType: BulletComponent.BulletType,
        color: BulletColor = .red,
        speed: CGFloat? = nil,
        game: GameFacade
    ) {
        let bulletSpeed = speed ?? (bulletType == .homingAmulet ? BulletPattern.homingSpeed : BulletPattern.defaultSpeed)
        game.entities.spawnBullet(
            position: position,
            velocity: velocity,
            bulletType: bulletType,
            ownedByPlayer: true,
            physics: PhysicsConfig(speed: bulletSpeed, damage: BulletPattern.defaultDamage),
            visual: VisualConfig(size: .small, shape: .circle, color: color, hasTrail: false, trailLength: 3),
            behavior: BehaviorConfig()
        )
    }
    
    /// Spawn basic homing pattern (center + 2 side homing bullets)
    private func spawnBasicHomingPattern(transform: TransformComponent, game: GameFacade) {
        // Center bullet (straight up)
        spawnCenterBullet(transform: transform, game: game)
        
        // Left homing bullet
        let leftPosition = CGPoint(x: transform.position.x - Tuning.sideShotOffsetX, y: transform.position.y + Tuning.shotOffsetY)
        let leftVelocity = CGVector(dx: -BulletPattern.sideShotVelocityX, dy: BulletPattern.sideShotVelocityY)
        spawnPlayerBullet(position: leftPosition, velocity: leftVelocity, bulletType: .homingAmulet, color: .blue, game: game)
        
        // Right homing bullet
        let rightPosition = CGPoint(x: transform.position.x + Tuning.sideShotOffsetX, y: transform.position.y + Tuning.shotOffsetY)
        let rightVelocity = CGVector(dx: BulletPattern.sideShotVelocityX, dy: BulletPattern.sideShotVelocityY)
        spawnPlayerBullet(position: rightPosition, velocity: rightVelocity, bulletType: .homingAmulet, color: .blue, game: game)
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
