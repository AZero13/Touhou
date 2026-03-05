//
//  ScoreSystemTests.swift
//  TouhouTests
//
//  Created by Antigravity on 11/27/25.
//

import XCTest
import GameplayKit
@testable import Touhou

@MainActor
final class ScoreSystemTests: XCTestCase {
    var system: ScoreSystem!
    var mockEntityManager: MockEntityManager!
    var mockEventBus: MockEventBus!
    var playerEntity: GKEntity!
    
    override func setUp() {
        super.setUp()
        mockEntityManager = MockEntityManager()
        mockEventBus = MockEventBus()
        system = ScoreSystem()
        
        // Create a player entity with necessary components
        playerEntity = GKEntity()
        playerEntity.addComponent(PlayerComponent())
        mockEntityManager.addEntity(playerEntity)
        
        let engine = createTestEngine()
        system.initialize(engine: engine)
    }
    
    override func tearDown() {
        system = nil
        mockEntityManager = nil
        mockEventBus = nil
        playerEntity = nil
        super.tearDown()
    }
    
    func createTestEngine() -> MockGameEngine {
        MockGameEngine(
            entityManager: mockEntityManager,
            eventBus: mockEventBus
        )
    }
    
    // MARK: - Tests
    
    func testScoreInitiallyZero() {
        let player = mockEntityManager.getPlayerComponent()
        XCTAssertEqual(player?.score, 0, "Player score should start at 0")
    }
    
    func testPowerUpCollectedAddsScore() {
        let player = mockEntityManager.getPlayerComponent()!
        let initialScore = player.score
        
        // Simulate power-up collection with value
        let event = PowerUpCollectedEvent(itemType: .power, value: 1000, position: .zero)
        system.handleEvent(event)
        
        XCTAssertEqual(player.score, initialScore + 1000, "Score should increase by power-up value")
    }
    
    func testScoreChangedEventFired() {
        let player = mockEntityManager.getPlayerComponent()!
        player.score = 0
        mockEventBus.reset()
        
        let event = PowerUpCollectedEvent(itemType: .power, value: 500, position: .zero)
        system.handleEvent(event)
        
        XCTAssertTrue(mockEventBus.didFire(ScoreChangedEvent.self), "ScoreChangedEvent should be fired")
        
        let scoreEvents = mockEventBus.getEvents(ofType: ScoreChangedEvent.self)
        XCTAssertEqual(scoreEvents.count, 1, "Exactly one ScoreChangedEvent should be fired")
        XCTAssertEqual(scoreEvents.first?.newTotal, 500, "ScoreChangedEvent should contain new score")
    }
    
    func testHighScoreUpdates() {
        let player = mockEntityManager.getPlayerComponent()!
        player.score = 0
        
        // Set score higher than initial high score (0)
        player.score = 5000
        let event = PowerUpCollectedEvent(itemType: .point, value: 1000, position: .zero)
        system.handleEvent(event)
        
        // High score should update
        XCTAssertTrue(mockEventBus.didFire(HighScoreChangedEvent.self), "HighScoreChangedEvent should be fired when score exceeds high score")
    }
    
    func testZeroValuePowerUpStillTracked() {
        let player = mockEntityManager.getPlayerComponent()!
        let initialScore = player.score
        
        let event = PowerUpCollectedEvent(itemType: .power, value: 0, position: .zero)
        system.handleEvent(event)
        
        XCTAssertEqual(player.score, initialScore, "Score should not change for zero-value power-up")
    }
}
