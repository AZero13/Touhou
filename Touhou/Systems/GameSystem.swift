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
    func destroyMarkedEntities() {
        for entity in entitiesToDestroy {
            // Debug: Check if we're destroying a player entity
            if entity.component(ofType: PlayerComponent.self) != nil {
                print("WARNING: Player entity is being destroyed!")
            }
            if let index = entities.firstIndex(of: entity) {
                entities.remove(at: index)
            }
        }
        entitiesToDestroy.removeAll()
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
