//
//  EnemyComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

// MARK: - Protocols

/// Protocol for entities that can shoot
protocol Shootable {
    var attackPattern: EnemyPattern { get }
    var patternConfig: PatternConfig { get }
    var lastShotTime: TimeInterval { get set }
    var shotInterval: TimeInterval { get }
    
    func canShoot(at currentTime: TimeInterval) -> Bool
    func getBulletCommands(from position: CGPoint, targetPosition: CGPoint?) -> [BulletSpawnCommand]
}

/// Protocol for entities that drop items
protocol Droppable {
    var dropItem: ItemType? { get }
}

/// Protocol for entities that can be scored
protocol Scoreable {
    var scoreValue: Int { get }
}

// MARK: - Component

/// EnemyComponent - handles enemy state, movement, shooting, and scoring
final class EnemyComponent: GKComponent, Shootable, Droppable, Scoreable {
    enum EnemyType: Equatable {
        case fairy
        case custom(String)
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
    
    // MARK: - Protocol Conformance
    
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
        if !GameFacade.shared.isFrozen() {
            handleShooting(currentTime: CACurrentMediaTime())
        }
    }
    
    // MARK: - Private Methods
    
    private func handleShooting(currentTime: TimeInterval) {
        guard let transform = entity?.component(ofType: TransformComponent.self) else { return }
        
        if canShoot(at: currentTime) {
            lastShotTime = currentTime
            
            // Get player position for aimed shots
            let playerPosition = PlayerUtility.getPosition(entityManager: GameFacade.shared.getEntityManager())
            let commands = getBulletCommands(from: transform.position, targetPosition: playerPosition)
            
            // Spawn bullets via facade
            for cmd in commands {
                GameFacade.shared.getCommandQueue().enqueue(.spawnBullet(cmd, ownedByPlayer: false))
            }
        }
    }
}
