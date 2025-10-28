//
//  CleanupSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// CleanupSystem - handles entity destruction (runs last)
class CleanupSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Destroy all marked entities
        entityManager.destroyMarkedEntities()
    }
    
    func handleEvent(_ event: GameEvent) {
        // No events to handle
    }
}
