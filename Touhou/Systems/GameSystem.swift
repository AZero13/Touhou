//
//  GameSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// Protocol for all game systems.
/// Systems hold a reference to the engine from initialize() and access everything through it.
protocol GameSystem: EventListener {
    func initialize(engine: GameEngine)
    func update(deltaTime: TimeInterval)
    func handleEvent(_ event: GameEvent)
}
