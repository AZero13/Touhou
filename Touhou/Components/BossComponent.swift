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
    
    // Multi-phase system (for bosses with multiple health bars/lives)
    var totalPhases: Int = 1  // Total number of phases (health bars)
    var currentPhase: Int = 1  // Current phase (1-indexed)
    var phaseHealths: [Int] = []  // Max health for each phase
    var currentPhaseHealth: Int = 0  // Current health of the current phase
    
    // Time bonus system (for midbosses)
    var hasTimeBonus: Bool
    var timeLimit: TimeInterval
    var elapsedTime: TimeInterval = 0
    var bonusPointsBase: Int
    
    // Defeat state
    var isDefeated: Bool = false
    
    // Movement pattern (for bosses with scheduled movements)
    struct MovementStep {
        let position: CGPoint
        let delay: TimeInterval  // Time to wait before moving to this position
        let duration: TimeInterval  // How long to take to reach this position
    }
    var movementPattern: [MovementStep] = []
    var movementPatternStartTime: TimeInterval = 0
    var movementPatternIndex: Int = 0
    
    init(name: String, phaseNumber: Int = 1, hasTimeBonus: Bool = false, timeLimit: TimeInterval = 20.0, bonusPointsBase: Int = 10000, totalPhases: Int = 1, phaseHealths: [Int] = []) {
        self.name = name
        self.phaseNumber = phaseNumber
        self.hasTimeBonus = hasTimeBonus
        self.timeLimit = timeLimit
        self.bonusPointsBase = bonusPointsBase
        self.totalPhases = totalPhases
        self.currentPhase = 1
        self.phaseHealths = phaseHealths.isEmpty ? [300] : phaseHealths  // Default to single phase with 300 health
        self.currentPhaseHealth = self.phaseHealths.first ?? 300
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
        // Stop updating when defeated
        guard !isDefeated else { return }
        
        // Update movement pattern if one exists
        updateMovementPattern(deltaTime: deltaTime)
        
        if hasTimeBonus {
            elapsedTime += deltaTime
            
            // When time expires, trigger escape
            if isTimeExpired && entity != nil {
                handleTimeExpired()
            }
        }
    }
    
    private func updateMovementPattern(deltaTime: TimeInterval) {
        guard !movementPattern.isEmpty,
              let transform = entity?.component(ofType: TransformComponent.self),
              movementPatternIndex < movementPattern.count else { return }
        
        // Calculate elapsed time since pattern started
        let currentTime = CACurrentMediaTime()
        if movementPatternStartTime == 0 {
            movementPatternStartTime = currentTime
        }
        let patternElapsed = currentTime - movementPatternStartTime
        
        // Calculate cumulative delay up to current step
        var cumulativeDelay: TimeInterval = 0
        for i in 0..<movementPatternIndex {
            cumulativeDelay += movementPattern[i].delay
        }
        
        // Check if it's time to start moving to the next position
        let step = movementPattern[movementPatternIndex]
        let stepStartTime = cumulativeDelay
        
        if patternElapsed >= stepStartTime && !transform.isMovingToTarget {
            // Time to start this movement
            transform.moveTo(position: step.position, duration: step.duration)
        }
        
        // Check if we should advance to next step (current movement complete + delay elapsed)
        let stepCompleteTime = stepStartTime + step.duration
        if patternElapsed >= stepCompleteTime && !transform.isMovingToTarget {
            movementPatternIndex += 1
        }
    }
    
    /// Set a movement pattern for the boss
    func setMovementPattern(_ pattern: [MovementStep]) {
        movementPattern = pattern
        movementPatternStartTime = CACurrentMediaTime()
        movementPatternIndex = 0
    }
    
    /// Clear movement pattern (e.g., when boss is defeated)
    func clearMovementPattern() {
        movementPattern = []
        movementPatternStartTime = 0
        movementPatternIndex = 0
    }
    
    private func handleTimeExpired() {
        guard let entity = entity else { return }
        
        // Make midboss leave offscreen (force movement even though time expired)
        if let transform = entity.component(ofType: TransformComponent.self) {
            let exitPosition = CGPoint(x: GameFacade.playArea.midX, y: 500)
            transform.moveTo(position: exitPosition, duration: 1.5, force: true)
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


