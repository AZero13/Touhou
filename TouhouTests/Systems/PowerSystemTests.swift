//
//  PowerSystemTests.swift
//  TouhouTests
//
//  Created by Antigravity on 11/27/25.
//

import XCTest
import GameplayKit
@testable import Touhou

@MainActor
final class PowerSystemTests: XCTestCase {
    var system: PowerSystem!
    var mockEntityManager: MockEntityManager!
    var mockEventBus: MockEventBus!
    var playerEntity: GKEntity!
    
    override func setUp() {
        super.setUp()
        mockEntityManager = MockEntityManager()
        mockEventBus = MockEventBus()
        system = PowerSystem()
        
        // Create a player entity with necessary components
        playerEntity = GKEntity()
        playerEntity.addComponent(PlayerComponent())
        mockEntityManager.addEntity(playerEntity)
        
        let context = createTestContext()
        system.initialize(context: context)
    }
    
    override func tearDown() {
        system = nil
        mockEntityManager = nil
        mockEventBus = nil
        playerEntity = nil
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
    
    func testPowerInitiallyZero() {
        let player = mockEntityManager.getPlayerComponent()!
        XCTAssertEqual(player.power, 0, "Player power should start at 0")
    }
    
    func testPowerIncreases() {
        let player = mockEntityManager.getPlayerComponent()!
        player.power = 0
        
        let event = PowerUpCollectedEvent(itemType: .power, value: 10, position: .zero)
        system.handleEvent(event, context: createTestContext())
        
        XCTAssertEqual(player.power, 1, "Power should increase by 1 for power item")
    }
    
    func testPowerLevelChangedEventFired() {
        let player = mockEntityManager.getPlayerComponent()!
        player.power = 0
        mockEventBus.reset()
        
        let event = PowerUpCollectedEvent(itemType: .power, value: 10, position: .zero)
        system.handleEvent(event, context: createTestContext())
        
        XCTAssertTrue(mockEventBus.didFire(PowerLevelChangedEvent.self), "PowerLevelChangedEvent should be fired")
    }
    
    func testPowerThresholds() {
        let player = mockEntityManager.getPlayerComponent()!
        player.power = 0
        
        // PowerSystem thresholds: [8, 16, 32, 48, 64, 80, 96, 128]
        // First threshold is 8
        for _ in 0..<8 {
            let event = PowerUpCollectedEvent(itemType: .power, value: 10, position: .zero)
            system.handleEvent(event, context: createTestContext())
        }
        
        XCTAssertEqual(player.power, 8, "Power should be at threshold after collecting 8 items")
    }
    
    func testPowerCappedAt128() {
        let player = mockEntityManager.getPlayerComponent()!
        player.power = 128  // Max power level
        
        let event = PowerUpCollectedEvent(itemType: .power, value: 10, position: .zero)
        system.handleEvent(event, context: createTestContext())
        
        XCTAssertEqual(player.power, 128, "Power should not exceed 128")
    }
    
    func testPowerItemCountResetsAfterThreshold() {
        let player = mockEntityManager.getPlayerComponent()!
        player.power = 0
        player.powerItemCountForScore = 0
        
        // Collect items up to threshold
        for _ in 0..<8 {
            let event = PowerUpCollectedEvent(itemType: .power, value: 10, position: .zero)
            system.handleEvent(event, context: createTestContext())
        }
        
        // powerItemCountForScore should reset when threshold is reached
        XCTAssertEqual(player.powerItemCountForScore, 0, "Power item count should reset at threshold")
    }
}
