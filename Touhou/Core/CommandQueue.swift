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
@MainActor
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
    
    /// Despawn all bullets, optionally filtered by selector
    static func despawnAllBullets(entityManager: EntityManager, selector: ((BulletComponent) -> Bool)? = nil) {
        let bullets = entityManager.getEntities(with: BulletComponent.self)
        for bullet in bullets {
            guard let bulletComp = bullet.component(ofType: BulletComponent.self) else { continue }
            if let selector = selector {
                if !selector(bulletComp) { continue }
            }
            GameFacade.shared.entities.destroy(bullet)
        }
    }
    
    private func spawnBullet(_ cmd: BulletSpawnCommand, ownedByPlayer: Bool, entityManager: EntityManager) {
        let entity = createBulletEntity(from: cmd, ownedByPlayer: ownedByPlayer, entityManager: entityManager)
        
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
        let entity = entityManager.createEntity()
        entity.addComponent(ItemComponent(itemType: type, value: 0))
        entity.addComponent(TransformComponent(position: position, velocity: velocity))
        
        // Register with component systems
        GameFacade.shared.registerEntity(entity)
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
            // TH06: Player takes damage - set invulnerability timer
            // TH06 uses 360 frames of invulnerability after taking damage (6 seconds at 60fps)
            if let playerHealth = playerEntity.component(ofType: HealthComponent.self) {
                playerHealth.invulnerabilityTimer = 6.0
            }
            
            // TH06: Power loss on death
            // If power <= 16: drop to 0, else drop by 16
            if player.power <= 16 {
                player.power = 0
            } else {
                player.power -= 16
            }
            eventBus.fire(PowerLevelChangedEvent(newTotal: player.power))
            
            // Reset power item count for score (TH06 behavior)
            player.powerItemCountForScore = 0
            
            // respawn on life loss - reset bombs to 3
            player.bombs = 3
            eventBus.fire(BombsChangedEvent(newTotal: player.bombs))
            // Fire respawn event - PlayerLifecycleSystem will handle position reset
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
        let oldPower = player.power
        player.power = max(0, min(player.power + delta, 128))
        
        // TH06: Reset powerItemCountForScore when power increases (crossing thresholds)
        if delta > 0 && oldPower < 128 && player.power >= 128 {
            // Reaching full power - reset counter
            player.powerItemCountForScore = 0
        } else if delta > 0 {
            // Power increased but not at full power - reset counter (TH06 behavior)
            player.powerItemCountForScore = 0
        }
        
        eventBus.fire(PowerLevelChangedEvent(newTotal: player.power))
    }
    
    private func adjustScore(amount: Int, entityManager: EntityManager, eventBus: EventBus) {
        guard let player = entityManager.getEntities(with: PlayerComponent.self).first?.component(ofType: PlayerComponent.self) else { return }
        player.score += amount
        eventBus.fire(ScoreChangedEvent(newTotal: player.score))
    }
    
    // MARK: - Entity Creation Helpers (moved from factories)
    
    private func createBulletEntity(from command: BulletSpawnCommand, ownedByPlayer: Bool, entityManager: EntityManager) -> GKEntity {
        let entity = entityManager.createEntity()
        
        // Apply TH06-style defaults for player homing amulets
        let isPlayerHomingAmulet = ownedByPlayer && command.bulletType == .homingAmulet
        let defaultRetargetInterval: TimeInterval? = isPlayerHomingAmulet ? 0.066 : nil
        let defaultMaxRetargets: Int? = isPlayerHomingAmulet ? nil : nil
        
        let bullet = BulletComponent(
            ownedByPlayer: ownedByPlayer,
            bulletType: command.bulletType,
            damage: command.physics.damage,
            size: command.visual.size,
            shape: command.visual.shape,
            color: command.visual.color,
            hasTrail: command.visual.hasTrail,
            trailLength: command.visual.trailLength
        )
        bullet.homingStrength = command.behavior.homingStrength
        bullet.maxTurnRate = command.behavior.maxTurnRate
        bullet.retargetInterval = command.behavior.retargetInterval ?? defaultRetargetInterval
        bullet.maxRetargets = command.behavior.maxRetargets ?? defaultMaxRetargets
        bullet.rotationOffset = (command.behavior.rotationOffset != 0 ? command.behavior.rotationOffset : 0)
        bullet.groupId = command.groupId
        bullet.patternId = command.patternId
        bullet.tags = command.tags
        
        entity.addComponent(bullet)
        entity.addComponent(TransformComponent(position: command.position, velocity: command.velocity))
        
        // Register with component systems
        GameFacade.shared.registerEntity(entity)
        
        return entity
    }
}


