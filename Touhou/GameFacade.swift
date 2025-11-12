//
//  GameFacade.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit
import CoreGraphics

@MainActor
class GameFacade {
    static let shared = GameFacade()
    static let playArea: CGRect = CGRect(x: 0, y: 0, width: 384, height: 448)
    static let maxStage: Int = 6
    
    private let entityManager = EntityManager()
    private let eventBus = EventBus()
    private let commandQueue = CommandQueue()
    
    private(set) lazy var entities: EntityFacade = {
        EntityFacade(entityManager: entityManager, commandQueue: commandQueue, eventBus: eventBus, registerEntity: registerEntity)
    }()
    
    private(set) lazy var combat: CombatFacade = {
        CombatFacade(entityManager: entityManager, commandQueue: commandQueue, eventBus: eventBus)
    }()
    
    private var componentSystems: [GKComponentSystem] = []
    private var crossCuttingSystems: [GameSystem] = []
    private var stateMachine: GKStateMachine!
    private var lastUpdateTime: TimeInterval = 0
    
    var currentStage: Int {
        _currentStage
    }
    private var _currentStage: Int = 1
    
    var isTimeFrozen: Bool {
        get { _isTimeFrozen }
        set { _isTimeFrozen = newValue }
    }
    private var _isTimeFrozen: Bool = false
    
    var isInNotStartedState: Bool {
        stateMachine.currentState is GameNotStartedState
    }
    
    private init() {
        setupStateMachine()
        setupSystems()
    }
    
    private func setupStateMachine() {
        let notStartedState = GameNotStartedState(gameFacade: self)
        let playingState = GamePlayingState(gameFacade: self)
        let pausedState = GamePausedState(gameFacade: self)
        stateMachine = GKStateMachine(states: [notStartedState, playingState, pausedState])
        stateMachine.enter(GameNotStartedState.self)
    }
    
    private func setupSystems() {
        componentSystems = [
            GKComponentSystem(componentClass: PlayerComponent.self),
            GKComponentSystem(componentClass: EnemyComponent.self),
            GKComponentSystem(componentClass: BulletComponent.self),
            GKComponentSystem(componentClass: ItemComponent.self),
            GKComponentSystem(componentClass: BossComponent.self)
        ]
        
        addCrossCuttingSystem(PlayerLifecycleSystem())
        addCrossCuttingSystem(EnemySystem())
        addCrossCuttingSystem(BulletHomingSystem())
        addCrossCuttingSystem(ItemAttractionSystem())
        addCrossCuttingSystem(CollisionSystem())
        addCrossCuttingSystem(HealthSystem())
        addCrossCuttingSystem(PowerSystem())
        addCrossCuttingSystem(ScoreSystem())
        addCrossCuttingSystem(DialogueSystem())
        addCrossCuttingSystem(CleanupSystem())
    }
    
    private func addCrossCuttingSystem(_ system: GameSystem) {
        let context = createRuntimeContext()
        system.initialize(context: context)
        eventBus.register(listener: system)
        crossCuttingSystems.append(system)
    }
    
    private func createRuntimeContext() -> GameRuntimeContext {
        GameRuntimeContext(
            entityManager: entityManager,
            eventBus: eventBus,
            entities: entities,
            combat: combat,
            isTimeFrozen: _isTimeFrozen,
            currentStage: _currentStage,
            unregisterEntity: unregisterEntity
        )
    }
    
    func registerEntity(_ entity: GKEntity) {
        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }
    
    func unregisterEntity(_ entity: GKEntity) {
        for componentSystem in componentSystems {
            componentSystem.removeComponent(foundIn: entity)
        }
    }
    
    func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        InputManager.shared.update()
        stateMachine.update(deltaTime: deltaTime)
        
        if stateMachine.currentState is GamePlayingState {
            let context = createRuntimeContext()
            
            if !_isTimeFrozen {
                // Phase 1: Component systems (player, enemies, bullets, items)
                for componentSystem in componentSystems {
                    componentSystem.update(deltaTime: deltaTime)
                }
                
                // Phase 2: Cross-cutting systems
                for system in crossCuttingSystems {
                    system.update(deltaTime: deltaTime, context: context)
                }
            }
            
            // Phase 3: Process command queue
            commandQueue.process(
                entityManager: entityManager,
                eventBus: eventBus,
                isTimeFrozen: _isTimeFrozen,
                registerEntity: registerEntity
            )
        }
        eventBus.processEvents(context: createRuntimeContext())
    }
    
    func restartGame() {
        startNewRun()
        print("Game restarted from stage 1")
    }
    
    func startNewRun() {
        _currentStage = 1
        startStage(stageId: _currentStage)
    }
    
    func startStage(stageId: Int) {
        clearTransientWorld()
        commandQueue.clear()
        _currentStage = stageId
        lastUpdateTime = CACurrentMediaTime()
        stateMachine.enter(GamePlayingState.self)
        eventBus.fire(StageStartedEvent(stageId: stageId))
        eventBus.processEvents(context: createRuntimeContext())  // Process StageStartedEvent immediately so systems initialize before first frame
        print("Stage \(stageId) started")
    }
    
    func endStage() {
        stateMachine.enter(GameNotStartedState.self)
        eventBus.fire(StageEndedEvent(stageId: _currentStage))
        eventBus.processEvents(context: createRuntimeContext())
        clearTransientWorld()
        commandQueue.clear()
        print("Stage \(_currentStage) ended")
    }
    
    private func clearTransientWorld() {
        let entities = entityManager.getAllEntities()
        for entity in entities {
            let hasBullet = entity.component(ofType: BulletComponent.self) != nil
            let hasEnemy = entity.component(ofType: EnemyComponent.self) != nil
            let hasItem = entity.component(ofType: ItemComponent.self) != nil
            if hasBullet || hasEnemy || hasItem {
                entityManager.markForDestruction(entity)
            }
        }
        entityManager.destroyMarkedEntities(unregisterEntity: unregisterEntity)
    }
    
    func registerListener(_ listener: EventListener) {
        eventBus.register(listener: listener)
    }
    
    func unregisterListener(_ listener: EventListener) {
        eventBus.unregister(listener)
    }
    
    func fireEvent(_ event: GameEvent) {
        eventBus.fire(event)
    }
    
    /// Activate bomb with proper context
    func activateBomb(playerEntity: GKEntity) {
        let context = createRuntimeContext()
        combat.activateBomb(playerEntity: playerEntity, context: context)
    }
}
