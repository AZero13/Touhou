//
//  CommandQueue.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// A small, typed command queue to buffer world mutations between system updates
final class CommandQueue {
    enum Command {
        case spawnBullet(BulletSpawnCommand, ownedByPlayer: Bool)
        case destroyEntity(GKEntity)
        case spawnItem(type: ItemType, position: CGPoint, velocity: CGVector)
        case applyDamage(entity: GKEntity, amount: Int)
        case adjustLives(delta: Int)
        case adjustBombs(delta: Int)
        case adjustPower(delta: Int)
        case adjustScore(amount: Int)
    }
    
    private var queue: [Command] = []
    
    func enqueue(_ command: Command) {
        queue.append(command)
    }
    
    func clear() {
        queue.removeAll()
    }
    
    /// Apply all queued commands immediately
    func process(entityManager: EntityManager, eventBus: EventBus) {
        guard !queue.isEmpty else { return }
        for command in queue {
            switch command {
            case let .spawnBullet(cmd, ownedByPlayer):
                spawnBullet(cmd, ownedByPlayer: ownedByPlayer, entityManager: entityManager)
            case let .destroyEntity(entity):
                entityManager.markForDestruction(entity)
            case let .spawnItem(type, position, velocity):
                spawnItem(type: type, position: position, velocity: velocity, entityManager: entityManager)
            case let .applyDamage(entity, amount):
                applyDamage(entity: entity, amount: amount, entityManager: entityManager, eventBus: eventBus)
            case let .adjustLives(delta):
                adjustLives(delta: delta, entityManager: entityManager, eventBus: eventBus)
            case let .adjustBombs(delta):
                adjustBombs(delta: delta, entityManager: entityManager, eventBus: eventBus)
            case let .adjustPower(delta):
                adjustPower(delta: delta, entityManager: entityManager, eventBus: eventBus)
            case let .adjustScore(amount):
                adjustScore(amount: amount, entityManager: entityManager, eventBus: eventBus)
            }
        }
        queue.removeAll()
    }
    
    // MARK: - Helpers
    private func spawnBullet(_ cmd: BulletSpawnCommand, ownedByPlayer: Bool, entityManager: EntityManager) {
        let entity = BulletFactory.createEntity(from: cmd, ownedByPlayer: ownedByPlayer, entityManager: entityManager)
        
        // If time is frozen, immediately apply freeze modifier to newly spawned bullet
        if GameFacade.shared.isFrozen() {
            let mods = entity.component(ofType: BulletMotionModifiersComponent.self)
                ?? BulletMotionModifiersComponent()
            if entity.component(ofType: BulletMotionModifiersComponent.self) == nil {
                entity.addComponent(mods)
            }
            mods.timeScale = 0.0
        }
    }

    private func spawnItem(type: ItemType, position: CGPoint, velocity: CGVector, entityManager: EntityManager) {
        _ = ItemFactory.createEntity(type: type, position: position, velocity: velocity, entityManager: entityManager)
    }

    private func applyDamage(entity: GKEntity, amount: Int, entityManager: EntityManager, eventBus: EventBus) {
        guard let health = entity.component(ofType: HealthComponent.self) else { return }
        health.health -= amount
        if !health.isAlive {
            if let enemy = entity.component(ofType: EnemyComponent.self) {
                eventBus.fire(EnemyDiedEvent(entity: entity, scoreValue: enemy.scoreValue, dropItem: enemy.dropItem))
                entityManager.markForDestruction(entity)
            }
        }
    }
    
    private func adjustLives(delta: Int, entityManager: EntityManager, eventBus: EventBus) {
        guard let playerEntity = entityManager.getEntities(with: PlayerComponent.self).first,
              let player = playerEntity.component(ofType: PlayerComponent.self) else { return }
        player.lives += delta
        eventBus.fire(LivesChangedEvent(newTotal: player.lives))
        if player.lives <= 0 {
            eventBus.fire(GameOverEvent(finalScore: player.score))
        } else if delta < 0 {
            // respawn on life loss
            if let transform = playerEntity.component(ofType: TransformComponent.self) {
                transform.position = CGPoint(x: 192, y: 50)
            }
            eventBus.fire(PlayerRespawnedEvent(entity: playerEntity))
        }
    }
    
    private func adjustBombs(delta: Int, entityManager: EntityManager, eventBus: EventBus) {
        guard let player = entityManager.getEntities(with: PlayerComponent.self).first?.component(ofType: PlayerComponent.self) else { return }
        player.bombs = max(0, min(player.bombs + delta, 8))
        eventBus.fire(BombsChangedEvent(newTotal: player.bombs))
    }
    
    private func adjustPower(delta: Int, entityManager: EntityManager, eventBus: EventBus) {
        guard let player = entityManager.getEntities(with: PlayerComponent.self).first?.component(ofType: PlayerComponent.self) else { return }
        player.power = max(0, min(player.power + delta, 128))
        eventBus.fire(PowerLevelChangedEvent(newTotal: player.power))
    }
    
    private func adjustScore(amount: Int, entityManager: EntityManager, eventBus: EventBus) {
        guard let player = entityManager.getEntities(with: PlayerComponent.self).first?.component(ofType: PlayerComponent.self) else { return }
        player.score += amount
        eventBus.fire(ScoreChangedEvent(newTotal: player.score))
    }
}


