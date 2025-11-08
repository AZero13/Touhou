//
//  EntityManager.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// EntityManager wrapper around GameplayKit's GKEntity management
@MainActor
class EntityManager {
    private var entities: [GKEntity] = []
    private var entitiesToDestroy: [GKEntity] = []
    
    /// Creates a new game entity.
    ///
    /// - Returns: A new `GKEntity` ready for component attachment.
    func createEntity() -> GKEntity {
        let entity = GKEntity()
        entities.append(entity)
        return entity
    }
    
    /// Marks an entity for destruction at the end of the frame.
    ///
    /// - Parameter entity: The entity to mark for destruction.
    func markForDestruction(_ entity: GKEntity) {
        entitiesToDestroy.append(entity)
    }
    
    /// Destroys all entities marked for destruction.
    ///
    /// Unregisters entities from systems, removes all components, and removes them
    /// from tracking. This should be called once per frame after all systems have
    /// finished processing.
    ///
    /// - Parameter gameFacade: Optional game facade for unregistering entities.
    ///   If `nil`, uses `GameFacade.shared`.
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
    
    /// Gets all entities in the manager.
    ///
    /// - Returns: An array of all entities currently tracked.
    func getAllEntities() -> [GKEntity] {
        return entities
    }
    
    /// Gets entities that have the specified component type.
    ///
    /// - Parameter componentType: The component type to filter by.
    /// - Returns: An array of entities that have the specified component.
    func getEntities<T: GKComponent>(with componentType: T.Type) -> [GKEntity] {
        return entities.filter { $0.component(ofType: componentType) != nil }
    }
    
    /// Gets entities that have all of the specified component types.
    ///
    /// - Parameter componentTypes: An array of component types that entities must have.
    /// - Returns: An array of entities that have all specified components.
    func getEntities(with componentTypes: [GKComponent.Type]) -> [GKEntity] {
        return entities.filter { entity in
            componentTypes.allSatisfy { componentType in
                entity.component(ofType: componentType) != nil
            }
        }
    }
    
    // MARK: - Convenience Helpers
    
    /// Gets the player entity.
    ///
    /// - Returns: The player entity, or `nil` if no player exists.
    func getPlayerEntity() -> GKEntity? {
        return getEntities(with: PlayerComponent.self).first
    }
    
    /// Gets the player component directly.
    ///
    /// This is an optimized lookup that avoids redundant component queries by
    /// directly searching for the `PlayerComponent` in a single pass.
    ///
    /// - Returns: The player component, or `nil` if no player exists.
    func getPlayerComponent() -> PlayerComponent? {
        // Direct search to avoid redundant lookup:
        // getEntities() already calls component(ofType:) to filter, so we'd be calling it twice
        // This directly finds and returns the component in one pass
        for entity in entities {
            if let playerComponent = entity.component(ofType: PlayerComponent.self) {
                return playerComponent
            }
        }
        return nil
    }
    
    /// Gets all components of the specified type from all entities.
    ///
    /// This is more efficient than calling `getEntities(with:)` and then extracting
    /// components, as it does both operations in a single pass.
    ///
    /// - Parameter componentType: The component type to search for.
    /// - Returns: An array of all components of the specified type.
    func getAllComponents<T: GKComponent>(_ componentType: T.Type) -> [T] {
        return entities.compactMap { $0.component(ofType: componentType) }
    }
}
