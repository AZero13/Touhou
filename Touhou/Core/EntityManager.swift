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
    
    func destroyMarkedEntities(gameFacade: GameFacade? = nil) {
        for entity in entitiesToDestroy {
            if let facade = gameFacade {
                facade.unregisterEntity(entity)
            } else {
                GameFacade.shared.unregisterEntity(entity)
            }
            removeAllComponents(from: entity)
            if let index = entities.firstIndex(of: entity) {
                entities.remove(at: index)
            }
        }
        entitiesToDestroy.removeAll()
    }
    
    private func removeAllComponents(from entity: GKEntity) {
        entity.removeComponent(ofType: RenderComponent.self)
        entity.removeComponent(ofType: PlayerComponent.self)
        entity.removeComponent(ofType: EnemyComponent.self)
        entity.removeComponent(ofType: BulletComponent.self)
        entity.removeComponent(ofType: ItemComponent.self)
        entity.removeComponent(ofType: TransformComponent.self)
        entity.removeComponent(ofType: HealthComponent.self)
        entity.removeComponent(ofType: HitboxComponent.self)
        entity.removeComponent(ofType: BossComponent.self)
        entity.removeComponent(ofType: BulletMotionModifiersComponent.self)
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
