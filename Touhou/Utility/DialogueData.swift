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
    
    init(speaker: DialogueSpeaker, text: String, annotation: String? = nil) {
        self.speaker = speaker
        self.text = text
        self.annotation = annotation
    }
}

struct DialogueSequence {
    let id: String
    let lines: [DialogueLine]
    let onComplete: (() -> Void)?
    
    init(id: String, lines: [DialogueLine], onComplete: (() -> Void)? = nil) {
        self.id = id
        self.lines = lines
        self.onComplete = onComplete
    }
}

/// Dialogue data definitions
enum DialogueData {
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
            DialogueLine(speaker: .boss, text: "You said it!"),
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
        
        // After victory dialogue, transition to next stage
        return DialogueSequence(id: "stage1_victory", lines: lines, onComplete: {
            let totalScore = GameFacade.shared.entities.player?.component(ofType: PlayerComponent.self)?.score ?? 0
            let nextId = 2
            print("DialogueData: Victory dialogue complete, transitioning to stage \(nextId)")
            GameFacade.shared.fireEvent(StageTransitionEvent(nextStageId: nextId, totalScore: totalScore))
        })
    }
}

