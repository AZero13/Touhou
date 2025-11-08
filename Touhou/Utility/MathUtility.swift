//
//  MathUtility.swift
//  Touhou
//
//  Created by Rose on 11/01/25.
//

import Foundation
import CoreGraphics

enum MathUtility {
    @inlinable
    static func angle(from: CGPoint, to: CGPoint) -> CGFloat {
        atan2(to.y - from.y, to.x - from.x)
    }
    
    @inlinable
    static func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return sqrt(dx * dx + dy * dy)
    }
    
    @inlinable
    static func distanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return dx * dx + dy * dy
    }
    
    @inlinable
    static func normalize(_ vector: CGVector) -> CGVector? {
        let length = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        guard length > 0 else { return nil }
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }
    
    @inlinable
    static func magnitude(_ vector: CGVector) -> CGFloat {
        sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
    }
    
    @inlinable
    static func velocity(angle: CGFloat, speed: CGFloat) -> CGVector {
        CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
    }
    
    @inlinable
    static func angle(of vector: CGVector) -> CGFloat {
        atan2(vector.dy, vector.dx)
    }
    
    @inlinable
    static func normalizeAngle(_ angle: CGFloat) -> CGFloat {
        var normalized = angle
        while normalized > .pi { normalized -= 2 * .pi }
        while normalized < -.pi { normalized += 2 * .pi }
        return normalized
    }
    
    @inlinable
    static func angleDifference(from: CGFloat, to: CGFloat) -> CGFloat {
        normalizeAngle(to - from)
    }
    
    @inlinable
    static func velocity(from: CGPoint, to: CGPoint, speed: CGFloat) -> CGVector {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 0 else { return CGVector.zero }
        return CGVector(dx: (dx / distance) * speed, dy: (dy / distance) * speed)
    }
}
