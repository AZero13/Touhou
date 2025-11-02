//
//  EntityFacade.swift
//  Touhou
//
//  Created by Assistant on 11/02/25.
//

import Foundation
import GameplayKit
import CoreGraphics

/// EntityFacade - Simplified API for entity creation and manipulation
/// Hides complexity of EntityManager, components, and coordinate systems
final class EntityFacade {
    private let entityManager: EntityManager
    private let commandQueue: CommandQueue
    private let eventBus: EventBus
    
    init(entityManager: EntityManager, commandQueue: CommandQueue, eventBus: EventBus) {
        self.entityManager = entityManager
        self.commandQueue = commandQueue
        self.eventBus = eventBus
    }
    
    // MARK: - Boss Operations
    
    /// Spawn a boss enemy
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
            enemyType: .custom("boss_\(name)"),
            scoreValue: 5000,
            dropItem: .life,
            attackPattern: attackPattern,
            patternConfig: patternConfig,
            shotInterval: shotInterval
        ))
        entity.addComponent(TransformComponent(position: position, velocity: .zero))
        entity.addComponent(HealthComponent(current: health, max: health))
        entity.addComponent(HitboxComponent(enemyHitbox: 16))
        
        // Register with component systems after entity is fully set up
        GameFacade.shared.registerEntity(entity)
        
        return entity
    }
    
    // MARK: - Enemy Operations
    
    /// Spawn a fairy enemy
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
        entity.addComponent(HealthComponent(current: 1, max: 1))
        
        // Register with component systems after entity is fully set up
        GameFacade.shared.registerEntity(entity)
        
        return entity
    }
    
    // MARK: - Bullet Operations
    
    /// Spawn a bullet (uses command queue for deferred execution)
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
    
    // MARK: - Item Operations
    
    /// Spawn an item
    func spawnItem(type: ItemType, at position: CGPoint, velocity: CGVector = .zero) {
        commandQueue.enqueue(.spawnItem(type: type, position: position, velocity: velocity))
    }
    
    // MARK: - Entity Destruction
    
    /// Destroy an entity
    func destroy(_ entity: GKEntity) {
        commandQueue.enqueue(.destroyEntity(entity))
    }
    
    /// Destroy all bullets (optionally filtered)
    func destroyAllBullets(where filter: ((BulletComponent) -> Bool)? = nil) {
        CommandQueue.despawnAllBullets(entityManager: entityManager, selector: filter)
    }
    
    // MARK: - Entity Queries
    
    /// Find the player entity
    func getPlayer() -> GKEntity? {
        return entityManager.getEntities(with: PlayerComponent.self).first
    }
    
    /// Get all entities of a specific type
    func getEntities<T: GKComponent>(with componentType: T.Type) -> [GKEntity] {
        return entityManager.getEntities(with: componentType)
    }
}

