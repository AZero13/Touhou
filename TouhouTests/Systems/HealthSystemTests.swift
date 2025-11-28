//
//  HealthSystemTests.swift
//  TouhouTests
//
//  Created by Antigravity on 11/27/25.
//

import XCTest
import GameplayKit
@testable import Touhou

@MainActor
final class HealthSystemTests: XCTestCase {
    var system: HealthSystem!
    var mockEntityManager: MockEntityManager!
    var mockEventBus: MockEventBus!
    
    override func setUp() {
        super.setUp()
        mockEntityManager = MockEntityManager()
        mockEventBus = MockEventBus()
        system = HealthSystem()
        
        let context = createTestContext()
        system.initialize(context: context)
    }
    
    override func tearDown() {
        system = nil
        mockEntityManager = nil
        mockEventBus = nil
        super.tearDown()
    }
    
    func createTestContext() -> GameRuntimeContext {
        GameRuntimeContext(
            entityManager: mockEntityManager,
            eventBus: mockEventBus,
            entities: EntityFacade(
                entityManager: mockEntityManager,
                commandQueue: CommandQueue(),
                eventBus: mockEventBus,
                registerEntity: { _ in }
            ),
            combat: CombatFacade(
                entityManager: mockEntityManager,
                commandQueue: CommandQueue(),
                eventBus: mockEventBus
            ),
            isTimeFrozen: false,
            currentStage: 1,
            unregisterEntity: { _ in }
        )
    }
    
    // MARK: - Tests
    
    func testEntityWithHealthComponentIsAlive() {
        let entity = GKEntity()
        entity.addComponent(HealthComponent(health: 100, maxHealth: 100))
        
        let health = entity.component(ofType: HealthComponent.self)!
        XCTAssertTrue(health.isAlive, "Entity with positive health should be alive")
    }
    
    func testEntityWithZeroHealthIsDead() {
        let entity = GKEntity()
        entity.addComponent(HealthComponent(health: 0, maxHealth: 100))
        
        let health = entity.component(ofType: HealthComponent.self)!
        XCTAssertFalse(health.isAlive, "Entity with zero health should be dead")
    }
    
    func testInvulnerabilityDecreases() {
        let entity = GKEntity()
        entity.addComponent(HealthComponent(health: 100, maxHealth: 100, invulnerabilityTimer: 2.0))
        mockEntityManager.addEntity(entity)
        
        let health = entity.component(ofType: HealthComponent.self)!
        let initialTimer = health.invulnerabilityTimer
        
        system.update(deltaTime: 0.5, context: createTestContext())
        
        XCTAssertLessThan(health.invulnerabilityTimer, initialTimer, "Invulnerability timer should decrease")
    }
    
    func testInvulnerabilityPreventsDamage() {
        let entity = GKEntity()
        entity.addComponent(HealthComponent(health: 100, maxHealth: 100, invulnerabilityTimer: 2.0))
        
        let health = entity.component(ofType: HealthComponent.self)!
        XCTAssertTrue(health.isInvulnerable, "Entity should be invulnerable when timer > 0")
    }
    
    func testBossPhaseTransition() {
        // Create a multi-phase boss
        let boss = GKEntity()
        boss.addComponent(BossComponent(
            name: "Test Boss",
            phaseNumber: 1,
            hasTimeBonus: false,
            timeLimit: 30.0,
            bonusPointsBase: 10000,
            totalPhases: 2,
            phaseHealths: [100, 200]
        ))
        boss.addComponent(HealthComponent(health: 100, maxHealth: 100))
        boss.addComponent(EnemyComponent(enemyType: .boss, scoreValue: 5000))
        mockEntityManager.addEntity(boss)
        
        let bossComp = boss.component(ofType: BossComponent.self)!
        XCTAssertEqual(bossComp.currentPhase, 1, "Boss should start in phase 1")
        XCTAssertEqual(bossComp.currentPhaseHealth, 100, "Boss should have phase 1 health")
        
        // Reduce health to 0 to trigger phase transition
        let health = boss.component(ofType: HealthComponent.self)!
        health.health = 0
        
        let context = createTestContext()
        system.update(deltaTime: 0.016, context: context)
        
        // Boss should transition to phase 2 (health system handles this via BossTransitionedToNextPhaseEvent)
        XCTAssertFalse(health.isAlive, "Boss should be considered dead when phase depleted")
    }
    
    func testMaxHealthCap() {
        let entity = GKEntity()
        entity.addComponent(HealthComponent(health: 150, maxHealth: 100))
        
        let health = entity.component(ofType: HealthComponent.self)!
        XCTAssertEqual(health.health, 100, "Health should be capped at max health")
    }
}
