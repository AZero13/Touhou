//
//  GameScene.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var renderSystem: RenderSystem!
    
    override func didMove(to view: SKView) {
        // Set background color
        backgroundColor = SKColor.black
        
        // Initialize render system
        renderSystem = RenderSystem()
        
        // Start the game
        GameFacade.shared.startGame()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Update game logic
        GameFacade.shared.update(currentTime)
        
        // Update rendering
        if let renderSystem = renderSystem {
            renderSystem.sync(entityManager: GameFacade.shared.getEntityManager(), scene: self)
        }
    }
}
