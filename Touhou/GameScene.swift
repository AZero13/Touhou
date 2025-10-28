//
//  GameScene.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    override func didMove(to view: SKView) {
        // Set background color
        backgroundColor = SKColor.black
        
        // Add a simple label to test
        let label = SKLabelNode(text: "Touhou Game")
        label.fontSize = 24
        label.fontColor = SKColor.white
        label.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(label)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
