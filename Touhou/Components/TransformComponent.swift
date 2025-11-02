//
//  TransformComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import CoreGraphics
import GameplayKit

// MARK: - Protocols

/// Protocol for entities that can move
protocol Movable {
    var position: CGPoint { get set }
    var velocity: CGVector { get set }
}

// MARK: - Component

/// TransformComponent - handles entity position, velocity, and rotation
final class TransformComponent: GKComponent, Movable {
    var position: CGPoint
    var velocity: CGVector
    var rotation: CGFloat = 0
    
    init(position: CGPoint, velocity: CGVector = CGVector.zero, rotation: CGFloat = 0) {
        self.position = position
        self.velocity = velocity
        self.rotation = rotation
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
