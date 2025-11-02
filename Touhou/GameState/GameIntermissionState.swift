//
//  GameIntermissionState.swift
//  Touhou
//
//  Created by Rose on 10/31/25.
//

import Foundation
import GameplayKit

/// Intermission state - shown between stages (score screen, music fades, confirm to continue)
final class GameIntermissionState: GKState {
    unowned let gameFacade: GameFacade
    
    init(gameFacade: GameFacade) {
        self.gameFacade = gameFacade
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        // Announce transition for UI (score screen) and audio fades
        // Still needs direct EventBus access as facades don't cover all events yet
        if let next = gameFacade.getPendingNextStageId() {
            gameFacade.getEventBus().fire(StageTransitionEvent(nextStageId: next))
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        // Only listen for confirm inputs; gameplay systems do not tick in this state
        let input = InputManager.shared.getCurrentInput()
        if input.enter.justPressed || input.shoot.justPressed {
            guard let next = gameFacade.getPendingNextStageId() else { return }
            if next > GameFacade.maxStage {
                // End-of-run win handling: ViewController presents win scene
                gameFacade.endStage()
            } else {
                gameFacade.startStage(stageId: next)
            }
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GamePlayingState.self || stateClass == GameNotStartedState.self
    }
}


