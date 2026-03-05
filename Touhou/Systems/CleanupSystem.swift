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
    private weak var engine: GameEngine!
    
    func initialize(engine: GameEngine) {
        self.engine = engine
    }
    
    func update(deltaTime: TimeInterval) {
        // Destroy all marked entities
        engine.entityManager.destroyMarkedEntities(unregisterEntity: engine.unregisterEntity)
    }
    
    func handleEvent(_ event: GameEvent) {
        // No events to handle
    }
}
