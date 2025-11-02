//
//  AIPatternComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// AIPatternComponent - handles AI pattern state and timing
final class AIPatternComponent: GKComponent {
    var currentPattern: String // "circle", "aimed", "spiral"
    var patternTimer: TimeInterval
    var phaseIndex: Int
    
    init(currentPattern: String = "idle", patternTimer: TimeInterval = 0, phaseIndex: Int = 0) {
        self.currentPattern = currentPattern
        self.patternTimer = patternTimer
        self.phaseIndex = phaseIndex
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
