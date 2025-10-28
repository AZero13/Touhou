//
//  BulletCommandsTests.swift
//  TouhouTests
//
//  Created by Rose on 10/28/25.
//

import XCTest
@testable import Touhou

class BulletCommandsTests: XCTestCase {
    
    func testPhysicsConfigInitialization() {
        // Given
        let config = PhysicsConfig(speed: 200, damage: 3)
        
        // Then
        XCTAssertEqual(config.speed, 200)
        XCTAssertEqual(config.damage, 3)
    }
    
    func testPhysicsConfigDefaults() {
        // Given
        let config = PhysicsConfig()
        
        // Then
        XCTAssertEqual(config.speed, 150)
        XCTAssertEqual(config.damage, 1)
    }
    
    func testVisualConfigInitialization() {
        // Given
        let config = VisualConfig(size: .large, shape: .star, color: .purple, hasTrail: true, trailLength: 7)
        
        // Then
        XCTAssertEqual(config.size, .large)
        XCTAssertEqual(config.shape, .star)
        XCTAssertEqual(config.color, .purple)
        XCTAssertTrue(config.hasTrail)
        XCTAssertEqual(config.trailLength, 7)
    }
    
    func testVisualConfigDefaults() {
        // Given
        let config = VisualConfig()
        
        // Then
        XCTAssertEqual(config.size, .small)
        XCTAssertEqual(config.shape, .circle)
        XCTAssertEqual(config.color, .red)
        XCTAssertFalse(config.hasTrail)
        XCTAssertEqual(config.trailLength, 3)
    }
    
    func testBehaviorConfigInitialization() {
        // Given
        let config = BehaviorConfig(homingStrength: 0.5, maxTurnRate: 1.0, delay: 0.5)
        
        // Then
        XCTAssertEqual(config.homingStrength, 0.5)
        XCTAssertEqual(config.maxTurnRate, 1.0)
        XCTAssertEqual(config.delay, 0.5)
    }
    
    func testBehaviorConfigDefaults() {
        // Given
        let config = BehaviorConfig()
        
        // Then
        XCTAssertNil(config.homingStrength)
        XCTAssertNil(config.maxTurnRate)
        XCTAssertEqual(config.delay, 0)
    }
    
    func testPatternConfigInitialization() {
        // Given
        let physics = PhysicsConfig(speed: 200, damage: 3)
        let visual = VisualConfig(size: .large, shape: .star, color: .purple)
        let behavior = BehaviorConfig(homingStrength: 0.5, maxTurnRate: 1.0)
        let config = PatternConfig(physics: physics, visual: visual, behavior: behavior, bulletCount: 10, spread: 75, spiralSpeed: 20)
        
        // Then
        XCTAssertEqual(config.physics.speed, 200)
        XCTAssertEqual(config.physics.damage, 3)
        XCTAssertEqual(config.visual.size, .large)
        XCTAssertEqual(config.visual.shape, .star)
        XCTAssertEqual(config.visual.color, .purple)
        XCTAssertEqual(config.behavior.homingStrength, 0.5)
        XCTAssertEqual(config.behavior.maxTurnRate, 1.0)
        XCTAssertEqual(config.bulletCount, 10)
        XCTAssertEqual(config.spread, 75)
        XCTAssertEqual(config.spiralSpeed, 20)
    }
    
    func testPatternConfigDefaults() {
        // Given
        let config = PatternConfig()
        
        // Then
        XCTAssertEqual(config.physics.speed, 150)
        XCTAssertEqual(config.physics.damage, 1)
        XCTAssertEqual(config.visual.size, .small)
        XCTAssertEqual(config.visual.shape, .circle)
        XCTAssertEqual(config.visual.color, .red)
        XCTAssertNil(config.behavior.homingStrength)
        XCTAssertNil(config.behavior.maxTurnRate)
        XCTAssertEqual(config.bulletCount, 8)
        XCTAssertEqual(config.spread, 50)
        XCTAssertEqual(config.spiralSpeed, 10)
    }
}
