//
//  Scriptable.swift
//  Touhou
//
//  Created by Assistant on 11/02/25.
//

import Foundation
import GameplayKit

/// Protocol for entities that can execute scripts
/// More general than Spellcardable - can be used for stage scripts, boss intros, etc.
/// Uses GameFacade for simplified access to game systems
protocol Scriptable {
    /// Current script step index
    var scriptStep: Int { get set }
    /// Execute next script step
    func executeNextStep(game: GameFacade)
    /// Check if script has more steps
    func hasMoreSteps() -> Bool
}

