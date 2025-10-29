//
//  InputState.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import CoreGraphics

/// Unified input state for both keyboard and controller
/// Uses ButtonState to encapsulate button press state and edge detection
struct InputState {
    // Continuous movement input (for player movement)
    var movement: CGVector
    
    // Action buttons (encapsulated in ButtonState)
    var shoot: ButtonState
    var bomb: ButtonState
    var focus: ButtonState  // Currently just a bool for hold, but could be ButtonState if needed
    var pause: ButtonState
    var enter: ButtonState
    
    // Menu navigation buttons
    var up: ButtonState
    var down: ButtonState
    
    init() {
        self.movement = CGVector.zero
        self.shoot = ButtonState()
        self.bomb = ButtonState()
        self.focus = ButtonState()
        self.pause = ButtonState()
        self.enter = ButtonState()
        self.up = ButtonState()
        self.down = ButtonState()
    }
}

