//
//  DialogueSystem.swift
//  Touhou
//
//  Created by Rose on 11/12/25.
//

import Foundation
import GameplayKit

/// System to handle dialogue-triggered spawns and actions
final class DialogueSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(context: GameRuntimeContext) {
        self.entityManager = context.entityManager
        self.eventBus = context.eventBus
    }
    
    func update(deltaTime: TimeInterval, context: GameRuntimeContext) {
        // No per-frame updates needed
    }
    
    func handleEvent(_ event: GameEvent, context: GameRuntimeContext) {
        if let trigger = event as? DialogueSpawnTriggerEvent {
            handleDialogueTrigger(trigger, context: context)
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        // Fallback for non-GameSystem listeners (shouldn't be called)
        fatalError("DialogueSystem.handleEvent without context should not be called")
    }
    
    private func handleDialogueTrigger(_ trigger: DialogueSpawnTriggerEvent, context: GameRuntimeContext) {
        // Handle stage 1 midboss spawn
        if trigger.dialogueId == "stage1_midboss" && trigger.triggerName == "spawn_rumia" {
            Stage1Timeline.spawnRumiaMidbossNow()
        }
    }
}

