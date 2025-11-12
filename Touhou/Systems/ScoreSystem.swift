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
    
    func initialize(context: GameRuntimeContext) {
        self.entityManager = context.entityManager
        self.eventBus = context.eventBus
        self.highScore = entityManager.getPlayerComponent()?.score ?? 0
    }
    
    func update(deltaTime: TimeInterval, context: GameRuntimeContext) {
    }
    
    func handleEvent(_ event: GameEvent, context: GameRuntimeContext) {
        switch event {
        case let e as EnemyDiedEvent:
            context.combat.addScore(e.scoreValue)
        case let g as GrazeEvent:
            if let playerComp = entityManager.getPlayerComponent() {
                playerComp.grazeInStage += g.grazeValue
            }
            context.combat.addScore(g.grazeValue)
        case let p as PowerUpCollectedEvent:
            handlePowerUpCollection(p, context: context)
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
    
    func handleEvent(_ event: GameEvent) {
        // Fallback for non-GameSystem listeners (shouldn't be called)
        fatalError("ScoreSystem.handleEvent without context should not be called")
    }
    
    private func handlePowerUpCollection(_ p: PowerUpCollectedEvent, context: GameRuntimeContext) {
        guard let playerComp = entityManager.getPlayerComponent() else { return }
        
        switch p.itemType {
        case .point:
            context.combat.addScore(p.value)
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
                context.combat.addScore(actualScore)
            } else {
                context.combat.gainPower(1)
                context.combat.addScore(p.value)
            }
        case .pointBullet:
            context.combat.addScore(p.value)
        case .bomb:
            if playerComp.bombs < 8 {
                context.combat.gainBombs(1)
            }
        case .life:
            context.combat.gainLives(1)
        }
    }
    
    private func persistIfNewBest() {
        let stored = highScoreStore.loadHighScore()
        if highScore > stored { highScoreStore.saveHighScore(highScore) }
    }
}
