//
//  GamePausedState.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

/// Pause menu option
enum PauseMenuOption: Int {
    case continueGame = 0
    case restart = 1
}

/// Paused state - pause menu with Continue/Restart options
class GamePausedState: GKState {
    unowned let gameFacade: GameFacade
    private var selectedOption: PauseMenuOption = .continueGame
    
    init(gameFacade: GameFacade) {
        self.gameFacade = gameFacade
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        selectedOption = .continueGame // Reset to Continue on pause
        print("⏸️ Entered Paused state")
        gameFacade.getEventBus().fire(GamePausedEvent())
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        let input = InputManager.shared.getCurrentInput()
        
        // Handle pause menu navigation
        if input.movement.dy > 0.5 { // Up
            // Move to Continue
            if selectedOption != .continueGame {
                selectedOption = .continueGame
                print("Menu: Continue selected")
            }
        } else if input.movement.dy < -0.5 { // Down
            // Move to Restart
            if selectedOption != .restart {
                selectedOption = .restart
                print("Menu: Restart selected")
            }
        }
        
        // Handle selection (Z key or A button)
        if input.isShootPressed {
            handleSelection()
        }
        
        // Escape to unpause (only if Continue selected)
        if input.isPauseJustPressed && selectedOption == .continueGame {
            stateMachine?.enter(GamePlayingState.self)
        }
    }
    
    private func handleSelection() {
        switch selectedOption {
        case .continueGame:
            stateMachine?.enter(GamePlayingState.self)
        case .restart:
            gameFacade.restartGame()
            stateMachine?.enter(GamePlayingState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GamePlayingState.self
    }
    
    override func willExit(to nextState: GKState) {
        print("▶️ Exiting Paused state")
        gameFacade.getEventBus().fire(GameResumedEvent())
    }
    
    func getSelectedOption() -> PauseMenuOption {
        return selectedOption
    }
}

