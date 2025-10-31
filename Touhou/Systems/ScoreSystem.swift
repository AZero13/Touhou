//
//  ScoreSystem.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

/// ScoreSystem - updates player score and high score from events
final class ScoreSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    private var highScore: Int = 0 // session high score
    private let highScoreStore: HighScoreStore = UserDefaultsHighScoreStore()
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
        // Initialize session high score from current player score (likely 0)
        if let player = entityManager.getEntities(with: PlayerComponent.self).first,
           let playerComp = player.component(ofType: PlayerComponent.self) {
            self.highScore = playerComp.score
        } else {
            self.highScore = 0
        }
    }
    
    func update(deltaTime: TimeInterval) {
        // No per-frame work needed
    }
    
    func handleEvent(_ event: GameEvent) {
        if let e = event as? EnemyDiedEvent {
            // Add score via CommandQueue
            GameFacade.shared.getCommandQueue().enqueue(.adjustScore(amount: e.scoreValue))
        } else if let g = event as? GrazeEvent {
            GameFacade.shared.getCommandQueue().enqueue(.adjustScore(amount: g.grazeValue))
        } else if let p = event as? PowerUpCollectedEvent {
            if let player = entityManager.getEntities(with: PlayerComponent.self).first,
               let playerComp = player.component(ofType: PlayerComponent.self) {
                switch p.itemType {
                case .point:
                    GameFacade.shared.getCommandQueue().enqueue(.adjustScore(amount: p.value))
                case .power:
                    if playerComp.power < 128 {
                        // Full power: gain score defined in value
                        GameFacade.shared.getCommandQueue().enqueue(.adjustPower(delta: 1))
                    }
                    GameFacade.shared.getCommandQueue().enqueue(.adjustScore(amount: p.value))
                case .bomb:
                    if playerComp.bombs < 8 {
                        GameFacade.shared.getCommandQueue().enqueue(.adjustBombs(delta: 1))
                    }
                case .life:
                    GameFacade.shared.getCommandQueue().enqueue(.adjustLives(delta: 1))
                }
            }
        } else if let s = event as? ScoreChangedEvent {
            // Maintain high score when score changes
            if s.newTotal > highScore {
                highScore = s.newTotal
                eventBus.fire(HighScoreChangedEvent(newHighScore: highScore))
            }
        } else if let st = event as? StageStartedEvent {
            // Reset run high score only at the beginning of a new run (stage 1)
            if st.stageId == 1 {
                if let player = entityManager.getEntities(with: PlayerComponent.self).first,
                   let playerComp = player.component(ofType: PlayerComponent.self) {
                    self.highScore = playerComp.score
                } else {
                    self.highScore = 0
                }
                eventBus.fire(HighScoreChangedEvent(newHighScore: highScore))
            }
        } else if event is GameOverEvent {
            // Persist best-of-all-time after a run ends (loss)
            persistIfNewBest()
        } else if let se = event as? StageEndedEvent {
            // Persist best-of-all-time at the end of the final stage (win)
            if se.stageId >= GameFacade.maxStage {
                persistIfNewBest()
            }
        }
    }
    
    private func persistIfNewBest() {
        let stored = highScoreStore.loadHighScore()
        if highScore > stored { highScoreStore.saveHighScore(highScore) }
    }
}


