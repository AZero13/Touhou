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
    private var highScore: Int = 0
    private let highScoreStore = UserDefaultsHighScoreStore()
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
        // Initialize session high score from current player score (likely 0)
        self.highScore = entityManager.getPlayerComponent()?.score ?? 0
    }
    
    func update(deltaTime: TimeInterval) {
        // No per-frame work needed
    }
    
    func handleEvent(_ event: GameEvent) {
        switch event {
        case let e as EnemyDiedEvent:
            // Add score via CombatFacade
            GameFacade.shared.combat.adjustScore(amount: e.scoreValue)
            
        case let g as GrazeEvent:
            // Increment graze count for pointBullet value calculation
            if let playerComp = entityManager.getPlayerComponent() {
                playerComp.grazeInStage += g.grazeValue
            }
            GameFacade.shared.combat.adjustScore(amount: g.grazeValue)
            
        case let p as PowerUpCollectedEvent:
            handlePowerUpCollection(p)
            
        case let s as ScoreChangedEvent:
            // Maintain high score when score changes
            if s.newTotal > highScore {
                highScore = s.newTotal
                eventBus.fire(HighScoreChangedEvent(newHighScore: highScore))
            }
            
        case let st as StageStartedEvent:
            // Reset run high score only at the beginning of a new run (stage 1)
            if st.stageId == 1 {
                self.highScore = entityManager.getPlayerComponent()?.score ?? 0
                eventBus.fire(HighScoreChangedEvent(newHighScore: highScore))
            }
            
        case is GameOverEvent:
            // Persist best-of-all-time after a run ends (loss)
            persistIfNewBest()
            
        case let se as StageEndedEvent:
            // Persist best-of-all-time at the end of the final stage (win)
            if se.stageId >= GameFacade.maxStage {
                persistIfNewBest()
            }
            
        default:
            // Ignore other events
            break
        }
    }
    
    private func handlePowerUpCollection(_ p: PowerUpCollectedEvent) {
        guard let playerComp = entityManager.getPlayerComponent() else { return }
        
        switch p.itemType {
        case .point:
            GameFacade.shared.combat.adjustScore(amount: p.value)
            
        case .power:
            // TH06: At full power, power items give score instead
            if playerComp.power >= 128 {
                // TH06: Increment count FIRST, then calculate score
                playerComp.powerItemCountForScore += 1
                // Cap at 30 (TH06 behavior)
                if playerComp.powerItemCountForScore > 30 {
                    playerComp.powerItemCountForScore = 30
                }
                // Calculate score based on NEW count (TH06 table)
                let powerItemScores: [Int] = [
                    10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
                    200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000,
                    3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 51200
                ]
                // Use safe subscript to prevent out-of-bounds access
                let actualScore = powerItemScores[safe: playerComp.powerItemCountForScore] ?? 51200
                GameFacade.shared.combat.adjustScore(amount: actualScore)
            } else {
                // Not at full power: increase power by 1, base score 10
                GameFacade.shared.combat.adjustPower(delta: 1)
                GameFacade.shared.combat.adjustScore(amount: p.value)
            }
            
        case .pointBullet:
            // Special bullet-to-point conversion item
            GameFacade.shared.combat.adjustScore(amount: p.value)
            
        case .bomb:
            if playerComp.bombs < 8 {
                GameFacade.shared.combat.adjustBombs(delta: 1)
            }
            
        case .life:
            GameFacade.shared.combat.adjustLives(delta: 1)
        }
    }
    
    private func persistIfNewBest() {
        let stored = highScoreStore.loadHighScore()
        if highScore > stored { highScoreStore.saveHighScore(highScore) }
    }
}


