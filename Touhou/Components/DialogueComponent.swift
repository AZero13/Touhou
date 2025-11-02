//
//  DialogueComponent.swift
//  Touhou
//
//  Created by Assistant on 11/02/25.
//

import Foundation
import GameplayKit

/// DialogueComponent - stores dialogue state for any entity that can display dialogue
/// Used for bosses, NPCs, and scripted dialogue sequences
final class DialogueComponent: GKComponent {
    /// Current dialogue text to display
    var currentDialogue: String?
    /// Character name for current dialogue
    var dialogueSpeaker: String?
    /// Whether dialogue is currently being displayed
    var isDialogueActive: Bool = false
    /// Duration for auto-advancing dialogue (nil = manual)
    var dialogueAutoAdvanceDelay: TimeInterval?
    
    init(speaker: String? = nil, autoAdvanceDelay: TimeInterval? = nil) {
        self.dialogueSpeaker = speaker
        self.dialogueAutoAdvanceDelay = autoAdvanceDelay
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Show dialogue text
    func showDialogue(text: String, speaker: String?, eventBus: EventBus) {
        self.currentDialogue = text
        if let speaker = speaker {
            self.dialogueSpeaker = speaker
        }
        self.isDialogueActive = true
        
        eventBus.fire(DialogueEvent.showDialogue(
            text: text,
            speaker: self.dialogueSpeaker,
            portraitId: entity?.component(ofType: PortraitComponent.self)?.portraitId,
            autoAdvanceDelay: dialogueAutoAdvanceDelay
        ))
    }
    
    /// Hide dialogue
    func hideDialogue(eventBus: EventBus) {
        self.currentDialogue = nil
        self.isDialogueActive = false
        eventBus.fire(DialogueEvent.clearDialogue)
    }
}

