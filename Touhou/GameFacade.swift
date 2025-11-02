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
    
    // MARK: - Core Systems (private - hidden from external access)
    private let entityManager = EntityManager()
    private let eventBus = EventBus()
    private let commandQueue = CommandQueue()
    
    // MARK: - Facades (public - simplified APIs)
    private(set) lazy var entities: EntityFacade = {
        EntityFacade(entityManager: entityManager, commandQueue: commandQueue, eventBus: eventBus)
    }()
    
    private(set) lazy var combat: CombatFacade = {
        CombatFacade(entityManager: entityManager, commandQueue: commandQueue, eventBus: eventBus)
    }()
    
    // MARK: - GameplayKit Component Systems (proper ECS)
    private var componentSystems: [GKComponentSystem] = []
    
    // MARK: - Cross-Cutting Systems (handle multi-entity concerns)
    private var crossCuttingSystems: [GameSystem] = []
    
    // MARK: - Game State Machine
    private var stateMachine: GKStateMachine!
    
    // MARK: - Game State
    private var lastUpdateTime: TimeInterval = 0
    private var currentStage: Int = 1
    private var isTimeFrozen: Bool = false
    
    // MARK: - Setup
    private func setupStateMachine() {
        let notStartedState = GameNotStartedState(gameFacade: self)
        let playingState = GamePlayingState(gameFacade: self)
        let pausedState = GamePausedState(gameFacade: self)
        stateMachine = GKStateMachine(states: [notStartedState, playingState, pausedState])
        stateMachine.enter(GameNotStartedState.self)
    }
    
    private func setupSystems() {
        // GameplayKit Component Systems (order matters for update sequence)
        componentSystems = [
            GKComponentSystem(componentClass: PlayerComponent.self),
            GKComponentSystem(componentClass: EnemyComponent.self),
            GKComponentSystem(componentClass: BulletComponent.self),  // Bullets update after homing
            GKComponentSystem(componentClass: ItemComponent.self)
        ]
        
        // Cross-cutting systems (handle interactions between entities)
        addCrossCuttingSystem(PlayerLifecycleSystem()) // Player spawning/lifecycle only
        addCrossCuttingSystem(EnemySystem())           // Enemy spawning/AI (movement now in component)
        addCrossCuttingSystem(BulletHomingSystem())    // Homing before bullet movement
        addCrossCuttingSystem(CollisionSystem())       // Detect collisions
        addCrossCuttingSystem(HealthSystem())          // Process damage/death
        addCrossCuttingSystem(ScoreSystem())           // Update score/high score
        addCrossCuttingSystem(CleanupSystem())         // Must be last
        
        // Note: PlayerComponent, BulletComponent, ItemComponent now update themselves via GKComponentSystem
    }
    
    /// Add a cross-cutting system to the game loop
    private func addCrossCuttingSystem(_ system: GameSystem) {
        system.initialize(entityManager: entityManager, eventBus: eventBus)
        eventBus.register(listener: system)
        crossCuttingSystems.append(system)
    }
    
    /// Register an entity with all component systems (call when entity is created)
    func registerEntity(_ entity: GKEntity) {
        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }
    
    /// Unregister an entity from all component systems (call when entity is destroyed)
    func unregisterEntity(_ entity: GKEntity) {
        for componentSystem in componentSystems {
            componentSystem.removeComponent(foundIn: entity)
        }
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
            // Update all systems in order (only if not frozen)
            if !isTimeFrozen {
                // GameplayKit component systems (proper ECS way)
                for componentSystem in componentSystems {
                    componentSystem.update(deltaTime: deltaTime)
                }
                
                // Cross-cutting systems
                for system in crossCuttingSystems {
                    system.update(deltaTime: deltaTime)
                }
            }
            
            // Apply buffered world mutations (always process, even during freeze, to handle unfreeze commands)
            commandQueue.process(entityManager: entityManager, eventBus: eventBus)
        }
        
        // Process events
        eventBus.processEvents()
    }
    
    // MARK: - Game Control
    func restartGame() {
        // Restart the current stage from the beginning
        startStage(stageId: currentStage)
        print("Game restarted from stage \(currentStage)")
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
        currentStage = stageId
        eventBus.fire(StageStartedEvent(stageId: stageId))
        // Process events immediately to ensure systems reset their state before next frame
        eventBus.processEvents()
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
        print("Stage \(currentStage) ended")
    }
    
    private func clearTransientWorld() {
        // Remove bullets, enemies, items, and spawners; keep persistent/player
        let entities = entityManager.getAllEntities()
        for entity in entities {
            let hasBullet = entity.component(ofType: BulletComponent.self) != nil
            let hasEnemy = entity.component(ofType: EnemyComponent.self) != nil
            let hasItem = entity.component(ofType: ItemComponent.self) != nil
            if hasBullet || hasEnemy || hasItem {
                entityManager.markForDestruction(entity)
            }
        }
        entityManager.destroyMarkedEntities()
    }
    
    // MARK: - System Access (deprecated - use facades instead)
    
    /// @deprecated Use facades (entities, dialogue, combat) for most operations
    /// Only use this for special cases not covered by facades
    func getEntityManager() -> EntityManager {
        return entityManager
    }
    
    /// @deprecated Use facades for event-based operations
    func getEventBus() -> EventBus {
        return eventBus
    }
    
    /// @deprecated Use facades for command-based operations
    func getCommandQueue() -> CommandQueue {
        return commandQueue
    }
    
    
    /// Register an event listener (still needed for systems)
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
    
    // MARK: - State Query
    func isInNotStartedState() -> Bool {
        return stateMachine.currentState is GameNotStartedState
    }
    
    // MARK: - Time Freeze Control
    func isFrozen() -> Bool {
        return isTimeFrozen
    }
    
    func setTimeFrozen(_ frozen: Bool) {
        isTimeFrozen = frozen
    }
}
