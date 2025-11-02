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
    
    init(name: String, phaseNumber: Int = 1) {
        self.name = name
        self.phaseNumber = phaseNumber
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


