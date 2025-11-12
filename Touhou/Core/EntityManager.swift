//
//  EntityManager.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

@MainActor
class EntityManager {
    private var entities: [GKEntity] = []
    private var entitiesToDestroy: [GKEntity] = []
    
    func createEntity() -> GKEntity {
        let entity = GKEntity()
        entities.append(entity)
        return entity
    }
    
    func markForDestruction(_ entity: GKEntity) {
        entitiesToDestroy.append(entity)
    }
    
    func destroyMarkedEntities(unregisterEntity: (GKEntity) -> Void) {
        for entity in entitiesToDestroy {
            unregisterEntity(entity)
            removeAllComponents(from: entity)
            if let index = entities.firstIndex(of: entity) {
                entities.remove(at: index)
            }
        }
        entitiesToDestroy.removeAll()
    }
    
    private func removeAllComponents(from entity: GKEntity) {
        // Remove all components by iterating over entity's component system
        // This is more maintainable than manually listing each component type
        let componentTypes: [GKComponent.Type] = [
            RenderComponent.self,
            PlayerComponent.self,
            EnemyComponent.self,
            BulletComponent.self,
            ItemComponent.self,
            TransformComponent.self,
            HealthComponent.self,
            HitboxComponent.self,
            BossComponent.self,
            BulletMotionModifiersComponent.self
        ]
        
        for componentType in componentTypes {
            entity.removeComponent(ofType: componentType)
        }
    }
    
    func getAllEntities() -> [GKEntity] {
        entities
    }
    
    func getEntities<T: GKComponent>(with componentType: T.Type) -> [GKEntity] {
        entities.filter { $0.component(ofType: componentType) != nil }
    }
    
    func getEntities(with componentTypes: [GKComponent.Type]) -> [GKEntity] {
        entities.filter { entity in
            componentTypes.allSatisfy { componentType in
                entity.component(ofType: componentType) != nil
            }
        }
    }
    
    func getPlayerEntity() -> GKEntity? {
        getEntities(with: PlayerComponent.self).first
    }
    
    func getPlayerComponent() -> PlayerComponent? {
        for entity in entities {
            if let playerComponent = entity.component(ofType: PlayerComponent.self) {
                return playerComponent
            }
        }
        return nil
    }
    
    func getAllComponents<T: GKComponent>(_ componentType: T.Type) -> [T] {
        entities.compactMap { $0.component(ofType: componentType) }
    }
}
