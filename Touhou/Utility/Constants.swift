//
//  Constants.swift
//  Touhou
//
//  Created by Antigravity on 11/27/25.
//

import Foundation
import SpriteKit

struct Constants {
    struct ZLayer {
        static let background: CGFloat = -100
        static let overlay: CGFloat = -1
        static let world: CGFloat = 0
        static let items: CGFloat = 100
        static let grazeEffect: CGFloat = 200
        static let floatingScore: CGFloat = 250
        static let hitEffect: CGFloat = 300
        static let effect: CGFloat = 400
        static let spellCard: CGFloat = 400
        static let boss: CGFloat = 500
        static let ui: CGFloat = 1000
        static let pauseMenu: CGFloat = 1000
        static let timeBonus: CGFloat = 1001
        static let dialogue: CGFloat = 2000
        static let spellName: CGFloat = 1500
    }
    
    struct NodeName {
        static let worldLayer = "worldLayer"
        static let bossLayer = "bossLayer"
        static let effectLayer = "effectLayer"
        static let uiLayer = "uiLayer"
        static let pauseMenu = "pauseMenu"
        static let dialogueBox = "dialogueBox"
        static let closeButton = "close"
        static let restartButton = "restart"
        static let promptIndicator = "promptIndicator"
    }
    
    struct Font {
        static let main = "Menlo"
        static let bold = "Menlo-Bold"
        static let italic = "Menlo-Italic"
    }
    
    struct UI {
        static let defaultFontSize: CGFloat = 16
        static let titleFontSize: CGFloat = 32
        static let headerFontSize: CGFloat = 24
        static let largeFontSize: CGFloat = 28
        static let smallFontSize: CGFloat = 12
    }
}
