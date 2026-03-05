//
//  ScoreSystem.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

final class ScoreSystem: GameSystem {
    private weak var engine: GameEngine!
    private var highScore: Int = 0
    private let highScoreStore = UserDefaultsHighScoreStore()
    
    func initialize(engine: GameEngine) {
        self.engine = engine
        self.highScore = engine.entityManager.getPlayerComponent()?.score ?? 0
    }
    
    func update(deltaTime: TimeInterval) {
    }
    
    func handleEvent(_ event: GameEvent) {
        switch event {
        case let e as EnemyDiedEvent:
            engine.addScore(e.scoreValue)
        case let g as GrazeEvent:
            if let playerComp = engine.entityManager.getPlayerComponent() {
                playerComp.grazeInStage += g.grazeValue
            }
            engine.addScore(g.grazeValue)
        case let p as PowerUpCollectedEvent:
            handlePowerUpCollection(p)
        case let s as ScoreChangedEvent:
            if s.newTotal > highScore {
                highScore = s.newTotal
                engine.fireEvent(HighScoreChangedEvent(newHighScore: highScore))
            }
        case let st as StageStartedEvent:
            if st.stageId == 1 {
                self.highScore = engine.entityManager.getPlayerComponent()?.score ?? 0
                engine.fireEvent(HighScoreChangedEvent(newHighScore: highScore))
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
        guard let playerComp = engine.entityManager.getPlayerComponent() else { return }
        
        switch p.itemType {
        case .point:
            engine.addScore(p.value)
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
                let actualScore = powerItemScores[playerComp.powerItemCountForScore]
                engine.addScore(actualScore)
            } else {
                engine.gainPower(1)
                engine.addScore(p.value)
            }
        case .pointBullet:
            engine.addScore(p.value)
        case .bomb:
            if playerComp.bombs < 8 {
                engine.gainBombs(1)
            }
        case .life:
            engine.gainLives(1)
        }
    }
    
    private func persistIfNewBest() {
        let stored = highScoreStore.loadHighScore()
        if highScore > stored { highScoreStore.saveHighScore(highScore) }
    }
}
