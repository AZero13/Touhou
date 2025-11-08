//
//  MathUtility.swift
//  Touhou
//
//  Created by Assistant on 11/01/25.
//

import Foundation
import CoreGraphics

/// Centralized math utilities for angle, distance, and vector calculations
/// Eliminates code duplication across systems (like th06's math helpers)
enum MathUtility {
    /// Calculate angle from one point to another (in radians, 0 = right, π/2 = down)
    @inlinable
    static func angle(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return atan2(dy, dx)
    }
    
    /// Calculate distance between two points
    @inlinable
    static func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Calculate distance squared (faster, avoids sqrt for comparisons)
    @inlinable
    static func distanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return dx * dx + dy * dy
    }
    
    /// Normalize a vector (return unit vector with same direction)
    @inlinable
    static func normalize(_ vector: CGVector) -> CGVector? {
        let length = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        guard length > 0 else { return nil }
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }
    
    /// Get the magnitude (length) of a vector
    @inlinable
    static func magnitude(_ vector: CGVector) -> CGFloat {
        return sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
    }
    
    /// Create a velocity vector from angle and speed
    @inlinable
    static func velocity(angle: CGFloat, speed: CGFloat) -> CGVector {
        return CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
    }
    
    /// Get angle of a velocity vector
    @inlinable
    static func angle(of vector: CGVector) -> CGFloat {
        return atan2(vector.dy, vector.dx)
    }
    
    /// Normalize an angle to [-π, π] range
    @inlinable
    static func normalizeAngle(_ angle: CGFloat) -> CGFloat {
        var normalized = angle
        while normalized > .pi { normalized -= 2 * .pi }
        while normalized < -.pi { normalized += 2 * .pi }
        return normalized
    }
    
    /// Calculate angle difference between two angles, normalized to [-π, π]
    @inlinable
    static func angleDifference(from: CGFloat, to: CGFloat) -> CGFloat {
        return normalizeAngle(to - from)
    }
    
    /// Calculate velocity vector pointing from one point to another with specified speed
    @inlinable
    static func velocity(from: CGPoint, to: CGPoint, speed: CGFloat) -> CGVector {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 0 else { return CGVector.zero }
        return CGVector(dx: (dx / distance) * speed, dy: (dy / distance) * speed)
    }
}

