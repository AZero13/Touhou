//
//  HealthComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// Protocol for entities that can take damage
protocol Damageable {
    var health: Int { get set }
    var maxHealth: Int { get }
    var isAlive: Bool { get }
    var invulnerabilityTimer: TimeInterval { get set }
}

class HealthComponent: GKComponent, Damageable {
    var current: Int
    var max: Int
    var invulnerabilityTimer: TimeInterval = 0
    
    init(current: Int, max: Int, invulnerabilityTimer: TimeInterval = 0) {
        self.current = current
        self.max = max
        self.invulnerabilityTimer = invulnerabilityTimer
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isAlive: Bool {
        return current > 0
    }
    
    var isInvulnerable: Bool {
        return invulnerabilityTimer > 0
    }
    
    // MARK: - Damageable Protocol
    
    var health: Int {
        get { current }
        set { current = newValue }
    }
    
    var maxHealth: Int {
        return max
    }
}
