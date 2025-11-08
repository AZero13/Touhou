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
        EntityFacade(entityManager: entityManager, commandQueue: commandQueue, eventBus: eventBus)
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
            GKComponentSystem(componentClass: ItemComponent.self)
        ]
        
        addCrossCuttingSystem(PlayerLifecycleSystem())
        addCrossCuttingSystem(EnemySystem())
        addCrossCuttingSystem(BulletHomingSystem())
        addCrossCuttingSystem(ItemAttractionSystem())
        addCrossCuttingSystem(CollisionSystem())
        addCrossCuttingSystem(HealthSystem())
        addCrossCuttingSystem(PowerSystem())
        addCrossCuttingSystem(ScoreSystem())
        addCrossCuttingSystem(CleanupSystem())
    }
    
    private func addCrossCuttingSystem(_ system: GameSystem) {
        system.initialize(entityManager: entityManager, eventBus: eventBus)
        eventBus.register(listener: system)
        crossCuttingSystems.append(system)
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
            if !_isTimeFrozen {
                for componentSystem in componentSystems {
                    componentSystem.update(deltaTime: deltaTime)
                }
                for system in crossCuttingSystems {
                    system.update(deltaTime: deltaTime)
                }
            }
            commandQueue.process(entityManager: entityManager, eventBus: eventBus)
        }
        
        eventBus.processEvents()
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
        eventBus.processEvents()
        lastUpdateTime = CACurrentMediaTime()
        stateMachine.enter(GamePlayingState.self)
        print("Stage \(stageId) started")
    }
    
    func endStage() {
        stateMachine.enter(GameNotStartedState.self)
        eventBus.fire(StageEndedEvent(stageId: _currentStage))
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
        entityManager.destroyMarkedEntities()
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
}
