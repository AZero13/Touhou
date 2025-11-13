//
//  BossComponent.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

/// BossComponent - marks an enemy as a boss (for special handling)
/// Bosses don't despawn when stage clears, have special health bars, etc.
final class BossComponent: GKComponent {
    let name: String
    var phaseNumber: Int
    
    // Time bonus system (for midbosses)
    var hasTimeBonus: Bool
    var timeLimit: TimeInterval
    var elapsedTime: TimeInterval = 0
    var bonusPointsBase: Int
    
    init(name: String, phaseNumber: Int = 1, hasTimeBonus: Bool = false, timeLimit: TimeInterval = 20.0, bonusPointsBase: Int = 10000) {
        self.name = name
        self.phaseNumber = phaseNumber
        self.hasTimeBonus = hasTimeBonus
        self.timeLimit = timeLimit
        self.bonusPointsBase = bonusPointsBase
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Calculate time bonus based on remaining time
    func calculateTimeBonus() -> Int {
        guard hasTimeBonus else { return 0 }
        let remainingTime = max(0, timeLimit - elapsedTime)
        let bonusRatio = remainingTime / timeLimit
        return Int(Double(bonusPointsBase) * bonusRatio)
    }
    
    /// Check if time has run out (no bonus)
    var isTimeExpired: Bool {
        return hasTimeBonus && elapsedTime >= timeLimit
    }
    
    override func update(deltaTime: TimeInterval) {
        if hasTimeBonus {
            elapsedTime += deltaTime
            
            // When time expires, trigger escape
            if isTimeExpired && entity != nil {
                handleTimeExpired()
            }
        }
    }
    
    private func handleTimeExpired() {
        guard let entity = entity else { return }
        
        // Make midboss leave offscreen
        if let transform = entity.component(ofType: TransformComponent.self) {
            let exitPosition = CGPoint(x: GameFacade.playArea.midX, y: 500)
            transform.moveTo(position: exitPosition, duration: 1.5)
        }
        
        // Fire event for "FAILED" text
        if let transform = entity.component(ofType: TransformComponent.self) {
            GameFacade.shared.fireEvent(TimeBonusFailedEvent(
                bossName: name,
                position: transform.position
            ))
        }
        
        // Mark as no longer having time bonus (prevent repeated triggers)
        hasTimeBonus = false
    }
}


