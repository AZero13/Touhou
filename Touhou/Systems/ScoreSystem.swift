//
//  ScoreSystem.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

final class ScoreSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    private var highScore: Int = 0
    private let highScoreStore = UserDefaultsHighScoreStore()
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
        self.highScore = entityManager.getPlayerComponent()?.score ?? 0
    }
    
    func update(deltaTime: TimeInterval) {
    }
    
    func handleEvent(_ event: GameEvent) {
        switch event {
        case let e as EnemyDiedEvent:
            GameFacade.shared.combat.adjustScore(amount: e.scoreValue)
        case let g as GrazeEvent:
            if let playerComp = entityManager.getPlayerComponent() {
                playerComp.grazeInStage += g.grazeValue
            }
            GameFacade.shared.combat.adjustScore(amount: g.grazeValue)
        case let p as PowerUpCollectedEvent:
            handlePowerUpCollection(p)
        case let s as ScoreChangedEvent:
            if s.newTotal > highScore {
                highScore = s.newTotal
                eventBus.fire(HighScoreChangedEvent(newHighScore: highScore))
            }
        case let st as StageStartedEvent:
            if st.stageId == 1 {
                self.highScore = entityManager.getPlayerComponent()?.score ?? 0
                eventBus.fire(HighScoreChangedEvent(newHighScore: highScore))
            }
        case is GameOverEvent:
            persistIfNewBest()
        case let se as StageEndedEvent:
            if se.stageId >= GameFacade.maxStage {
                persistIfNewBest()
            }
        default:
            break
        }
    }
    
    private func handlePowerUpCollection(_ p: PowerUpCollectedEvent) {
        guard let playerComp = entityManager.getPlayerComponent() else { return }
        
        switch p.itemType {
        case .point:
            GameFacade.shared.combat.adjustScore(amount: p.value)
        case .power:
            if playerComp.power >= 128 {
                playerComp.powerItemCountForScore += 1
                if playerComp.powerItemCountForScore > 30 {
                    playerComp.powerItemCountForScore = 30
                }
                let powerItemScores = [
                    10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
                    200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000,
                    3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 51200
                ]
                let actualScore = powerItemScores[safe: playerComp.powerItemCountForScore] ?? 51200
                GameFacade.shared.combat.adjustScore(amount: actualScore)
            } else {
                GameFacade.shared.combat.adjustPower(delta: 1)
                GameFacade.shared.combat.adjustScore(amount: p.value)
            }
        case .pointBullet:
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
