//
//  InputManager.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import AppKit
import GameController

/// Unified input state for both keyboard and controller
struct InputState {
    var movement: CGVector  // -1 to 1 for each axis
    var isShootPressed: Bool
    var isBombPressed: Bool
    var isFocusPressed: Bool
    var isPausePressed: Bool
    
    init() {
        self.movement = CGVector.zero
        self.isShootPressed = false
        self.isBombPressed = false
        self.isFocusPressed = false
        self.isPausePressed = false
    }
}

/// InputManager - handles both keyboard and gamepad input
class InputManager {
    static let shared = InputManager()
    
    private var currentInput = InputState()
    private var keyboardState: Set<UInt16> = []
    
    private init() {
        setupKeyboardMonitoring()
        setupControllerMonitoring()
    }
    
    // MARK: - Keyboard Setup
    private func setupKeyboardMonitoring() {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            self?.handleKeyboardEvent(event)
            return event
        }
    }
    
    private func handleKeyboardEvent(_ event: NSEvent) {
        let keyCode = event.keyCode
        let isKeyDown = event.type == .keyDown
        
        if isKeyDown {
            keyboardState.insert(keyCode)
        } else {
            keyboardState.remove(keyCode)
        }
    }
    
    // MARK: - Controller Setup
    private func setupControllerMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect),
            name: .GCControllerDidDisconnect,
            object: nil
        )
    }
    
    @objc private func controllerDidConnect(_ notification: Notification) {
        print("Controller connected")
    }
    
    @objc private func controllerDidDisconnect(_ notification: Notification) {
        print("Controller disconnected")
    }
    
    // MARK: - Input Processing
    func update() {
        var input = InputState()
        
        // Process keyboard input
        processKeyboardInput(&input)
        
        // Process controller input (if available)
        processControllerInput(&input)
        
        currentInput = input
    }
    
    private func processKeyboardInput(_ input: inout InputState) {
        var movement = CGVector.zero
        
        // Arrow keys
        if keyboardState.contains(123) { movement.dx -= 1 } // Left
        if keyboardState.contains(124) { movement.dx += 1 } // Right
        if keyboardState.contains(125) { movement.dy -= 1 } // Down
        if keyboardState.contains(126) { movement.dy += 1 } // Up
        
        input.movement = movement
        
        // Action keys
        input.isShootPressed = keyboardState.contains(6)  // Z key
        input.isBombPressed = keyboardState.contains(7)    // X key
        input.isFocusPressed = keyboardState.contains(56) // Shift key
        input.isPausePressed = keyboardState.contains(53) // Esc key
    }
    
    private func processControllerInput(_ input: inout InputState) {
        guard let controller = GCController.controllers().first else { return }
        
        // D-Pad or Left Stick
        if let dpad = controller.extendedGamepad?.dpad {
            input.movement.dx = CGFloat(dpad.xAxis.value)
            input.movement.dy = CGFloat(dpad.yAxis.value)
        } else if let leftStick = controller.extendedGamepad?.leftThumbstick {
            input.movement.dx = CGFloat(leftStick.xAxis.value)
            input.movement.dy = CGFloat(leftStick.yAxis.value)
        }
        
        // Face buttons
        if let gamepad = controller.extendedGamepad {
            input.isShootPressed = gamepad.buttonA.isPressed
            input.isBombPressed = gamepad.buttonB.isPressed
            input.isFocusPressed = gamepad.leftTrigger.isPressed || gamepad.rightTrigger.isPressed
            input.isPausePressed = gamepad.buttonMenu.isPressed
        }
    }
    
    // MARK: - Public Interface
    func getCurrentInput() -> InputState {
        return currentInput
    }
}
