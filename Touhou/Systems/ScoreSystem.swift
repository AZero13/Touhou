//
//  ScoreSystem.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

/// ScoreSystem - updates player score and high score from events
class ScoreSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    private var highScore: Int = 0
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // No per-frame work needed
    }
    
    func handleEvent(_ event: GameEvent) {
        if let e = event as? EnemyDiedEvent {
            // Add score to player
            if let player = entityManager.getEntities(with: PlayerComponent.self).first,
               let playerComp = player.component(ofType: PlayerComponent.self) {
                playerComp.score += e.scoreValue
                eventBus.fire(ScoreChangedEvent(newTotal: playerComp.score))
                
                if playerComp.score > highScore {
                    highScore = playerComp.score
                    eventBus.fire(HighScoreChangedEvent(newHighScore: highScore))
                }
            }
        } else if let g = event as? GrazeEvent {
            if let player = entityManager.getEntities(with: PlayerComponent.self).first,
               let playerComp = player.component(ofType: PlayerComponent.self) {
                playerComp.score += g.grazeValue
                eventBus.fire(ScoreChangedEvent(newTotal: playerComp.score))
            }
        } else if let p = event as? PowerUpCollectedEvent {
            if let player = entityManager.getEntities(with: PlayerComponent.self).first,
               let playerComp = player.component(ofType: PlayerComponent.self) {
                switch p.itemType {
                case .point:
                    playerComp.score += p.value
                    eventBus.fire(ScoreChangedEvent(newTotal: playerComp.score))
                case .power:
                    playerComp.power = min(playerComp.power + p.value, 128)
                    eventBus.fire(PowerLevelChangedEvent(newTotal: playerComp.power))
                case .bomb:
                    playerComp.bombs += 1
                    eventBus.fire(BombsChangedEvent(newTotal: playerComp.bombs))
                case .life:
                    playerComp.lives += 1
                    eventBus.fire(LivesChangedEvent(newTotal: playerComp.lives))
                }
                if playerComp.score > highScore {
                    highScore = playerComp.score
                    eventBus.fire(HighScoreChangedEvent(newHighScore: highScore))
                }
            }
        }
    }
}


