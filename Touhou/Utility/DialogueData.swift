//
//  DialogueData.swift
//  Touhou
//
//  Created by Rose on 11/12/25.
//

import Foundation
import GameplayKit

enum DialogueSpeaker {
    case reimu
    case boss
}

struct DialogueLine {
    let speaker: DialogueSpeaker
    let text: String
    let annotation: String?  // Optional annotation like "(← carefree)"
    let speakerName: String? // Custom speaker name override (nil = use default for speaker type)
    let trigger: GameEvent?  // Optional event to fire when this line is shown
    
    init(speaker: DialogueSpeaker, text: String, annotation: String? = nil,
         speakerName: String? = nil, trigger: GameEvent? = nil) {
        self.speaker = speaker
        self.text = text
        self.annotation = annotation
        self.speakerName = speakerName
        self.trigger = trigger
    }
}

struct DialogueSequence {
    let id: String
    let lines: [DialogueLine]
    /// Event to fire when the entire dialogue sequence completes (replaces onComplete closure)
    let completionEvent: GameEvent?
    
    init(id: String, lines: [DialogueLine], completionEvent: GameEvent? = nil) {
        self.id = id
        self.lines = lines
        self.completionEvent = completionEvent
    }
}

/// Dialogue data definitions
enum DialogueData {
    
    /// Default speaker display names for each speaker type
    static func defaultSpeakerName(for speaker: DialogueSpeaker) -> String {
        switch speaker {
        case .reimu: return "REIMU"
        case .boss: return "???"
        }
    }
    
    static func getDialogue(id: String) -> DialogueSequence? {
        switch id {
        case "stage1_boss":
            return createStage1BossDialogue()
        case "stage1_victory":
            return createStage1VictoryDialogue()
        default:
            return nil
        }
    }
    
    private static func createStage1BossDialogue() -> DialogueSequence {
        let lines: [DialogueLine] = [
            DialogueLine(speaker: .reimu, text: "It's been a while since my last job."),
            DialogueLine(speaker: .reimu, text: "It sure feels great out."),
            DialogueLine(speaker: .reimu, text: "There aren't many evil spirits about\nduring the day, so I'm trying my luck at night..."),
            DialogueLine(speaker: .reimu, text: "But it's dark out, and\nI'm not sure where to go."),
            DialogueLine(speaker: .reimu, text: "Still..."),
            DialogueLine(speaker: .reimu, text: "It's so romantic out behind the shrine at night.", annotation: "(← carefree)"),
            // Boss first speaks — trigger boss spawn
            DialogueLine(speaker: .boss, text: "You said it!",
                         trigger: SpawnStageBossEvent()),
            DialogueLine(speaker: .boss, text: "Monsters come out too, so it's simply wonderful."),
            DialogueLine(speaker: .reimu, text: "Um,\nwho are you?")
        ]
        
        return DialogueSequence(id: "stage1_boss", lines: lines)
    }
    
    private static func createStage1VictoryDialogue() -> DialogueSequence {
        let lines: [DialogueLine] = [
            DialogueLine(speaker: .reimu, text: "That was easier than I thought."),
            DialogueLine(speaker: .reimu, text: "I wonder if there are more ahead...")
        ]
        
        // Fire StageVictoryEvent on completion instead of using a closure
        return DialogueSequence(
            id: "stage1_victory",
            lines: lines,
            completionEvent: StageVictoryEvent(stageId: 1)
        )
    }
}
