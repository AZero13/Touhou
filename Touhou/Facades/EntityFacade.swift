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
    
    /// Spawn a boss enemy with dialogue and portrait capabilities
    @discardableResult
    func spawnBoss(
        name: String,
        health: Int,
        position: CGPoint,
        phaseNumber: Int = 1,
        portraitId: String? = nil,
        portraitSide: PortraitSide = .right
    ) -> GKEntity {
        let entity = entityManager.createEntity()
        entity.addComponent(BossComponent(name: name, health: health, phaseNumber: phaseNumber))
        entity.addComponent(TransformComponent(position: position))
        entity.addComponent(HealthComponent(current: health, max: health))
        entity.addComponent(HitboxComponent(enemyHitbox: 16))
        entity.addComponent(SpriteComponent(textureName: "boss_\(name.lowercased())", zIndex: 100))
        
        // Add dialogue capability
        entity.addComponent(DialogueComponent(speaker: name))
        
        // Add portrait if provided
        if let portraitId = portraitId {
            entity.addComponent(PortraitComponent(portraitId: portraitId, side: portraitSide))
        }
        
        // Register with component systems after entity is fully set up
        GameFacade.shared.registerEntity(entity)
        
        return entity
    }
    
    // MARK: - Enemy Operations
    
    /// Spawn a regular enemy
    @discardableResult
    func spawnEnemy(
        type: String,
        position: CGPoint,
        health: Int,
        scoreValue: Int,
        pattern: String? = nil
    ) -> GKEntity {
        let entity = entityManager.createEntity()
        let enemyType: EnemyComponent.EnemyType = (type == "fairy") ? .fairy : .custom(type)
        entity.addComponent(EnemyComponent(enemyType: enemyType, scoreValue: scoreValue))
        entity.addComponent(TransformComponent(position: position))
        entity.addComponent(HealthComponent(current: health, max: health))
        entity.addComponent(HitboxComponent(enemyHitbox: 8))
        entity.addComponent(SpriteComponent(textureName: "enemy_\(type)", zIndex: 50))
        
        if let pattern = pattern {
            entity.addComponent(AIPatternComponent(currentPattern: pattern))
        }
        
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

