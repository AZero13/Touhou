//
//  BulletCommands.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import CoreGraphics
import GameplayKit

// MARK: - Physics Configuration
struct PhysicsConfig {
    let speed: CGFloat
    let damage: Int
    
    init(speed: CGFloat = 150, damage: Int = 1) {
        self.speed = speed
        self.damage = damage
    }
}

// MARK: - Visual Configuration
struct VisualConfig {
    let size: BulletSize
    let shape: BulletShape
    let color: BulletColor
    let hasTrail: Bool
    let trailLength: Int
    
    init(size: BulletSize = .small, shape: BulletShape = .circle, color: BulletColor = .red, 
         hasTrail: Bool = false, trailLength: Int = 3) {
        self.size = size
        self.shape = shape
        self.color = color
        self.hasTrail = hasTrail
        self.trailLength = trailLength
    }
}

// MARK: - Behavior Configuration
struct BehaviorConfig {
    let homingStrength: CGFloat?
    let maxTurnRate: CGFloat?
    let delay: TimeInterval
    // TH06-style discrete retargeting
    let retargetInterval: TimeInterval?
    let maxRetargets: Int?
    let rotationOffset: CGFloat
    
    init(homingStrength: CGFloat? = nil, maxTurnRate: CGFloat? = nil, delay: TimeInterval = 0,
         retargetInterval: TimeInterval? = nil, maxRetargets: Int? = nil, rotationOffset: CGFloat = 0) {
        self.homingStrength = homingStrength
        self.maxTurnRate = maxTurnRate
        self.delay = delay
        self.retargetInterval = retargetInterval
        self.maxRetargets = maxRetargets
        self.rotationOffset = rotationOffset
    }
}

// MARK: - Bullet Spawn Command
struct BulletSpawnCommand {
    let position: CGPoint
    let velocity: CGVector
    let bulletType: BulletComponent.BulletType
    
    // Configuration objects
    let physics: PhysicsConfig
    let visual: VisualConfig
    let behavior: BehaviorConfig
    
    init(position: CGPoint, velocity: CGVector, bulletType: BulletComponent.BulletType = .enemyBullet,
         physics: PhysicsConfig = PhysicsConfig(),
         visual: VisualConfig = VisualConfig(),
         behavior: BehaviorConfig = BehaviorConfig()) {
        self.position = position
        self.velocity = velocity
        self.bulletType = bulletType
        self.physics = physics
        self.visual = visual
        self.behavior = behavior
    }
}

// MARK: - Pattern Configuration
struct PatternConfig {
    let physics: PhysicsConfig
    let visual: VisualConfig
    let behavior: BehaviorConfig
    
    // Pattern-specific properties
    let bulletCount: Int
    let spread: CGFloat
    let spiralSpeed: CGFloat
    
    init(physics: PhysicsConfig = PhysicsConfig(),
         visual: VisualConfig = VisualConfig(),
         behavior: BehaviorConfig = BehaviorConfig(),
         bulletCount: Int = 8,
         spread: CGFloat = 50,
         spiralSpeed: CGFloat = 10) {
        self.physics = physics
        self.visual = visual
        self.behavior = behavior
        self.bulletCount = bulletCount
        self.spread = spread
        self.spiralSpeed = spiralSpeed
    }
}
