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
class GameFacade: GameEngine {
    static let shared = GameFacade()
    
    // GameEngine protocol requirement
    var playArea: CGRect { return GameFacade.playArea }
    
    static let playArea: CGRect = CGRect(x: 0, y: 0, width: 384, height: 448)
    static let maxStage: Int = 6
    
    let entityManager: EntityManaging = EntityManager()
    let eventBus: EventDispatching = EventBus()
    private let commandQueue = CommandQueue()
    
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
    
    init() {
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
            GKComponentSystem(componentClass: BossComponent.self),
            GKComponentSystem(componentClass: LaserComponent.self)
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
        system.initialize(engine: self)
        eventBus.register(listener: system)
        crossCuttingSystems.append(system)
    }
    
    // MARK: - Entity Registration
    
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
    
    // MARK: - Game Loop
    
    func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        InputManager.shared.update()
        stateMachine.update(deltaTime: deltaTime)
        
        if stateMachine.currentState is GamePlayingState {
            if !_isTimeFrozen {
                // Phase 1: Component systems (player, enemies, bullets, items)
                for componentSystem in componentSystems {
                    componentSystem.update(deltaTime: deltaTime)
                }
                
                // Phase 2: Cross-cutting systems
                for system in crossCuttingSystems {
                    system.update(deltaTime: deltaTime)
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
        eventBus.processEvents()
    }
    
    // MARK: - Stage Management
    
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
        lastUpdateTime = 0
        stateMachine.enter(GamePlayingState.self)
        eventBus.fire(StageStartedEvent(stageId: stageId))
        eventBus.processEvents()  // Process StageStartedEvent immediately
        print("Stage \(stageId) started")
    }
    
    func endStage() {
        stateMachine.enter(GameNotStartedState.self)
        eventBus.fire(StageEndedEvent(stageId: _currentStage))
        eventBus.processEvents()
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
    
    // MARK: - Events
    
    func registerListener(_ listener: EventListener) {
        eventBus.register(listener: listener)
    }
    
    func unregisterListener(_ listener: EventListener) {
        eventBus.unregister(listener)
    }
    
    func fireEvent(_ event: GameEvent) {
        eventBus.fire(event)
    }
    
    func processEvents() {
        eventBus.processEvents()
    }
    
    // MARK: - Entity Spawning (from EntityFacade)
    
    var player: GKEntity? {
        entityManager.getPlayerEntity()
    }
    
    @discardableResult
    func spawnBoss(data: BossData) -> GKEntity {
        let entity = entityManager.createEntity()
        let bossComponent = BossComponent(
            name: data.name,
            phaseNumber: data.phaseNumber,
            hasTimeBonus: data.hasTimeBonus,
            timeLimit: data.timeLimit,
            bonusPointsBase: data.bonusPointsBase,
            totalPhases: data.totalPhases,
            phaseHealths: data.phaseHealths
        )
        entity.addComponent(bossComponent)
        entity.addComponent(EnemyComponent(
            enemyType: .boss,
            scoreValue: 5000,
            dropItem: nil,
            attackPattern: data.attackPattern,
            patternConfig: data.patternConfig,
            shotInterval: data.shotInterval
        ))
        entity.addComponent(TransformComponent(position: data.position, velocity: .zero))
        let firstPhaseHealth = bossComponent.phaseHealths.first ?? data.health
        entity.addComponent(HealthComponent(health: firstPhaseHealth, maxHealth: firstPhaseHealth))
        bossComponent.currentPhaseHealth = firstPhaseHealth
        entity.addComponent(HitboxComponent(enemyHitbox: 14))
        registerEntity(entity)
        return entity
    }
    
    @discardableResult
    func spawnFairy(
        position: CGPoint,
        attackPattern: EnemyPattern,
        patternConfig: PatternConfig,
        shotInterval: TimeInterval = 2.0,
        dropItem: ItemType? = .power
    ) -> GKEntity {
        let entity = entityManager.createEntity()
        entity.addComponent(EnemyComponent(
            enemyType: .fairy,
            scoreValue: 100,
            dropItem: dropItem,
            attackPattern: attackPattern,
            patternConfig: patternConfig,
            shotInterval: shotInterval
        ))
        entity.addComponent(TransformComponent(position: position, velocity: CGVector(dx: 0, dy: -50)))
        entity.addComponent(HitboxComponent(enemyHitbox: 9))
        entity.addComponent(HealthComponent(health: 1, maxHealth: 1))
        registerEntity(entity)
        return entity
    }
    
    func spawnBullet(
        position: CGPoint,
        velocity: CGVector,
        bulletType: BulletComponent.BulletType = .enemyBullet,
        ownedByPlayer: Bool = false,
        physics: PhysicsConfig = PhysicsConfig(),
        visual: VisualConfig = VisualConfig(),
        behavior: BehaviorConfig = BehaviorConfig()
    ) {
        let cmd = BulletSpawnCommand(
            position: position,
            velocity: velocity,
            bulletType: bulletType,
            physics: physics,
            visual: visual,
            behavior: behavior
        )
        commandQueue.enqueue(.spawnBullet(cmd, ownedByPlayer: ownedByPlayer))
    }
    
    func spawnItem(type: ItemType, at position: CGPoint, velocity: CGVector = .zero) {
        commandQueue.enqueue(.spawnItem(type: type, position: position, velocity: velocity))
    }
    
    func destroy(_ entity: GKEntity) {
        commandQueue.enqueue(.destroyEntity(entity))
    }
    
    func destroyAllBullets(where filter: ((BulletComponent) -> Bool)? = nil) {
        CommandQueue.despawnAllBullets(entityManager: entityManager, destroyEntity: destroy, selector: filter)
    }
    
    // MARK: - Combat (from CombatFacade)
    
    func damage(_ entity: GKEntity, amount: Int) {
        commandQueue.enqueue(.applyDamage(entity: entity, amount: amount))
    }
    
    func heal(_ entity: GKEntity, amount: Int) {
        guard let healthComp = entity.component(ofType: HealthComponent.self) else { return }
        healthComp.health = min(healthComp.maxHealth, healthComp.health + amount)
    }
    
    func gainLives(_ amount: Int) {
        commandQueue.enqueue(.adjustLives(delta: amount))
    }
    
    func loseLife() {
        commandQueue.enqueue(.adjustLives(delta: -1))
    }
    
    func gainBombs(_ amount: Int) {
        commandQueue.enqueue(.adjustBombs(delta: amount))
    }
    
    func loseBomb() {
        commandQueue.enqueue(.adjustBombs(delta: -1))
    }
    
    func gainPower(_ amount: Int) {
        commandQueue.enqueue(.adjustPower(delta: amount))
    }
    
    func losePower(_ amount: Int) {
        commandQueue.enqueue(.adjustPower(delta: -amount))
    }
    
    func addScore(_ amount: Int) {
        commandQueue.enqueue(.adjustScore(amount: amount))
    }
    
    func activateBomb(playerEntity: GKEntity) {
        if let playerHealth = playerEntity.component(ofType: HealthComponent.self) {
            playerHealth.invulnerabilityTimer = 6.0
        }
        
        BulletUtility.convertBulletsToPoints(entityManager: entityManager, engine: self)
        eventBus.fire(AttractItemsEvent(itemTypes: [.pointBullet]))
        
        let enemies = entityManager.getEntities(with: EnemyComponent.self)
        for enemy in enemies {
            damage(enemy, amount: 50)
        }
        
        eventBus.fire(BombActivatedEvent(playerEntity: playerEntity))
        loseBomb()
    }
    
    func spawnEnemyBullet(_ command: BulletSpawnCommand) {
        commandQueue.enqueue(.spawnBullet(command, ownedByPlayer: false))
    }
    
    func spawnEnemyLaser(_ command: LaserSpawnCommand) {
        commandQueue.enqueue(.spawnLaser(command, ownedByPlayer: false))
    }
    
    func fireItemCollectionEvent(itemType: ItemType, value: Int, position: CGPoint) {
        eventBus.fire(PowerUpCollectedEvent(itemType: itemType, value: value, position: position))
    }
}
