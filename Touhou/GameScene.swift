//
//  GameScene.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, EventListener {
    
    private var renderSystem: RenderSystem!
    
    // Pause menu UI
    private var pauseMenuNode: SKNode?
    private var closeLabel: SKLabelNode?
    private var restartLabel: SKLabelNode?
    
    override func didMove(to view: SKView) {
        // Set background color
        backgroundColor = SKColor.black
        
        // Initialize render system
        renderSystem = RenderSystem()

        // Create pause menu (initially hidden)
        createPauseMenu()
        
        // Register for game events
        GameFacade.shared.registerListener(self)
        
        // Only start a new run if we're in NotStarted state (i.e., app just launched)
        // Don't reset if we're transitioning between stages (scene is recreated but game continues)
        if GameFacade.shared.isInNotStartedState() {
            GameFacade.shared.startNewRun()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Update game logic
        GameFacade.shared.update(currentTime)
        
        // Update rendering
        if let renderSystem = renderSystem {
            renderSystem.sync(entityManager: GameFacade.shared.getEntityManager(), scene: self)
        }
    }
    
    // MARK: - EventListener
    
    @MainActor
    func handleEvent(_ event: GameEvent) {
        switch event {
        case is GamePausedEvent:
            self.showPauseMenu()
        case is PauseMenuHiddenEvent:
            self.hidePauseMenu()
        case let e as PauseMenuUpdateEvent:
            self.updatePauseMenuSelection(selectedOption: e.selectedOption)
        case let e as GrazeEvent:
            self.playGrazeEffect(for: e.bulletEntity)
        case let e as EnemyHitEvent:
            self.showHitEffect(atLogical: e.hitPosition)
        default:
            break
        }
    }
    
    // MARK: - Pause Menu UI
    
    private func createPauseMenu() {
        let menuNode = SKNode()
        menuNode.name = "pauseMenu"
        menuNode.isHidden = true
        
        // Title
        let titleLabel = SKLabelNode(text: "PAUSE")
        titleLabel.fontName = "Menlo-Bold"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        menuNode.addChild(titleLabel)
        
        // Close option
        let close = SKLabelNode(text: "CLOSE")
        close.fontName = "Menlo"
        close.fontSize = 24
        close.fontColor = .white
        close.position = CGPoint(x: size.width / 2, y: size.height / 2)
        close.name = "close"
        menuNode.addChild(close)
        self.closeLabel = close
        
        // Restart option
        let restart = SKLabelNode(text: "RESTART")
        restart.fontName = "Menlo"
        restart.fontSize = 24
        restart.fontColor = .white
        restart.position = CGPoint(x: size.width / 2, y: size.height / 2 - 40)
        restart.name = "restart"
        menuNode.addChild(restart)
        self.restartLabel = restart
        
        // Add dark overlay
        let overlay = SKSpriteNode(color: .black, size: size)
        overlay.alpha = 0.7
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = -1
        menuNode.addChild(overlay)
        
        menuNode.zPosition = 1000 // Above everything
        addChild(menuNode)
        self.pauseMenuNode = menuNode
    }
    
    private func showPauseMenu() {
        pauseMenuNode?.isHidden = false
    }
    
    private func hidePauseMenu() {
        pauseMenuNode?.isHidden = true
    }
    
    private func updatePauseMenuSelection(selectedOption: PauseMenuOption) {
        // Highlight selected option (white), dim unselected (gray)
        switch selectedOption {
        case .close:
            closeLabel?.fontColor = .white
            closeLabel?.fontName = "Menlo-Bold"
            restartLabel?.fontColor = .gray
            restartLabel?.fontName = "Menlo"
        case .restart:
            closeLabel?.fontColor = .gray
            closeLabel?.fontName = "Menlo"
            restartLabel?.fontColor = .white
            restartLabel?.fontName = "Menlo-Bold"
        }
    }

    // MARK: - Effects
    private func playGrazeEffect(for bulletEntity: GKEntity) {
        if let transform = bulletEntity.component(ofType: TransformComponent.self) {
            self.showGrazeEffect(atLogical: transform.position)
        }
    }

    private func showGrazeEffect(atLogical position: CGPoint) {
        let scaleX = size.width / GameFacade.playArea.width
        let scaleY = size.height / GameFacade.playArea.height
        let scenePosition = CGPoint(x: position.x * scaleX, y: position.y * scaleY)
        let radius: CGFloat = 8 * max(scaleX, scaleY)
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = scenePosition
        node.strokeColor = .white
        node.lineWidth = 1.0
        node.alpha = 1.0
        node.zPosition = 200
        addChild(node)
        let expand = SKAction.scale(to: 2.5, duration: 0.2)
        let fade = SKAction.fadeOut(withDuration: 0.2)
        let group = SKAction.group([expand, fade])
        node.run(.sequence([group, .removeFromParent()]))
        run(SKAction.playSoundFileNamed("graze.caf", waitForCompletion: false))
    }
    
    private func showHitEffect(atLogical position: CGPoint) {
        let scaleX = size.width / GameFacade.playArea.width
        let scaleY = size.height / GameFacade.playArea.height
        let scenePosition = CGPoint(x: position.x * scaleX, y: position.y * scaleY)
        let radius: CGFloat = 4 * max(scaleX, scaleY)  // Small white circle
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = scenePosition
        node.strokeColor = .white
        node.lineWidth = 1.5
        node.fillColor = .clear
        node.alpha = 1.0
        node.zPosition = 300  // Above everything
        addChild(node)
        let expand = SKAction.scale(to: 3.0, duration: 0.15)  // Expand 3x
        let fade = SKAction.fadeOut(withDuration: 0.15)
        let group = SKAction.group([expand, fade])
        node.run(.sequence([group, .removeFromParent()]))
        
        // TODO: Add sound effect here when sound file is ready
        // run(SKAction.playSoundFileNamed("hit.caf", waitForCompletion: false))
    }
}
