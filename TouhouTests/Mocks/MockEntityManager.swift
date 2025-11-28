//
//  MockEntityManager.swift
//  TouhouTests
//
//  Created by Antigravity on 11/27/25.
//

import Foundation
import GameplayKit
@testable import Touhou

/// Mock implementation of EntityManaging for testing
@MainActor
final class MockEntityManager: EntityManaging {
    private(set) var entities: [GKEntity] = []
    private(set) var markedForDestruction: Set<ObjectIdentifier> = []
    
    // Tracking for verification
    private(set) var createEntityCallCount = 0
    private(set) var markForDestructionCallCount = 0
    private(set) var destroyMarkedEntitiesCallCount = 0
    
    func createEntity() -> GKEntity {
        createEntityCallCount += 1
        let entity = GKEntity()
        entities.append(entity)
        return entity
    }
    
    func markForDestruction(_ entity: GKEntity) {
        markForDestructionCallCount += 1
        markedForDestruction.insert(ObjectIdentifier(entity))
    }
    
    func isMarkedForDestruction(_ entity: GKEntity) -> Bool {
        markedForDestruction.contains(ObjectIdentifier(entity))
    }
    
    func destroyMarkedEntities(unregisterEntity: (GKEntity) -> Void) {
        destroyMarkedEntitiesCallCount += 1
        let toDestroy = entities.filter { markedForDestruction.contains(ObjectIdentifier($0)) }
        for entity in toDestroy {
            unregisterEntity(entity)
            if let index = entities.firstIndex(of: entity) {
                entities.remove(at: index)
            }
        }
        markedForDestruction.removeAll()
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
        getPlayerEntity()?.component(ofType: PlayerComponent.self)
    }
    
    func getAllComponents<T: GKComponent>(_ componentType: T.Type) -> [T] {
        entities.compactMap { $0.component(ofType: componentType) }
    }
    
    // Helper methods for testing
    func addEntity(_ entity: GKEntity) {
        entities.append(entity)
    }
    
    func reset() {
        entities.removeAll()
        markedForDestruction.removeAll()
        createEntityCallCount = 0
        markForDestructionCallCount = 0
        destroyMarkedEntitiesCallCount = 0
    }
}
