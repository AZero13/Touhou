//
//  CommandQueue.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import CoreGraphics
import GameplayKit

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
    
    func process(entityManager: EntityManaging, eventBus: EventDispatching, isTimeFrozen: Bool, registerEntity: (GKEntity) -> Void) {
        if queue.isEmpty { return }
        for command in queue {
            switch command {
            case let .spawnBullet(cmd, ownedByPlayer) where isTimeFrozen:
                let entity = spawnBullet(cmd, ownedByPlayer: ownedByPlayer, entityManager: entityManager, registerEntity: registerEntity)
                applyFreezeModifier(to: entity)
            case let .spawnBullet(cmd, ownedByPlayer):
                spawnBullet(cmd, ownedByPlayer: ownedByPlayer, entityManager: entityManager, registerEntity: registerEntity)
            case let .destroyEntity(entity):
                entityManager.markForDestruction(entity)
            case let .spawnItem(type, position, velocity):
                spawnItem(type: type, position: position, velocity: velocity, entityManager: entityManager, registerEntity: registerEntity)
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
    
    static func despawnAllBullets(entityManager: EntityManaging, destroyEntity: (GKEntity) -> Void, selector: ((BulletComponent) -> Bool)? = nil) {
        let bullets = entityManager.getEntities(with: BulletComponent.self)
        for bulletEntity in bullets {
            guard let bulletComp = bulletEntity.component(ofType: BulletComponent.self) else { continue }
            if selector == nil || selector!(bulletComp) {
                destroyEntity(bulletEntity)
            }
        }
    }
    
    @discardableResult
    private func spawnBullet(_ cmd: BulletSpawnCommand, ownedByPlayer: Bool, entityManager: EntityManaging, registerEntity: (GKEntity) -> Void) -> GKEntity {
        createBulletEntity(from: cmd, ownedByPlayer: ownedByPlayer, entityManager: entityManager, registerEntity: registerEntity)
    }
    
    private func applyFreezeModifier(to entity: GKEntity) {
        if let mods = entity.component(ofType: BulletMotionModifiersComponent.self) {
            mods.timeScale = 0.0
        } else {
            let mods = BulletMotionModifiersComponent()
            mods.timeScale = 0.0
            entity.addComponent(mods)
        }
    }

    private func spawnItem(type: ItemType, position: CGPoint, velocity: CGVector, entityManager: EntityManaging, registerEntity: (GKEntity) -> Void) {
        let entity = entityManager.createEntity()
        entity.addComponent(ItemComponent(itemType: type, value: 0))
        entity.addComponent(TransformComponent(position: position, velocity: velocity))
        registerEntity(entity)
    }

    private func applyDamage(entity: GKEntity, amount: Int, entityManager: EntityManaging, eventBus: EventDispatching) {
        guard let health = entity.component(ofType: HealthComponent.self) else { return }
        
        // For all bosses (single or multi-phase), sync health with BossComponent's currentPhaseHealth
        if let bossComponent = entity.component(ofType: BossComponent.self) {
            // Update bossComponent's current phase health
            bossComponent.currentPhaseHealth = max(0, bossComponent.currentPhaseHealth - amount)
            // Sync HealthComponent with current phase health
            health.health = bossComponent.currentPhaseHealth
        } else {
            // Regular damage for non-boss entities
            health.health -= amount
        }
        
        if !health.isAlive {
            if let enemy = entity.component(ofType: EnemyComponent.self) {
                eventBus.fire(EnemyDiedEvent(entity: entity, scoreValue: enemy.scoreValue, dropItem: enemy.dropItem))
                
                // Check if this is a multi-phase boss - if so, HealthSystem will handle phase transition
                // Only mark for destruction if it's not a multi-phase boss or if all phases are defeated
                let bossComponent = entity.component(ofType: BossComponent.self)
                let isMultiPhase = bossComponent?.totalPhases ?? 1 > 1
                let isMidboss = bossComponent?.phaseNumber == 0
                
                if !isMidboss && !isMultiPhase {
                    // Single-phase stage bosses vanish immediately
                    entityManager.markForDestruction(entity)
                }
                // Multi-phase bosses and midbosses are handled in HealthSystem
            }
        }
    }
    
    private func adjustLives(delta: Int, entityManager: EntityManaging, eventBus: EventDispatching) {
        guard let playerEntity = entityManager.getPlayerEntity(),
              let player = playerEntity.component(ofType: PlayerComponent.self) else { return }
        player.lives += delta
        eventBus.fire(LivesChangedEvent(newTotal: player.lives))
        if player.lives <= 0 {
            eventBus.fire(GameOverEvent(finalScore: player.score))
        } else if delta < 0 {
            playerEntity.component(ofType: HealthComponent.self)?.invulnerabilityTimer = 6.0
            if player.power <= 16 {
                player.power = 0
            } else {
                player.power -= 16
            }
            player.powerItemCountForScore = 0
            player.bombs = 3
            eventBus.fire(PowerLevelChangedEvent(newTotal: player.power))

            eventBus.fire(BombsChangedEvent(newTotal: player.bombs))
            eventBus.fire(PlayerRespawnedEvent(entity: playerEntity))
        }
    }
    
    private func adjustBombs(delta: Int, entityManager: EntityManaging, eventBus: EventDispatching) {
        guard let player = entityManager.getPlayerComponent() else { return }
        player.bombs += delta
        eventBus.fire(BombsChangedEvent(newTotal: player.bombs))
    }
    
    private func adjustPower(delta: Int, entityManager: EntityManaging, eventBus: EventDispatching) {
        guard let player = entityManager.getPlayerComponent() else { return }
        player.power += delta
        if delta > 0 {
            player.powerItemCountForScore = 0
        }
        eventBus.fire(PowerLevelChangedEvent(newTotal: player.power))
    }
    
    private func adjustScore(amount: Int, entityManager: EntityManaging, eventBus: EventDispatching) {
        guard let player = entityManager.getPlayerComponent() else { return }
        player.score += amount
        eventBus.fire(ScoreChangedEvent(newTotal: player.score))
    }
    
    private func createBulletEntity(from command: BulletSpawnCommand, ownedByPlayer: Bool, entityManager: EntityManaging, registerEntity: (GKEntity) -> Void) -> GKEntity {
        let entity = entityManager.createEntity()
        
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
        
        if ownedByPlayer && command.bulletType == .homingAmulet {
            bullet.retargetInterval = command.behavior.retargetInterval ?? 0.066
        } else {
            bullet.retargetInterval = command.behavior.retargetInterval
        }
        bullet.maxRetargets = command.behavior.maxRetargets
        bullet.rotationOffset = command.behavior.rotationOffset
        bullet.groupId = command.groupId
        bullet.patternId = command.patternId
        bullet.tags = command.tags
        
        entity.addComponent(bullet)
        entity.addComponent(TransformComponent(position: command.position, velocity: command.velocity))
        registerEntity(entity)
        
        return entity
    }
}


