//
//  CleanupSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// CleanupSystem - handles entity destruction (runs last)
/// IMPORTANT: This system must run after all other systems to ensure entities marked
/// for destruction during the frame are properly cleaned up at the end.
final class CleanupSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(context: GameRuntimeContext) {
        self.entityManager = context.entityManager
        self.eventBus = context.eventBus
    }
    
    func update(deltaTime: TimeInterval, context: GameRuntimeContext) {
        // Destroy all marked entities
        entityManager.destroyMarkedEntities(unregisterEntity: context.unregisterEntity)
    }
    
    func handleEvent(_ event: GameEvent, context: GameRuntimeContext) {
        // No events to handle
    }
    
    func handleEvent(_ event: GameEvent) {
        // Fallback for non-GameSystem listeners (shouldn't be called)
        fatalError("CleanupSystem.handleEvent without context should not be called")
    }
}
