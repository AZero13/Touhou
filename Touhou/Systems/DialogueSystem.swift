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
        print("DialogueSystem: Received spawn trigger - dialogueId: \(trigger.dialogueId), triggerName: \(trigger.triggerName)")
        
        // Handle stage 1 stage boss spawn (after dialogue)
        if trigger.dialogueId == "stage1_boss" && trigger.triggerName == "spawn_stage_boss" {
            print("DialogueSystem: Triggering stage boss spawn")
            context.eventBus.fire(SpawnStageBossEvent())
        }
        // Handle stage 1 midboss spawn (if we ever want dialogue before midboss)
        else if trigger.dialogueId == "stage1_midboss" && trigger.triggerName == "spawn_rumia" {
            print("DialogueSystem: Triggering midboss spawn")
            Stage1Timeline.triggerMidbossSpawn()
        }
    }
}

