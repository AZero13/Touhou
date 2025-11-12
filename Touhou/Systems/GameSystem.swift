//
//  GameSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// Runtime context passed to systems each update
/// Contains all shared game state and services systems need
struct GameRuntimeContext {
    let entityManager: EntityManager
    let eventBus: EventBus
    let entities: EntityFacade
    let combat: CombatFacade
    let isTimeFrozen: Bool
    let currentStage: Int
    let unregisterEntity: (GKEntity) -> Void
}

/// Protocol for all game systems
protocol GameSystem: EventListener {
    func initialize(context: GameRuntimeContext)
    func update(deltaTime: TimeInterval, context: GameRuntimeContext)
    func handleEvent(_ event: GameEvent, context: GameRuntimeContext)
    
    // Default implementation for EventListener compatibility
    func handleEvent(_ event: GameEvent)
}
