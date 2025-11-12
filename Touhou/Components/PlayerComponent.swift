//
//  PlayerComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit
import CoreGraphics

final class PlayerComponent: GKComponent {
    private var _power: Int
    
    var power: Int {
        get { _power }
        set {
            _power = max(0, min(newValue, 128))
        }
    }
    
    var lives: Int
    private var _bombs: Int
    
    var bombs: Int {
        get { _bombs }
        set {
            _bombs = max(0, min(newValue, 8))
        }
    }
    
    var isFocused: Bool
    var score: Int
    var powerItemCountForScore: Int
    var grazeInStage: Int
    var visualRadius: CGFloat = 8.0
    
    @inlinable
    var powerRank: Int {
        PowerSystem.getPowerRank(power: power)
    }
    
    private var lastShotTime: TimeInterval = 0
    
    private static let unfocusedSpeed: CGFloat = 270
    private static let focusedSpeed: CGFloat = 135
    private static let shotInterval: TimeInterval = 0.1
    private static let shotOffsetY: CGFloat = 20
    private static let sideShotOffsetX: CGFloat = 10
    
    private static let bulletSpeed: CGFloat = 200
    private static let homingSpeed: CGFloat = 180
    private static let bulletDamage: Int = 1
    private static let sideShotVelocityX: CGFloat = 50
    private static let sideShotVelocityY: CGFloat = 180
    private static let rank3Offsets: [CGFloat] = [-8, 8]
    private static let rank5Offsets: [CGFloat] = [-12, -6, 0, 6, 12]
    private static let rank7Offsets: [CGFloat] = [-16, -12, -8, -4, 0, 4, 8, 12, 16]
    private static let maxPowerAngleMultiplier: Double = 0.05
    
    init(power: Int = 0, lives: Int = 3, bombs: Int = 3, isFocused: Bool = false, score: Int = 0) {
        self._power = max(0, min(power, 128))
        self.lives = lives
        self._bombs = max(0, min(bombs, 8))
        self.isFocused = isFocused
        self.score = score
        self.powerItemCountForScore = 0
        self.grazeInStage = 0
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime: TimeInterval) {
        guard entity != nil else { return }
        if GameFacade.shared.isTimeFrozen { return }
        
        let input = InputManager.shared.currentInput
        handleMovement(input: input, deltaTime: deltaTime)
        handleShooting(input: input, currentTime: CACurrentMediaTime())
        handleBomb(input: input)
    }
    
    private func handleMovement(input: InputState, deltaTime: TimeInterval) {
        guard let transform = entity?.component(ofType: TransformComponent.self) else { return }
        
        let speed: CGFloat = isFocused ? Self.focusedSpeed : Self.unfocusedSpeed
        let movement = CGVector(
            dx: input.movement.dx * speed * deltaTime,
            dy: input.movement.dy * speed * deltaTime
        )
        
        transform.position.x += movement.dx
        transform.position.y += movement.dy
        
        let area = GameFacade.playArea
        transform.position.x = max(area.minX + visualRadius, min(area.maxX - visualRadius, transform.position.x))
        transform.position.y = max(area.minY + visualRadius, min(area.maxY - visualRadius, transform.position.y))
        
        isFocused = input.focus.isPressed
    }
    
    private func handleShooting(input: InputState, currentTime: TimeInterval) {
        guard let transform = entity?.component(ofType: TransformComponent.self) else { return }
        guard input.shoot.isPressed && currentTime - lastShotTime > Self.shotInterval else { return }
        
        lastShotTime = currentTime
        spawnBulletsForPowerRank(powerRank: powerRank, transform: transform, game: GameFacade.shared)
    }
    
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
    
    private func spawnRank0Pattern(transform: TransformComponent, game: GameFacade) {
        spawnCenterBullet(transform: transform, game: game)
    }
    
    private func spawnRank1Pattern(transform: TransformComponent, game: GameFacade) {
        spawnBasicHomingPattern(transform: transform, game: game)
    }
    
    private func spawnRank2Pattern(transform: TransformComponent, game: GameFacade) {
        spawnBasicHomingPattern(transform: transform, game: game)
        spawnCenterBullet(transform: transform, game: game)
    }
    
    private func spawnRank3Pattern(transform: TransformComponent, game: GameFacade) {
        spawnBasicHomingPattern(transform: transform, game: game)
        for offset in Self.rank3Offsets {
            spawnAngledBullet(transform: transform, offset: offset, game: game)
        }
    }
    
