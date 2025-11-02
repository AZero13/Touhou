//
//  DialogueFacade.swift
//  Touhou
//
//  Created by Assistant on 11/02/25.
//

import Foundation
import GameplayKit

/// DialogueFacade - Simplified API for dialogue and portrait operations
/// Hides complexity of DialogueComponent, PortraitComponent, and EventBus
final class DialogueFacade {
    private let entityManager: EntityManager
    private let eventBus: EventBus
    
    init(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    // MARK: - Dialogue Operations
    
    /// Show dialogue for an entity
    func showDialogue(
        for entity: GKEntity,
        text: String,
        speaker: String? = nil,
        autoAdvanceDelay: TimeInterval? = nil
    ) {
        guard let dialogueComp = entity.component(ofType: DialogueComponent.self) else {
            print("Warning: Entity has no DialogueComponent")
            return
        }
        
        dialogueComp.showDialogue(
            text: text,
            speaker: speaker ?? dialogueComp.dialogueSpeaker,
            eventBus: eventBus
        )
    }
    
    /// Hide dialogue for an entity
    func hideDialogue(for entity: GKEntity) {
        guard let dialogueComp = entity.component(ofType: DialogueComponent.self) else {
            return
        }
        
        dialogueComp.hideDialogue(eventBus: eventBus)
    }
    
    /// Queue multiple dialogue entries for sequential display
    func queueDialogue(entries: [DialogueEntry]) {
        eventBus.fire(DialogueEvent.queueDialogue(entries: entries))
    }
    
    /// Advance to next queued dialogue
    func advanceDialogue() {
        eventBus.fire(DialogueEvent.advanceDialogue)
    }
    
    /// Clear all dialogue
    func clearAllDialogue() {
        eventBus.fire(DialogueEvent.clearDialogue)
    }
    
    // MARK: - Portrait Operations
    
    /// Change portrait emotion for an entity
    func setPortraitEmotion(for entity: GKEntity, emotion: String) {
        guard let portraitComp = entity.component(ofType: PortraitComponent.self) else {
            print("Warning: Entity has no PortraitComponent")
            return
        }
        
        portraitComp.portraitEmotion = emotion
    }
    
    // MARK: - Convenience
    
    /// Show dialogue with emotion change
    func showDialogue(
        for entity: GKEntity,
        text: String,
        speaker: String? = nil,
        emotion: String? = nil,
        autoAdvanceDelay: TimeInterval? = nil
    ) {
        if let emotion = emotion {
            setPortraitEmotion(for: entity, emotion: emotion)
        }
        
        showDialogue(for: entity, text: text, speaker: speaker, autoAdvanceDelay: autoAdvanceDelay)
    }
}

