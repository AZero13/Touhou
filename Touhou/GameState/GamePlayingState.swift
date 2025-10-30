//
//  GamePlayingState.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

/// Playing state - normal gameplay
class GamePlayingState: GKState {
    unowned let gameFacade: GameFacade
    
    init(gameFacade: GameFacade) {
        self.gameFacade = gameFacade
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        print("Entered Playing state")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        let input = InputManager.shared.getCurrentInput()
        
        // Check for pause input (Escape key edge detection)
        if input.pause.justPressed {
            stateMachine?.enter(GamePausedState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GamePausedState.self
    }
}

