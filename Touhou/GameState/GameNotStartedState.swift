//
//  GameNotStartedState.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

/// NotStarted state - initial state before game begins
class GameNotStartedState: GKState {
    unowned let gameFacade: GameFacade
    
    init(gameFacade: GameFacade) {
        self.gameFacade = gameFacade
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        print("Game not started")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        // Do nothing - wait for startGame() to transition
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GamePlayingState.self
    }
}

