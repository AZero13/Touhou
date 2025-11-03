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
