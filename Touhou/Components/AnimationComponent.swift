//
//  AnimationComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// AnimationComponent - handles animation state and frame tracking
final class AnimationComponent: GKComponent {
    var currentState: String // "idle", "moving", "shooting"
    var frameTimer: TimeInterval
    var frameIndex: Int
    
    init(currentState: String = "idle", frameTimer: TimeInterval = 0, frameIndex: Int = 0) {
        self.currentState = currentState
        self.frameTimer = frameTimer
        self.frameIndex = frameIndex
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
