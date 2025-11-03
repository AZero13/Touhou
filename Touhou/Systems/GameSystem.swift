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
