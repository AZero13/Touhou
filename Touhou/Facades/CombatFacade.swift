//
//  CombatFacade.swift
//  Touhou
//
//  Created by Assistant on 11/02/25.
//

import Foundation
import GameplayKit

/// CombatFacade - Simplified API for combat operations
/// Hides complexity of CommandQueue, HealthComponent, and damage calculations
final class CombatFacade {
    private let entityManager: EntityManager
    private let commandQueue: CommandQueue
    private let eventBus: EventBus
    
    init(entityManager: EntityManager, commandQueue: CommandQueue, eventBus: EventBus) {
        self.entityManager = entityManager
        self.commandQueue = commandQueue
        self.eventBus = eventBus
    }
    
    // MARK: - Damage Operations
    
    /// Apply damage to an entity
    func damage(_ entity: GKEntity, amount: Int) {
        commandQueue.enqueue(.applyDamage(entity: entity, amount: amount))
    }
    
    /// Heal an entity by amount
    func heal(_ entity: GKEntity, amount: Int) {
        guard let healthComp = entity.component(ofType: HealthComponent.self) else {
            return
        }
        
        healthComp.health = min(healthComp.maxHealth, healthComp.health + amount)
    }
    
    // MARK: - Player Resources
    
    /// Adjust player lives
    func adjustLives(delta: Int) {
        commandQueue.enqueue(.adjustLives(delta: delta))
    }
    
    /// Adjust player bombs
    func adjustBombs(delta: Int) {
        commandQueue.enqueue(.adjustBombs(delta: delta))
    }
    
    /// Adjust player power level
    func adjustPower(delta: Int) {
        commandQueue.enqueue(.adjustPower(delta: delta))
    }
    
    /// Adjust score
    func adjustScore(amount: Int) {
        commandQueue.enqueue(.adjustScore(amount: amount))
    }
    
    // MARK: - Bomb Operations
    
    /// Activate bomb (clears enemy bullets and damages enemies)
    func activateBomb(playerEntity: GKEntity) {
        // Clear all enemy bullets
        CommandQueue.despawnAllBullets(entityManager: entityManager) { bullet in
            !bullet.ownedByPlayer
        }
        
        // Damage all enemies
        let enemies = entityManager.getEntities(with: EnemyComponent.self)
        for enemy in enemies {
            damage(enemy, amount: 50)
        }
        
        // Fire bomb event
        eventBus.fire(BombActivatedEvent(playerEntity: playerEntity))
        
        // Deduct a bomb
        adjustBombs(delta: -1)
    }
    
    // MARK: - Helper Methods
    
    /// Spawn enemy bullet (for component use)
    func spawnEnemyBullet(_ command: BulletSpawnCommand) {
        commandQueue.enqueue(.spawnBullet(command, ownedByPlayer: false))
    }
    
    /// Fire item collection event (for component use)
    func fireItemCollectionEvent(itemType: ItemType, value: Int, position: CGPoint) {
        eventBus.fire(PowerUpCollectedEvent(itemType: itemType, value: value, position: position))
    }
}

