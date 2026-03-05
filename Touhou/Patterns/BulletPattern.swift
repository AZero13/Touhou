//
//  BulletPattern.swift
//  Touhou
//

import Foundation
import CoreGraphics

/// A bullet pattern that runs over time, producing commands each frame.
protocol BulletPattern {
    /// Called each frame. Returns commands to spawn this frame.
    mutating func update(
        dt: TimeInterval, 
        position: CGPoint, 
        target: CGPoint?
    ) -> PatternOutput
    
    /// Whether this pattern has finished its sequence.
    var isComplete: Bool { get }
    
    /// Reset to start the pattern over.
    mutating func reset()
}

struct PatternOutput {
    var bullets: [BulletSpawnCommand] = []
    var lasers: [LaserSpawnCommand] = []
    
    mutating func append(bullets: [BulletSpawnCommand]) {
        self.bullets.append(contentsOf: bullets)
    }
    
    mutating func append(lasers: [LaserSpawnCommand]) {
        self.lasers.append(contentsOf: lasers)
    }
}
