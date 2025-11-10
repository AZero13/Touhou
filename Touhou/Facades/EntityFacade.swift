//
//  EntityFacade.swift
//  Touhou
//
//  Created by Rose on 11/02/25.
//

import Foundation
import GameplayKit
import CoreGraphics

final class EntityFacade {
    private let entityManager: EntityManager
    private let commandQueue: CommandQueue
    private let eventBus: EventBus
    
    init(entityManager: EntityManager, commandQueue: CommandQueue, eventBus: EventBus) {
        self.entityManager = entityManager
        self.commandQueue = commandQueue
        self.eventBus = eventBus
    }
    
    @discardableResult
    func spawnBoss(
        name: String,
        health: Int,
        position: CGPoint,
        phaseNumber: Int = 1,
        attackPattern: EnemyPattern = .tripleShot,
        patternConfig: PatternConfig = PatternConfig(),
        shotInterval: TimeInterval = 1.2
    ) -> GKEntity {
        let entity = entityManager.createEntity()
        entity.addComponent(BossComponent(name: name, phaseNumber: phaseNumber))
        entity.addComponent(EnemyComponent(
            enemyType: .boss,
            scoreValue: 5000,
            dropItem: nil,
            attackPattern: attackPattern,
            patternConfig: patternConfig,
            shotInterval: shotInterval
        ))
        entity.addComponent(TransformComponent(position: position, velocity: .zero))
        entity.addComponent(HealthComponent(health: health, maxHealth: health))
        entity.addComponent(HitboxComponent(enemyHitbox: 16))
        GameFacade.shared.registerEntity(entity)
        return entity
    }
    
    @discardableResult
    func spawnFairy(
        position: CGPoint,
        attackPattern: EnemyPattern,
        patternConfig: PatternConfig,
        shotInterval: TimeInterval = 2.0,
        dropItem: ItemType? = .power
    ) -> GKEntity {
        let entity = entityManager.createEntity()
        entity.addComponent(EnemyComponent(
            enemyType: .fairy,
            scoreValue: 100,
            dropItem: dropItem,
            attackPattern: attackPattern,
            patternConfig: patternConfig,
            shotInterval: shotInterval
        ))
        entity.addComponent(TransformComponent(position: position, velocity: CGVector(dx: 0, dy: -50)))
        entity.addComponent(HitboxComponent(enemyHitbox: 12))
        entity.addComponent(HealthComponent(health: 1, maxHealth: 1))
        GameFacade.shared.registerEntity(entity)
        return entity
    }
    
    func spawnBullet(
        position: CGPoint,
        velocity: CGVector,
        bulletType: BulletComponent.BulletType = .enemyBullet,
        ownedByPlayer: Bool = false,
        physics: PhysicsConfig = PhysicsConfig(),
        visual: VisualConfig = VisualConfig(),
        behavior: BehaviorConfig = BehaviorConfig()
    ) {
        let cmd = BulletSpawnCommand(
            position: position,
            velocity: velocity,
            bulletType: bulletType,
            physics: physics,
            visual: visual,
            behavior: behavior
        )
        commandQueue.enqueue(.spawnBullet(cmd, ownedByPlayer: ownedByPlayer))
    }
    
    func spawnItem(type: ItemType, at position: CGPoint, velocity: CGVector = .zero) {
        commandQueue.enqueue(.spawnItem(type: type, position: position, velocity: velocity))
    }
    
    func destroy(_ entity: GKEntity) {
        commandQueue.enqueue(.destroyEntity(entity))
    }
    
    func destroyAllBullets(where filter: ((BulletComponent) -> Bool)? = nil) {
        CommandQueue.despawnAllBullets(entityManager: entityManager, selector: filter)
    }
    
    var player: GKEntity? {
        entityManager.getPlayerEntity()
    }
    
    func getEntities<T: GKComponent>(with componentType: T.Type) -> [GKEntity] {
        entityManager.getEntities(with: componentType)
    }
    
    func getAllEntities() -> [GKEntity] {
        entityManager.getAllEntities()
    }
}

