//
//  BossComponent.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

/// BossComponent - represents a boss enemy that can have spellcards, dialogue, and phases
/// Bosses can optionally conform to Spellcardable, Dialogueable, and Portraitable protocols
final class BossComponent: GKComponent, Phased {
    let name: String
    var maxHealth: Int
    var health: Int
    
    // Phased conformance
    var currentHealth: Int {
        get { return health }
        set { health = newValue }
    }
    
    var maxHealthForPhase: Int {
        return maxHealth
    }
    
    var phaseNumber: Int = 1
    
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


