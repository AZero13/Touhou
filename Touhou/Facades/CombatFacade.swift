//
//  CombatFacade.swift
//  Touhou
//
//  Created by Rose on 11/02/25.
//

import Foundation
import GameplayKit

final class CombatFacade {
    private let entityManager: EntityManager
    private let commandQueue: CommandQueue
    private let eventBus: EventBus
    
    init(entityManager: EntityManager, commandQueue: CommandQueue, eventBus: EventBus) {
        self.entityManager = entityManager
        self.commandQueue = commandQueue
        self.eventBus = eventBus
    }
    
    func damage(_ entity: GKEntity, amount: Int) {
        commandQueue.enqueue(.applyDamage(entity: entity, amount: amount))
    }
    
    func heal(_ entity: GKEntity, amount: Int) {
        guard let healthComp = entity.component(ofType: HealthComponent.self) else { return }
        healthComp.health = min(healthComp.maxHealth, healthComp.health + amount)
    }
    
    func adjustLives(delta: Int) {
        commandQueue.enqueue(.adjustLives(delta: delta))
    }
    
    func adjustBombs(delta: Int) {
        commandQueue.enqueue(.adjustBombs(delta: delta))
    }
    
    func adjustPower(delta: Int) {
        commandQueue.enqueue(.adjustPower(delta: delta))
    }
    
    func adjustScore(amount: Int) {
        commandQueue.enqueue(.adjustScore(amount: amount))
    }
    
    func activateBomb(playerEntity: GKEntity) {
        if let playerHealth = playerEntity.component(ofType: HealthComponent.self) {
            playerHealth.invulnerabilityTimer = 6.0
        }
        
        BulletUtility.convertBulletsToPoints(entityManager: entityManager)
        eventBus.fire(AttractItemsEvent(itemTypes: [.pointBullet]))
        
        let enemies = entityManager.getEntities(with: EnemyComponent.self)
        for enemy in enemies {
            damage(enemy, amount: 50)
        }
        
        eventBus.fire(BombActivatedEvent(playerEntity: playerEntity))
        adjustBombs(delta: -1)
    }
    
    func spawnEnemyBullet(_ command: BulletSpawnCommand) {
        commandQueue.enqueue(.spawnBullet(command, ownedByPlayer: false))
    }
    
    func fireItemCollectionEvent(itemType: ItemType, value: Int, position: CGPoint) {
        eventBus.fire(PowerUpCollectedEvent(itemType: itemType, value: value, position: position))
    }
}

