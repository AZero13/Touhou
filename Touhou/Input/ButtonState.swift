//
//  ButtonState.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation

/// Encapsulates button state with edge detection
/// Tracks both current pressed state and whether it was just pressed this frame
struct ButtonState {
    /// Whether the button is currently pressed/held
    var isPressed: Bool
    
    /// Whether the button was just pressed this frame (edge detection)
    var justPressed: Bool
    
    init(isPressed: Bool = false, justPressed: Bool = false) {
        self.isPressed = isPressed
        self.justPressed = justPressed
    }
    
    /// Update state from current press state and previous state
    /// Call this once per frame with the current press state and previous ButtonState
    static func update(currentPressed: Bool, previousState: ButtonState) -> ButtonState {
        return ButtonState(
            isPressed: currentPressed,
            justPressed: currentPressed && !previousState.isPressed
        )
    }
}

