//
//  BulletCommands.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import CoreGraphics
import GameplayKit

struct PhysicsConfig {
    let speed: CGFloat
    let damage: Int
    
    init(speed: CGFloat = 150, damage: Int = 1) {
        self.speed = speed
        self.damage = damage
    }
}

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

struct BehaviorConfig {
    let homingStrength: CGFloat?
    let maxTurnRate: CGFloat?
    let delay: TimeInterval
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

struct BulletSpawnCommand {
    let position: CGPoint
    let velocity: CGVector
    let bulletType: BulletComponent.BulletType
    let groupId: Int?
    let patternId: Int?
    let tags: Set<String>
    let physics: PhysicsConfig
    let visual: VisualConfig
    let behavior: BehaviorConfig
    
    init(position: CGPoint, velocity: CGVector, bulletType: BulletComponent.BulletType = .enemyBullet,
         physics: PhysicsConfig = PhysicsConfig(),
         visual: VisualConfig = VisualConfig(),
         behavior: BehaviorConfig = BehaviorConfig(),
         groupId: Int? = nil, patternId: Int? = nil, tags: Set<String> = []) {
        self.position = position
        self.velocity = velocity
        self.bulletType = bulletType
        self.physics = physics
        self.visual = visual
        self.behavior = behavior
        self.groupId = groupId
        self.patternId = patternId
        self.tags = tags
    }
}

struct PatternConfig {
    let physics: PhysicsConfig
    let visual: VisualConfig
    let behavior: BehaviorConfig
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

/// Command for spawning a laser beam.
struct LaserSpawnCommand {
    let position: CGPoint
    let angle: CGFloat
    let length: CGFloat
    /// Target active width
    let width: CGFloat
    /// Optional preview width used during warmup (telegraph). Defaults to 30% of width.
    let previewWidth: CGFloat?
    let duration: TimeInterval
    /// Telegraph duration before the beam becomes active
    let warmup: TimeInterval
    /// Fade out tail duration
    let fadeOut: TimeInterval
    /// Optional delay before warmup begins (for staggered multi-beam telegraphs)
    let startDelay: TimeInterval
    /// Optional absolute activation time (seconds since spawn) to force simultaneous activation
    /// If nil, activation happens immediately after warmup.
    let activationOverride: TimeInterval?
    let color: BulletColor
    let damage: Int
    let tickInterval: TimeInterval
    let anchor: GKEntity?
    
    init(position: CGPoint,
         angle: CGFloat,
         length: CGFloat,
         width: CGFloat,
         previewWidth: CGFloat? = nil,
         duration: TimeInterval = 1.0,
         warmup: TimeInterval = 0.1,
         fadeOut: TimeInterval = 0.2,
         startDelay: TimeInterval = 0.0,
         activationOverride: TimeInterval? = nil,
         color: BulletColor = .red,
         damage: Int = 1,
         tickInterval: TimeInterval = 0.15,
         anchor: GKEntity? = nil) {
        self.position = position
        self.angle = angle
        self.length = length
        self.width = width
        self.previewWidth = previewWidth
        self.duration = duration
        self.warmup = warmup
        self.fadeOut = fadeOut
        self.startDelay = startDelay
        self.activationOverride = activationOverride
        self.color = color
        self.damage = damage
        self.tickInterval = tickInterval
        self.anchor = anchor
    }
}
