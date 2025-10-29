//
//  PlayerComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

class PlayerComponent: GKComponent {
    var power: Int
    var lives: Int
    var bombs: Int
    var isFocused: Bool
    var score: Int
    var powerItemCountForScore: Int // For tracking power items collected when at full power
    
    init(power: Int = 0, lives: Int = 3, bombs: Int = 3, isFocused: Bool = false, score: Int = 0) {
        self.power = power
        self.lives = lives
        self.bombs = bombs
        self.isFocused = isFocused
        self.score = score
        self.powerItemCountForScore = 0 // Always starts at 0
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
