//
//  HealthComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

class HealthComponent: GKComponent {
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
}
