//
//  BossComponent.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

// MARK: - Protocols

/// Protocol for entities that can execute spellcards
/// Bosses implement this to define spellcard phases and patterns
/// Uses GameFacade for simplified access to game systems
protocol Spellcardable {
    /// Unique identifier for this spellcard
    var spellcardId: String { get }
    /// Display name for this spellcard
    var spellcardName: String { get }
    /// Current phase index (0-based)
    var currentPhase: Int { get set }
    /// Total number of phases
    var phaseCount: Int { get }
    /// Duration of current phase in seconds
    var currentPhaseDuration: TimeInterval { get }
    /// Whether the spellcard is currently active
    var isActive: Bool { get set }
    
    /// Start executing the spellcard
    func startSpellcard(game: GameFacade)
    /// Update spellcard logic (called each frame while active)
    func updateSpellcard(deltaTime: TimeInterval, game: GameFacade)
    /// Advance to next phase or end spellcard
    func advancePhase(game: GameFacade)
    /// End the spellcard
    func endSpellcard(game: GameFacade)
}

// MARK: - Component

/// BossComponent - represents a boss enemy with health and phase tracking
/// Add DialogueComponent and PortraitComponent for dialogue/portrait capabilities
/// Implement Spellcardable for spellcard execution behavior
final class BossComponent: GKComponent {
    let name: String
    var maxHealth: Int
    var health: Int
    var phaseNumber: Int
    
    init(name: String, health: Int, phaseNumber: Int = 1) {
        self.name = name
        self.maxHealth = health
        self.health = health
        self.phaseNumber = phaseNumber
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


