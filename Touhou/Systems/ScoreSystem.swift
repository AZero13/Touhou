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
    private let highScoreStore: HighScoreStore
    
    init(highScoreStore: HighScoreStore = UserDefaultsHighScoreStore()) {
        self.highScoreStore = highScoreStore
    }
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
        self.highScore = highScoreStore.loadHighScore()
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
                highScoreStore.saveHighScore(highScore)
            }
        }
    }
}


