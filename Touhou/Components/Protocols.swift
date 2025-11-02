//
//  Protocols.swift
//  Touhou
//
//  Created by Assistant on 11/01/25.
//

import Foundation
import GameplayKit

/// Protocol for entities that can execute spellcards
/// Bosses implement this to define spellcard phases and patterns
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
    func startSpellcard(entityManager: EntityManager, commandQueue: CommandQueue, taskScheduler: TaskScheduler)
    /// Update spellcard logic (called each frame while active)
    func updateSpellcard(deltaTime: TimeInterval, entityManager: EntityManager, commandQueue: CommandQueue)
    /// Advance to next phase or end spellcard
    func advancePhase(entityManager: EntityManager, commandQueue: CommandQueue, taskScheduler: TaskScheduler)
    /// End the spellcard
    func endSpellcard(entityManager: EntityManager, commandQueue: CommandQueue)
}

/// Protocol for entities that can display dialogue
/// Used for bosses, NPCs, and scripted dialogue sequences
protocol Dialogueable {
    /// Current dialogue text to display
    var currentDialogue: String? { get set }
    /// Character name for current dialogue
    var dialogueSpeaker: String? { get set }
    /// Whether dialogue is currently being displayed
    var isDialogueActive: Bool { get set }
    /// Duration for auto-advancing dialogue (nil = manual)
    var dialogueAutoAdvanceDelay: TimeInterval? { get set }
    
    /// Show dialogue text
    func showDialogue(text: String, speaker: String?, eventBus: EventBus)
    /// Hide dialogue
    func hideDialogue(eventBus: EventBus)
}

/// Protocol for entities that have portrait displays
/// Used with Dialogueable to show character portraits during dialogue
protocol Portraitable {
    /// Portrait identifier (used to load appropriate portrait image)
    var portraitId: String { get }
    /// Current emotion/mood for portrait (e.g., "normal", "angry", "happy")
    var portraitEmotion: String { get set }
    /// Whether portrait should be displayed on left or right side
    var portraitSide: PortraitSide { get }
}

/// Side of screen for portrait display
enum PortraitSide {
    case left
    case right
}

/// Protocol for entities that can execute scripts
/// More general than Spellcardable - can be used for stage scripts, boss intros, etc.
protocol Scriptable {
    /// Current script step index
    var scriptStep: Int { get set }
    /// Execute next script step
    func executeNextStep(entityManager: EntityManager, commandQueue: CommandQueue, taskScheduler: TaskScheduler)
    /// Check if script has more steps
    func hasMoreSteps() -> Bool
}

/// Protocol for entities that have health/phases like bosses
protocol Phased {
    /// Current health
    var currentHealth: Int { get set }
    /// Maximum health for current phase
    var maxHealthForPhase: Int { get }
    /// Current phase number (1-based)
    var phaseNumber: Int { get set }
}

