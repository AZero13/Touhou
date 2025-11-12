//
//  TransformComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// TransformComponent - handles entity position, velocity, and rotation
final class TransformComponent: GKComponent {
    var position: CGPoint
    var velocity: CGVector
    var rotation: CGFloat = 0
    
    // Target-based movement (for bosses)
    var targetPosition: CGPoint?
    var movementDuration: TimeInterval = 0
    var movementElapsed: TimeInterval = 0
    private var moveStartPosition: CGPoint?
    
    init(position: CGPoint, velocity: CGVector = CGVector.zero, rotation: CGFloat = 0) {
        self.position = position
        self.velocity = velocity
        self.rotation = rotation
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Move to a target position over a duration (used by bosses)
    func moveTo(position: CGPoint, duration: TimeInterval) {
        self.moveStartPosition = self.position
        self.targetPosition = position
        self.movementDuration = duration
        self.movementElapsed = 0
        self.velocity = .zero // Stop constant velocity while moving to target
    }
    
    /// Update target-based movement
    func updateTargetMovement(deltaTime: TimeInterval) {
        guard let target = targetPosition, let start = moveStartPosition else { return }
        
        movementElapsed += deltaTime
        let progress = min(movementElapsed / movementDuration, 1.0)
        
        // Linear interpolation
        position.x = start.x + (target.x - start.x) * progress
        position.y = start.y + (target.y - start.y) * progress
        
        // Clear target when movement complete
        if progress >= 1.0 {
            targetPosition = nil
            moveStartPosition = nil
        }
    }
    
    var isMovingToTarget: Bool {
        return targetPosition != nil
    }
}
