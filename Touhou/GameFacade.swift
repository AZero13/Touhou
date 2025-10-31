//
//  GameFacade.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit
import CoreGraphics

/// GameFacade - Singleton coordinator that owns all systems and runs the game loop
/// Contains NO game logic - only coordination
class GameFacade {
    
    // MARK: - Singleton
    static let shared = GameFacade()
    
    // MARK: - Global Game Configuration
    static let playArea: CGRect = CGRect(x: 0, y: 0, width: 384, height: 448)
    static let maxStage: Int = 6
    
    private init() {
        setupStateMachine()
        setupSystems()
    }
    
    // MARK: - Core Systems
    private let entityManager = EntityManager()
    private let eventBus = EventBus()
    private let commandQueue = CommandQueue()
    private let taskScheduler = TaskScheduler()
    
    // MARK: - Game Systems
    private var systems: [GameSystem] = []
    
    // MARK: - Game State Machine
    private var stateMachine: GKStateMachine!
    
    // MARK: - Game State
    private var lastUpdateTime: TimeInterval = 0
    private var currentStage: Int = 1
    
    // MARK: - Setup
    private func setupStateMachine() {
        let notStartedState = GameNotStartedState(gameFacade: self)
        let playingState = GamePlayingState(gameFacade: self)
        let pausedState = GamePausedState(gameFacade: self)
        stateMachine = GKStateMachine(states: [notStartedState, playingState, pausedState])
        stateMachine.enter(GameNotStartedState.self)
    }
    
    private func setupSystems() {
        // Add systems in update order
        addSystem(PlayerSystem())
        addSystem(EnemySystem())
        addSystem(BulletHomingSystem()) // Apply homing steering before movement for immediate effect
        addSystem(BulletSystem())
        addSystem(CollisionSystem()) // Detect collisions
        addSystem(HealthSystem()) // Process damage/death
        addSystem(ItemSystem()) // Items: drops and collection
        addSystem(ScoreSystem()) // Update score/high score for UI
        addSystem(CleanupSystem()) // Must be last
    }
    
    /// Add a system to the game loop
    func addSystem(_ system: GameSystem) {
        system.initialize(entityManager: entityManager, eventBus: eventBus) // Initialize the system
        eventBus.register(listener: system)
        systems.append(system)
    }
    
    func update(_ currentTime: TimeInterval) {

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update input manager first
        InputManager.shared.update()
        
        // Update state machine (handles pause/unpause and menu navigation)
        stateMachine.update(deltaTime: deltaTime)
        
        // Only update game systems if we're in playing state
        if stateMachine.currentState is GamePlayingState {
            // Update all systems in order
            for system in systems {
                system.update(deltaTime: deltaTime)
            }
            
            // Run scheduled tasks (patterns, phases)
            taskScheduler.update(deltaTime: deltaTime, entityManager: entityManager, commandQueue: commandQueue)
            
            // Apply buffered world mutations
            commandQueue.process(entityManager: entityManager, eventBus: eventBus)
        }
        
        // Process events
        eventBus.processEvents()
    }
    
    // MARK: - Game Control
    func restartGame() {
        // Clear all entities (player will be respawned by PlayerSystem)
        let allEntities = entityManager.getAllEntities()
        for entity in allEntities {
            entityManager.markForDestruction(entity)
        }

        // Clean up immediately (processEvents happens once per frame in update loop)
        entityManager.destroyMarkedEntities()
        
        lastUpdateTime = CACurrentMediaTime()
        
        // PlayerSystem will respawn player on next update
        print("Game restarted")
    }
    
    // MARK: - Stage Lifecycle
    func startNewRun() {
        currentStage = 1
        startStage(stageId: currentStage)
    }
    
    func startStage(stageId: Int) {
        // Reset world state for a clean start
        clearTransientWorld()
        commandQueue.clear()
        taskScheduler.reset()
        currentStage = stageId
        eventBus.fire(StageStartedEvent(stageId: stageId))
        lastUpdateTime = CACurrentMediaTime()
        stateMachine.enter(GamePlayingState.self)
        print("Stage \(stageId) started")
    }
    
    func endStage() {
        // Stop gameplay updates and clear transient entities so nothing lingers
        stateMachine.enter(GameNotStartedState.self)
        eventBus.fire(StageEndedEvent(stageId: currentStage))
        clearTransientWorld()
        commandQueue.clear()
        taskScheduler.reset()
        print("Stage \(currentStage) ended")
    }
    
    private func clearTransientWorld() {
        // Remove bullets, enemies, items, and spawners; keep persistent/player
        let entities = entityManager.getAllEntities()
        for entity in entities {
            let hasBullet = entity.component(ofType: BulletComponent.self) != nil
            let hasEnemy = entity.component(ofType: EnemyComponent.self) != nil
            let hasItem = entity.component(ofType: ItemComponent.self) != nil
            let hasSpawner = entity.component(ofType: BulletSpawnerComponent.self) != nil
            if hasBullet || hasEnemy || hasItem || hasSpawner {
                entityManager.markForDestruction(entity)
            }
        }
        entityManager.destroyMarkedEntities()
    }
    
    // MARK: - System Access
    func getEntityManager() -> EntityManager {
        return entityManager
    }
    
    func getEventBus() -> EventBus {
        return eventBus
    }
    
    func getCommandQueue() -> CommandQueue {
        return commandQueue
    }
    
    func getTaskScheduler() -> TaskScheduler {
        return taskScheduler
    }
    
    func registerListener(_ listener: EventListener) {
        eventBus.register(listener: listener)
    }
    
    func getCurrentStage() -> Int { currentStage }
    
    func advanceStage() {
        if currentStage >= GameFacade.maxStage {
            return
        }
        currentStage += 1
    }
}
