//
//  DialogueSystem.swift
//  Touhou
//
//  Created by Assistant on 11/01/25.
//

import Foundation
import GameplayKit

/// DialogueSystem - manages dialogue display and progression
/// Handles dialogue queuing, timing, and portrait display coordination
/// Works with DialogueComponent and PortraitComponent for entity dialogue
final class DialogueSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    /// Currently active dialogue queue
    private var dialogueQueue: [DialogueEntry] = []
    /// Current dialogue being displayed
    private var currentDialogue: DialogueEntry?
    /// Timer for auto-advancing dialogue
    private var dialogueTimer: TimeInterval = 0
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Update dialogue timer for auto-advance
        if let dialogue = currentDialogue,
           let autoAdvanceDelay = dialogue.autoAdvanceDelay {
            dialogueTimer += deltaTime
            if dialogueTimer >= autoAdvanceDelay {
                advanceDialogue()
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        if let dialogueEvent = event as? DialogueEvent {
            handleDialogueEvent(dialogueEvent)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleDialogueEvent(_ event: DialogueEvent) {
        switch event {
        case .showDialogue(let text, let speaker, let portraitId, let autoAdvanceDelay):
            showDialogue(text: text, speaker: speaker, portraitId: portraitId, autoAdvanceDelay: autoAdvanceDelay)
        case .queueDialogue(let entries):
            queueDialogueEntries(entries)
        case .advanceDialogue:
            advanceDialogue()
        case .clearDialogue:
            clearDialogue()
        }
    }
    
    private func showDialogue(text: String, speaker: String?, portraitId: String?, autoAdvanceDelay: TimeInterval?) {
        let entry = DialogueEntry(text: text, speaker: speaker, portraitId: portraitId, autoAdvanceDelay: autoAdvanceDelay)
        currentDialogue = entry
        dialogueTimer = 0
        
        // Fire event for UI to display dialogue
        eventBus.fire(DialogueDisplayEvent(entry: entry))
    }
    
    private func queueDialogueEntries(_ entries: [DialogueEntry]) {
        dialogueQueue.append(contentsOf: entries)
        
        // If no dialogue is currently showing, show first queued entry
        if currentDialogue == nil && !dialogueQueue.isEmpty {
            showNextQueuedDialogue()
        }
    }
    
    private func advanceDialogue() {
        // Show next queued dialogue or clear if queue is empty
        if !dialogueQueue.isEmpty {
            showNextQueuedDialogue()
        } else {
            clearDialogue()
        }
    }
    
    private func showNextQueuedDialogue() {
        guard !dialogueQueue.isEmpty else { return }
        let entry = dialogueQueue.removeFirst()
        currentDialogue = entry
        dialogueTimer = 0
        
        eventBus.fire(DialogueDisplayEvent(entry: entry))
    }
    
    private func clearDialogue() {
        currentDialogue = nil
        dialogueTimer = 0
        eventBus.fire(DialogueClearedEvent())
    }
}

// DialogueEntry is defined in GameEvent.swift to avoid circular dependencies

