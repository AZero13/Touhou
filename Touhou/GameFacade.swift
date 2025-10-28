//
//  GameFacade.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// GameFacade - Singleton coordinator that owns all systems and runs the game loop
/// Contains NO game logic - only coordination
class GameFacade {
    
    // MARK: - Singleton
    static let shared = GameFacade()
    
    private init() {
        setupSystems()
    }
    
    // MARK: - Core Systems
    private let entityManager = EntityManager()
    private let eventBus = EventBus()
    
    // MARK: - Game Systems
    private var systems: [GameSystem] = []
    
    // MARK: - Game State
    private var isRunning = false
    private var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Setup
    private func setupSystems() {
        // Add systems in update order
        addSystem(PlayerSystem())
        addSystem(BulletSystem())
        addSystem(BulletHomingSystem()) // Handle homing after movement
        addSystem(CleanupSystem()) // Must be last
    }
    
    /// Add a system to the game loop
    func addSystem(_ system: GameSystem) {
        system.initialize(entityManager: entityManager, eventBus: eventBus) // Initialize the system
        eventBus.register(listener: system)
        systems.append(system)
    }
    
    // MARK: - Game Loop
    func startGame() {
        isRunning = true
        lastUpdateTime = CACurrentMediaTime()
    }
    
    func stopGame() {
        isRunning = false
    }
    
    func update(_ currentTime: TimeInterval) {
        guard isRunning else { return }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update all systems in order
        for system in systems {
            system.update(deltaTime: deltaTime)
        }
        
        // Process events
        eventBus.processEvents()
    }
    
    // MARK: - System Access
    func getEntityManager() -> EntityManager {
        return entityManager
    }
    
    func getEventBus() -> EventBus {
        return eventBus
    }
}
