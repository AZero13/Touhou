//
//  GameSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// Protocol for all game systems
protocol GameSystem: EventListener {
    func initialize(entityManager: EntityManager, eventBus: EventBus)
    func update(deltaTime: TimeInterval)
    func handleEvent(_ event: GameEvent)
}

/// EntityManager wrapper around GameplayKit's GKEntity management
class EntityManager {
    private var entities: [GKEntity] = []
    private var entitiesToDestroy: [GKEntity] = []
    
    /// Create a new entity
    func createEntity() -> GKEntity {
        let entity = GKEntity()
        entities.append(entity)
        return entity
    }
    
    /// Mark an entity for destruction
    func markForDestruction(_ entity: GKEntity) {
        entitiesToDestroy.append(entity)
    }
    
    /// Actually destroy marked entities
    func destroyMarkedEntities(gameFacade: GameFacade? = nil) {
        for entity in entitiesToDestroy {
            // Unregister from systems first (removes system-managed components from systems)
            if let facade = gameFacade {
                facade.unregisterEntity(entity)
            } else {
                GameFacade.shared.unregisterEntity(entity)
            }
            
            // Remove all components from entity to trigger willRemoveFromEntity() cleanup
            // Note: removeComponent is safe to call even if component doesn't exist (no-op)
            removeAllComponents(from: entity)
            
            // Remove entity from tracking
            if let index = entities.firstIndex(of: entity) {
                entities.remove(at: index)
            }
        }
        entitiesToDestroy.removeAll()
    }
    
    /// Remove all known components from an entity
    private func removeAllComponents(from entity: GKEntity) {
        // RenderComponent must be removed to clean up SKNode
        entity.removeComponent(ofType: RenderComponent.self)
        
        // System-managed components (already removed from systems by unregisterEntity)
        entity.removeComponent(ofType: PlayerComponent.self)
        entity.removeComponent(ofType: EnemyComponent.self)
        entity.removeComponent(ofType: BulletComponent.self)
        entity.removeComponent(ofType: ItemComponent.self)
        
        // Data-only components
        entity.removeComponent(ofType: TransformComponent.self)
        entity.removeComponent(ofType: HealthComponent.self)
        entity.removeComponent(ofType: HitboxComponent.self)
        entity.removeComponent(ofType: BossComponent.self)
        entity.removeComponent(ofType: BulletMotionModifiersComponent.self)
    }
    
    /// Get all entities
    func getAllEntities() -> [GKEntity] {
        return entities
    }
    
    /// Get entities with specific components
    func getEntities<T: GKComponent>(with componentType: T.Type) -> [GKEntity] {
        return entities.filter { $0.component(ofType: componentType) != nil }
    }
    
    /// Get entities with multiple component types
    func getEntities(with componentTypes: [GKComponent.Type]) -> [GKEntity] {
        return entities.filter { entity in
            componentTypes.allSatisfy { componentType in
                entity.component(ofType: componentType) != nil
            }
        }
    }
}
