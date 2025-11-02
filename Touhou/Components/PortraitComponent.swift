//
//  PortraitComponent.swift
//  Touhou
//
//  Created by Assistant on 11/02/25.
//

import Foundation
import GameplayKit

/// Side of screen for portrait display
enum PortraitSide {
    case left
    case right
}

/// PortraitComponent - stores portrait display state for any entity
/// Used with DialogueComponent to show character portraits during dialogue
final class PortraitComponent: GKComponent {
    /// Portrait identifier (used to load appropriate portrait image)
    let portraitId: String
    /// Current emotion/mood for portrait (e.g., "normal", "angry", "happy")
    var portraitEmotion: String
    /// Whether portrait should be displayed on left or right side
    let portraitSide: PortraitSide
    
    init(portraitId: String, emotion: String = "normal", side: PortraitSide = .right) {
        self.portraitId = portraitId
        self.portraitEmotion = emotion
        self.portraitSide = side
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

