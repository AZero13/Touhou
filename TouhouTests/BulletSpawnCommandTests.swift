//
//  BulletSpawnCommandTests.swift
//  TouhouTests
//
//  Created by Rose on 10/28/25.
//

import XCTest
import CoreGraphics
@testable import Touhou

class BulletSpawnCommandTests: XCTestCase {
    
    func testBulletSpawnCommandInitialization() {
        // Given
        let position = CGPoint(x: 100, y: 200)
        let velocity = CGVector(dx: 50, dy: -100)
        let physics = PhysicsConfig(speed: 200, damage: 3)
        let visual = VisualConfig(size: .medium, shape: .diamond, color: .green, hasTrail: true, trailLength: 4)
        let behavior = BehaviorConfig(homingStrength: 0.5, maxTurnRate: 1.0, delay: 0.5)
        let command = BulletSpawnCommand(
            position: position,
            velocity: velocity,
            bulletType: .custom("test_bullet"),
            physics: physics,
            visual: visual,
            behavior: behavior
        )
        
        // Then
        XCTAssertEqual(command.position, position)
        XCTAssertEqual(command.velocity, velocity)
        XCTAssertEqual(command.bulletType, .custom("test_bullet"))
        XCTAssertEqual(command.physics.speed, 200)
        XCTAssertEqual(command.physics.damage, 3)
        XCTAssertEqual(command.visual.size, .medium)
        XCTAssertEqual(command.visual.shape, .diamond)
        XCTAssertEqual(command.visual.color, .green)
        XCTAssertTrue(command.visual.hasTrail)
        XCTAssertEqual(command.visual.trailLength, 4)
        XCTAssertEqual(command.behavior.homingStrength, 0.5)
        XCTAssertEqual(command.behavior.maxTurnRate, 1.0)
        XCTAssertEqual(command.behavior.delay, 0.5)
    }
    
    func testBulletSpawnCommandDefaults() {
        // Given
        let position = CGPoint(x: 0, y: 0)
        let velocity = CGVector(dx: 0, dy: 0)
        let command = BulletSpawnCommand(
            position: position,
            velocity: velocity,
            bulletType: .enemyBullet
        )
        
        // Then
        XCTAssertEqual(command.position, position)
        XCTAssertEqual(command.velocity, velocity)
        XCTAssertEqual(command.bulletType, .enemyBullet)
        XCTAssertEqual(command.physics.speed, 150)
        XCTAssertEqual(command.physics.damage, 1)
        XCTAssertEqual(command.visual.size, .small)
        XCTAssertEqual(command.visual.shape, .circle)
        XCTAssertEqual(command.visual.color, .red)
        XCTAssertFalse(command.visual.hasTrail)
        XCTAssertEqual(command.visual.trailLength, 3)
        XCTAssertNil(command.behavior.homingStrength)
        XCTAssertNil(command.behavior.maxTurnRate)
        XCTAssertEqual(command.behavior.delay, 0)
    }
}
