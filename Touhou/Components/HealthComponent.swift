//
//  HealthComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

final class HealthComponent: GKComponent {
    private var _health: Int
    
    var health: Int {
        get { _health }
        set {
            _health = max(0, min(newValue, maxHealth))
        }
    }
    
    var maxHealth: Int  // Mutable to support phase transitions
    var invulnerabilityTimer: TimeInterval = 0
    
    init(health: Int, maxHealth: Int, invulnerabilityTimer: TimeInterval = 0) {
        self._health = max(0, min(health, maxHealth))
        self.maxHealth = maxHealth
        self.invulnerabilityTimer = invulnerabilityTimer
        super.init()
    }
    
    /// Update max health (used for phase transitions)
    func updateMaxHealth(_ newMaxHealth: Int) {
        self.maxHealth = newMaxHealth
        // Clamp current health to new max
        if _health > newMaxHealth {
            _health = newMaxHealth
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @inlinable
    var isAlive: Bool {
        health > 0
    }
    
    @inlinable
    var isInvulnerable: Bool {
        invulnerabilityTimer > 0
    }
}
