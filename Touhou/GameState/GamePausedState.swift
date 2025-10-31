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
    case close = 0  // Resume/Continue
    case restart = 1
}

/// Paused state - pause menu with Close/Restart options
class GamePausedState: GKState {
    unowned let gameFacade: GameFacade
    private var selectedOption: PauseMenuOption = .close
    
    init(gameFacade: GameFacade) {
        self.gameFacade = gameFacade
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        selectedOption = .close // Reset to Close on pause
        print("Entered Paused state")
        gameFacade.getEventBus().fire(GamePausedEvent())
        fireMenuUpdateEvent()
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        let input = InputManager.shared.getCurrentInput()
        
        // Handle pause menu navigation with discrete key presses
        if input.up.justPressed {
            if selectedOption != .close {
                selectedOption = .close
                print("Menu: Close selected")
                fireMenuUpdateEvent()
            }
        } else if input.down.justPressed {
            if selectedOption != .restart {
                selectedOption = .restart
                print("Menu: Restart selected")
                fireMenuUpdateEvent()
            }
        }
        
        // Handle selection with Enter or Z (edge detected)
        if input.enter.justPressed || input.shoot.justPressed {
            handleSelection()
        }
        
        // Escape to unpause (only if Close selected)
        if input.pause.justPressed && selectedOption == .close {
            stateMachine?.enter(GamePlayingState.self)
        }
    }
    
    private func handleSelection() {
        switch selectedOption {
        case .close:
            stateMachine?.enter(GamePlayingState.self)
        case .restart:
            gameFacade.startNewRun()
            stateMachine?.enter(GamePlayingState.self)
        }
    }
    
    private func fireMenuUpdateEvent() {
        gameFacade.getEventBus().fire(PauseMenuUpdateEvent(selectedOption: selectedOption))
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GamePlayingState.self
    }
    
    override func willExit(to nextState: GKState) {
        print("Exiting Paused state")
        gameFacade.getEventBus().fire(PauseMenuHiddenEvent())
        gameFacade.getEventBus().fire(GameResumedEvent())
    }
    
    func getSelectedOption() -> PauseMenuOption {
        return selectedOption
    }
}

