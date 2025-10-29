//
//  BulletComponentTests.swift
//  TouhouTests
//
//  Created by Rose on 10/28/25.
//

import XCTest
import GameplayKit
@testable import Touhou

class BulletComponentTests: XCTestCase {
    
    func testBulletComponentInitialization() {
        // Given
        let bullet = BulletComponent(
            ownedByPlayer: true,
            bulletType: .custom("test_bullet"),
            damage: 5,
            homingStrength: 0.5,
            maxTurnRate: 1.0,
            size: .medium,
            shape: .diamond,
            color: .blue,
            hasTrail: true,
            trailLength: 5
        )
        
        // Then
        XCTAssertTrue(bullet.ownedByPlayer)
        XCTAssertEqual(bullet.bulletType, .custom("test_bullet"))
        XCTAssertEqual(bullet.damage, 5)
        XCTAssertEqual(bullet.homingStrength, 0.5)
        XCTAssertEqual(bullet.maxTurnRate, 1.0)
        XCTAssertEqual(bullet.size, .medium)
        XCTAssertEqual(bullet.shape, .diamond)
        XCTAssertEqual(bullet.color, .blue)
        XCTAssertTrue(bullet.hasTrail)
        XCTAssertEqual(bullet.trailLength, 5)
    }
    
    func testBulletComponentDefaults() {
        // Given
        let bullet = BulletComponent(ownedByPlayer: false)
        
        // Then
        XCTAssertFalse(bullet.ownedByPlayer)
        XCTAssertEqual(bullet.bulletType, .needle)
        XCTAssertEqual(bullet.damage, 1)
        XCTAssertNil(bullet.homingStrength)
        XCTAssertNil(bullet.maxTurnRate)
        XCTAssertEqual(bullet.size, .small)
        XCTAssertEqual(bullet.shape, .circle)
        XCTAssertEqual(bullet.color, .red)
        XCTAssertFalse(bullet.hasTrail)
        XCTAssertEqual(bullet.trailLength, 3)
    }
    
    func testBulletSizeRadius() {
        // Then
        XCTAssertEqual(BulletSize.tiny.radius, 2)
        XCTAssertEqual(BulletSize.small.radius, 3)
        XCTAssertEqual(BulletSize.medium.radius, 5)
        XCTAssertEqual(BulletSize.large.radius, 8)
        XCTAssertEqual(BulletSize.huge.radius, 12)
    }
    
    func testBulletColorNSColor() {
        // Then
        XCTAssertEqual(BulletColor.red.nsColor, NSColor.red)
        XCTAssertEqual(BulletColor.blue.nsColor, NSColor.blue)
        XCTAssertEqual(BulletColor.green.nsColor, NSColor.green)
        XCTAssertEqual(BulletColor.yellow.nsColor, NSColor.yellow)
        XCTAssertEqual(BulletColor.purple.nsColor, NSColor.purple)
        XCTAssertEqual(BulletColor.cyan.nsColor, NSColor.cyan)
        XCTAssertEqual(BulletColor.orange.nsColor, NSColor.orange)
        XCTAssertEqual(BulletColor.pink.nsColor, NSColor.systemPink)
    }
    
    func testDamagingProtocol() {
        // Given
        let bullet = BulletComponent(ownedByPlayer: true, damage: 3)
        
        // Then
        XCTAssertEqual(bullet.damage, 3)
    }
}
