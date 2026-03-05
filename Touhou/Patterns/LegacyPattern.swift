//
//  LegacyPattern.swift
//  Touhou
//

import Foundation
import CoreGraphics

/// A wrapper to easily adapt existing EnemyPattern enum cases into BulletPatterns
struct LegacyPattern: BulletPattern {
    let pattern: EnemyPattern
    let config: PatternConfig
    let interval: TimeInterval
    private var timer: TimeInterval = 0
    
    init(pattern: EnemyPattern, config: PatternConfig = PatternConfig(), interval: TimeInterval = 2.0) {
        self.pattern = pattern
        self.config = config
        self.interval = interval
        self.timer = interval - 0.1 // Shoot almost immediately on spawn
    }
    
    mutating func update(dt: TimeInterval, position: CGPoint, target: CGPoint?) -> PatternOutput {
        timer += dt
        var output = PatternOutput()
        
        if timer >= interval {
            timer -= interval
            output.bullets = pattern.getBulletCommands(from: position, targetPosition: target, config: config)
            output.lasers = pattern.getLaserCommands(from: position, targetPosition: target, config: config)
        }
        
        return output
    }
    
    var isComplete: Bool { return false }
    
    mutating func reset() {
        timer = interval - 0.1
    }
}

struct EmptyPattern: BulletPattern {
    mutating func update(dt: TimeInterval, position: CGPoint, target: CGPoint?) -> PatternOutput { return PatternOutput() }
    var isComplete: Bool { return true }
    mutating func reset() {}
}