    private func spawnRank5Pattern(transform: TransformComponent, game: GameFacade) {
        spawnBasicHomingPattern(transform: transform, game: game)
        for offset in Self.rank5Offsets {
            spawnSpreadBullet(transform: transform, offset: offset, game: game)
        }
    }
    
    private func spawnRank7Pattern(transform: TransformComponent, game: GameFacade) {
        spawnBasicHomingPattern(transform: transform, game: game)
        for offset in Self.rank7Offsets {
            spawnMaxPowerBullet(transform: transform, offset: offset, game: game)
        }
    }
    
    private func spawnCenterBullet(transform: TransformComponent, game: GameFacade) {
        let position = CGPoint(x: transform.position.x, y: transform.position.y + Self.shotOffsetY)
        let velocity = CGVector(dx: 0, dy: Self.bulletSpeed)
        spawnPlayerBullet(position: position, velocity: velocity, bulletType: .amulet, game: game)
    }
    
    private func spawnAngledBullet(transform: TransformComponent, offset: CGFloat, game: GameFacade) {
        let position = CGPoint(x: transform.position.x + offset, y: transform.position.y + Self.shotOffsetY)
        let velocity = CGVector(dx: offset * 3.75, dy: Self.homingSpeed)
        spawnPlayerBullet(position: position, velocity: velocity, bulletType: .amulet, game: game)
    }
    
    private func spawnSpreadBullet(transform: TransformComponent, offset: CGFloat, game: GameFacade) {
        let position = CGPoint(x: transform.position.x + offset, y: transform.position.y + Self.shotOffsetY)
        let velocity = CGVector(dx: offset * 2, dy: Self.bulletSpeed - abs(offset) * 2)
        spawnPlayerBullet(position: position, velocity: velocity, bulletType: .amulet, game: game)
    }
    
    private func spawnMaxPowerBullet(transform: TransformComponent, offset: CGFloat, game: GameFacade) {
        let position = CGPoint(x: transform.position.x + offset, y: transform.position.y + Self.shotOffsetY)
        let angle = Double(offset) * Self.maxPowerAngleMultiplier
        let velocity = CGVector(
            dx: CGFloat(sin(angle) * Double(Self.bulletSpeed)),
            dy: CGFloat(cos(angle) * Double(Self.bulletSpeed))
        )
        let bulletType: BulletComponent.BulletType = offset == 0 ? .amulet : .homingAmulet
        let color: BulletColor = offset == 0 ? .red : .blue
        spawnPlayerBullet(position: position, velocity: velocity, bulletType: bulletType, color: color, game: game)
    }
    
    private func spawnPlayerBullet(
        position: CGPoint,
        velocity: CGVector,
        bulletType: BulletComponent.BulletType,
        color: BulletColor = .red,
        speed: CGFloat? = nil,
        game: GameFacade
    ) {
        let bulletSpeed = speed ?? (bulletType == .homingAmulet ? Self.homingSpeed : Self.bulletSpeed)
        game.entities.spawnBullet(
            position: position,
            velocity: velocity,
            bulletType: bulletType,
            ownedByPlayer: true,
            physics: PhysicsConfig(speed: bulletSpeed, damage: Self.bulletDamage),
            visual: VisualConfig(size: .small, shape: .circle, color: color, hasTrail: false, trailLength: 3),
            behavior: BehaviorConfig()
        )
    }
    
    private func spawnBasicHomingPattern(transform: TransformComponent, game: GameFacade) {
        spawnCenterBullet(transform: transform, game: game)
        
        let leftPosition = CGPoint(x: transform.position.x - Self.sideShotOffsetX, y: transform.position.y + Self.shotOffsetY)
        let leftVelocity = CGVector(dx: -Self.sideShotVelocityX, dy: Self.sideShotVelocityY)
        spawnPlayerBullet(position: leftPosition, velocity: leftVelocity, bulletType: .homingAmulet, color: .blue, game: game)
        
        let rightPosition = CGPoint(x: transform.position.x + Self.sideShotOffsetX, y: transform.position.y + Self.shotOffsetY)
        let rightVelocity = CGVector(dx: Self.sideShotVelocityX, dy: Self.sideShotVelocityY)
        spawnPlayerBullet(position: rightPosition, velocity: rightVelocity, bulletType: .homingAmulet, color: .blue, game: game)
    }
    
    private func handleBomb(input: InputState) {
        guard let entity = entity else { return }
        guard input.bomb.justPressed else { return }
        guard bombs > 0 else { return }
        GameFacade.shared.activateBomb(playerEntity: entity)
    }
}
