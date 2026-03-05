//
//  StatefulPatterns.swift
//  Touhou
//
//  Created by Antigravity on 11/27/25.
//

import Foundation
import CoreGraphics

/// A pattern that shoots a single bullet straight down at regular intervals.
struct SingleShotPattern: BulletPattern, Sendable {
    private var timer: TimeInterval = 0
    let interval: TimeInterval
    let config: PatternConfig
    
    init(interval: TimeInterval, config: PatternConfig = PatternConfig()) {
        self.interval = interval
        self.config = config
    }
    
    mutating func update(dt: TimeInterval, position: CGPoint, target: CGPoint?) -> PatternOutput {
        timer += dt
        var output = PatternOutput()
        
        if timer >= interval {
            timer -= interval
            output.bullets.append(
                BulletSpawnCommand(
                    position: position,
                    velocity: CGVector(dx: 0, dy: -config.physics.speed),
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: config.visual,
                    behavior: config.behavior
                )
            )
        }
        
        return output
    }
    
    var isComplete: Bool { false }
    mutating func reset() { timer = 0 }
}

/// A pattern that shoots three bullets in a spread.
struct TripleShotPattern: BulletPattern, Sendable {
    private var timer: TimeInterval = 0
    let interval: TimeInterval
    let config: PatternConfig
    
    init(interval: TimeInterval, config: PatternConfig = PatternConfig()) {
        self.interval = interval
        self.config = config
    }
    
    mutating func update(dt: TimeInterval, position: CGPoint, target: CGPoint?) -> PatternOutput {
        timer += dt
        var output = PatternOutput()
        
        if timer >= interval {
            timer -= interval
            let spread = config.spread
            let speed = config.physics.speed
            
            output.bullets.append(contentsOf: [
                makeBullet(position: position, velocity: CGVector(dx: 0, dy: -speed)),
                makeBullet(position: position, velocity: CGVector(dx: -spread, dy: -speed * 0.8)),
                makeBullet(position: position, velocity: CGVector(dx: spread, dy: -speed * 0.8))
            ])
        }
        
        return output
    }
    
    private func makeBullet(position: CGPoint, velocity: CGVector) -> BulletSpawnCommand {
        BulletSpawnCommand(
            position: position,
            velocity: velocity,
            bulletType: .enemyBullet,
            physics: config.physics,
            visual: config.visual,
            behavior: config.behavior
        )
    }
    
    var isComplete: Bool { false }
    mutating func reset() { timer = 0 }
}

/// A pattern that shoots bullets in a full circle.
struct CircleShotPattern: BulletPattern, Sendable {
    private var timer: TimeInterval = 0
    let interval: TimeInterval
    let config: PatternConfig
    
    init(interval: TimeInterval, config: PatternConfig = PatternConfig()) {
        self.interval = interval
        self.config = config
    }
    
    mutating func update(dt: TimeInterval, position: CGPoint, target: CGPoint?) -> PatternOutput {
        timer += dt
        var output = PatternOutput()
        
        if timer >= interval {
            timer -= interval
            let bulletCount = config.bulletCount
            let speed = config.physics.speed
            
            for i in 0..<bulletCount {
                let angle = (CGFloat.pi * 2 * CGFloat(i)) / CGFloat(bulletCount)
                let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                output.bullets.append(
                    BulletSpawnCommand(
                        position: position,
                        velocity: velocity,
                        bulletType: .enemyBullet,
                        physics: config.physics,
                        visual: config.visual,
                        behavior: config.behavior
                    )
                )
            }
        }
        
        return output
    }
    
    var isComplete: Bool { false }
    mutating func reset() { timer = 0 }
}

/// A pattern that predicts and shoots at a target.
struct AimedShotPattern: BulletPattern, Sendable {
    private var timer: TimeInterval = 0
    let interval: TimeInterval
    let config: PatternConfig
    
    init(interval: TimeInterval, config: PatternConfig = PatternConfig()) {
        self.interval = interval
        self.config = config
    }
    
    mutating func update(dt: TimeInterval, position: CGPoint, target: CGPoint?) -> PatternOutput {
        timer += dt
        var output = PatternOutput()
        
        if timer >= interval {
            timer -= interval
            
            let velocity: CGVector
            if let target = target {
                velocity = MathUtility.velocity(from: position, to: target, speed: config.physics.speed)
            } else {
                velocity = CGVector(dx: 0, dy: -config.physics.speed)
            }
            
            output.bullets.append(
                BulletSpawnCommand(
                    position: position,
                    velocity: velocity,
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: config.visual,
                    behavior: config.behavior
                )
            )
        }
        
        return output
    }
    
    var isComplete: Bool { false }
    mutating func reset() { timer = 0 }
}

/// A pattern that shoots complex spiral waves.
struct SpiralShotPattern: BulletPattern, Sendable {
    private var timer: TimeInterval = 0
    let interval: TimeInterval
    let config: PatternConfig
    private var angleOffset: CGFloat = 0
    
    init(interval: TimeInterval, config: PatternConfig = PatternConfig()) {
        self.interval = interval
        self.config = config
    }
    
    mutating func update(dt: TimeInterval, position: CGPoint, target: CGPoint?) -> PatternOutput {
        timer += dt
        var output = PatternOutput()
        
        if timer >= interval {
            timer -= interval
            let bulletCount = config.bulletCount
            let baseSpeed = config.physics.speed
            
            for i in 0..<bulletCount {
                let angle = (CGFloat.pi * 2 * CGFloat(i)) / CGFloat(bulletCount) + angleOffset
                let speed = baseSpeed + CGFloat(i) * config.spiralSpeed
                let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                
                output.bullets.append(
                    BulletSpawnCommand(
                        position: position,
                        velocity: velocity,
                        bulletType: .enemyBullet,
                        physics: config.physics,
                        visual: config.visual,
                        behavior: config.behavior
                    )
                )
            }
            
            angleOffset += 0.2 // Rotate slightly each burst
        }
        
        return output
    }
    
    var isComplete: Bool { false }
    mutating func reset() { 
        timer = 0
        angleOffset = 0
    }
}
