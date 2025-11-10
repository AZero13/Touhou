//
//  EnemyComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// EnemyComponent - handles enemy state, movement, shooting, and scoring
final class EnemyComponent: GKComponent {
    enum EnemyType: Equatable {
        case fairy
        case boss
    }
    var enemyType: EnemyType
    var scoreValue: Int
    var dropItem: ItemType? // What item this enemy drops (nil = no drop)
    var attackPattern: EnemyPattern
    var patternConfig: PatternConfig
    var lastShotTime: TimeInterval
    var shotInterval: TimeInterval
    
    init(enemyType: EnemyType, scoreValue: Int, dropItem: ItemType? = nil, 
         attackPattern: EnemyPattern = .singleShot, patternConfig: PatternConfig = PatternConfig(), 
         shotInterval: TimeInterval = 2.0) {
        self.enemyType = enemyType
        self.scoreValue = scoreValue
        self.dropItem = dropItem
        self.attackPattern = attackPattern
        self.patternConfig = patternConfig
        self.lastShotTime = 0
        self.shotInterval = shotInterval
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Shooting
    
    func canShoot(at currentTime: TimeInterval) -> Bool {
        return currentTime - lastShotTime >= shotInterval
    }
    
    func getBulletCommands(from position: CGPoint, targetPosition: CGPoint?) -> [BulletSpawnCommand] {
        return attackPattern.getBulletCommands(from: position, targetPosition: targetPosition, config: patternConfig)
    }
    
    // MARK: - GameplayKit Update
    
    override func update(deltaTime: TimeInterval) {
        guard let entity = entity,
              let transform = entity.component(ofType: TransformComponent.self) else { return }
        
        // Move enemy down
        transform.position.y += transform.velocity.dy * deltaTime
        
        // Mark enemies that go off bottom of screen for destruction
        if transform.position.y < -50 {
            GameFacade.shared.entities.destroy(entity)
            return
        }
        
        // Handle shooting (same pattern as PlayerComponent)
        if !GameFacade.shared.isTimeFrozen {
            handleShooting(currentTime: CACurrentMediaTime())
        }
    }
    
    // MARK: - Private Methods
    
    private func handleShooting(currentTime: TimeInterval) {
        guard let transform = entity?.component(ofType: TransformComponent.self) else { return }
        
        if canShoot(at: currentTime) {
            lastShotTime = currentTime
            
            // Get player position for aimed shots
            let playerPosition = GameFacade.shared.entities.player?.component(ofType: TransformComponent.self)?.position
            let commands = getBulletCommands(from: transform.position, targetPosition: playerPosition)
            
            // Spawn bullets via command queue
            for cmd in commands {
                GameFacade.shared.combat.spawnEnemyBullet(cmd)
            }
        }
    }
}
