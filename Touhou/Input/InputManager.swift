//
//  InputManager.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import AppKit
import GameController

/// InputManager - handles both keyboard and gamepad input
@MainActor
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
        
        // Update button states with edge detection (use previous frame's state)
        input.shoot = ButtonState.update(currentPressed: input.shoot.isPressed, previousState: currentInput.shoot)
        input.bomb = ButtonState.update(currentPressed: input.bomb.isPressed, previousState: currentInput.bomb)
        input.pause = ButtonState.update(currentPressed: input.pause.isPressed, previousState: currentInput.pause)
        input.enter = ButtonState.update(currentPressed: input.enter.isPressed, previousState: currentInput.enter)
        input.up = ButtonState.update(currentPressed: input.up.isPressed, previousState: currentInput.up)
        input.down = ButtonState.update(currentPressed: input.down.isPressed, previousState: currentInput.down)
        // Focus doesn't need edge detection, it's a hold button
        input.focus = ButtonState(isPressed: input.focus.isPressed, justPressed: false)
        
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
        
        // Menu navigation (discrete key presses)
        input.up = ButtonState(isPressed: keyboardState.contains(126))  // Up arrow
        input.down = ButtonState(isPressed: keyboardState.contains(125))  // Down arrow
        
        // Action keys
        input.shoot = ButtonState(isPressed: keyboardState.contains(6))  // Z key
        input.bomb = ButtonState(isPressed: keyboardState.contains(7))    // X key
        input.focus = ButtonState(isPressed: keyboardState.contains(56)) // Shift key
        input.pause = ButtonState(isPressed: keyboardState.contains(53)) // Esc key
        input.enter = ButtonState(isPressed: keyboardState.contains(36)) // Enter key
    }
    
    private func processControllerInput(_ input: inout InputState) {
        guard let controller = GCController.controllers().first else { return }
        
        // D-Pad or Left Stick
        if let dpad = controller.extendedGamepad?.dpad {
            input.movement.dx = CGFloat(dpad.xAxis.value)
            input.movement.dy = CGFloat(dpad.yAxis.value)
            // Menu navigation (discrete)
            input.up = ButtonState(isPressed: dpad.up.isPressed)
            input.down = ButtonState(isPressed: dpad.down.isPressed)
        } else if let leftStick = controller.extendedGamepad?.leftThumbstick {
            input.movement.dx = CGFloat(leftStick.xAxis.value)
            input.movement.dy = CGFloat(leftStick.yAxis.value)
            // For menu: treat stick up/down as discrete presses if beyond threshold
            input.up = ButtonState(isPressed: leftStick.yAxis.value > 0.5)
            input.down = ButtonState(isPressed: leftStick.yAxis.value < -0.5)
        }
        
        // Face buttons
        if let gamepad = controller.extendedGamepad {
            input.shoot = ButtonState(isPressed: gamepad.buttonA.isPressed)
            input.bomb = ButtonState(isPressed: gamepad.buttonB.isPressed)
            input.focus = ButtonState(isPressed: gamepad.leftTrigger.isPressed || gamepad.rightTrigger.isPressed)
            input.pause = ButtonState(isPressed: gamepad.buttonMenu.isPressed)
        }
    }
    
    // MARK: - Public Interface
    func getCurrentInput() -> InputState {
        return currentInput
    }
    
    // MARK: - Cleanup
    deinit {
        // Remove NotificationCenter observers to prevent crashes if notifications are posted after deallocation
        NotificationCenter.default.removeObserver(self)
    }
}
