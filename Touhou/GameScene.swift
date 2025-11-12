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
    
    // Midboss timer UI
    private var timeBonusLabel: SKLabelNode?
    
    // Layers
    private var worldLayer: SKNode!      // Game entities: bullets, enemies, player, items
    private var bossLayer: SKNode!       // Boss-specific content: boss health bar, phase effects
    private var effectLayer: SKNode!     // Transient visual effects: graze, hits
    private var uiLayer: SKNode!         // Persistent UI: pause menu, score display
    
    // Cached actions for effects
    private var grazeEffectAction: SKAction!
    private var hitEffectAction: SKAction!
    private var grazeSoundAction: SKAction!
    private var floatingScoreAction: SKAction!
    private var enemyDeathAction: SKAction!
    private var bombFlashAction: SKAction!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        
        // Initialize render system
        renderSystem = RenderSystem()
        
        // World layer
        worldLayer = SKNode()
        worldLayer.name = "worldLayer"
        addChild(worldLayer)
        
        // Boss UI (healthbar)
        bossLayer = SKNode()
        bossLayer.name = "bossLayer"
        bossLayer.isHidden = true  // Hidden until boss appears
        addChild(bossLayer)
        
        effectLayer = SKNode()
        effectLayer.name = "effectLayer"
        addChild(effectLayer)
        
        uiLayer = SKNode()
        uiLayer.name = "uiLayer"
        addChild(uiLayer)

        // Create cached actions for effects
        setupEffectActions()

        // Create pause menu (initially hidden)
        createPauseMenu()
        
        // Create time bonus timer (initially hidden)
        createTimeBonusTimer()
        
        // Register for game events
        GameFacade.shared.registerListener(self)
        
        // Only start a new run if we're in NotStarted state (i.e., app just launched)
        // Don't reset if we're transitioning between stages (scene is recreated but game continues)
        if GameFacade.shared.isInNotStartedState {
            GameFacade.shared.startNewRun()
        }
    }
    
    private func setupEffectActions() {
        let grazeExpand = SKAction.scale(to: 2.5, duration: 0.2)
        let grazeFade = SKAction.fadeOut(withDuration: 0.2)
        grazeEffectAction = .sequence([.group([grazeExpand, grazeFade]), .removeFromParent()])
        
        let hitExpand = SKAction.scale(to: 3.0, duration: 0.15)
        let hitFade = SKAction.fadeOut(withDuration: 0.15)
        hitEffectAction = .sequence([.group([hitExpand, hitFade]), .removeFromParent()])
        
        grazeSoundAction = SKAction.playSoundFileNamed("graze.caf", waitForCompletion: false)
        
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        floatingScoreAction = .sequence([.group([moveUp, fadeOut]), remove])
        
        let deathExpand = SKAction.scale(to: 2.5, duration: 0.25)
        let deathFade = SKAction.fadeOut(withDuration: 0.25)
        enemyDeathAction = .sequence([.group([deathExpand, deathFade]), remove])
        
        // Bomb flash: white overlay that fades out quickly
        let flashFade = SKAction.fadeOut(withDuration: 0.3)
        bombFlashAction = .sequence([flashFade, .removeFromParent()])
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Update game logic
        GameFacade.shared.update(currentTime)
        
        // Update time bonus timer if visible
        updateTimeBonusTimer()
    }
    
    override func didFinishUpdate() {
        // Update rendering after all actions and physics have been processed
        // This ensures that any position changes from actions won't be overwritten
        if let renderSystem = renderSystem {
            renderSystem.sync(entities: GameFacade.shared.entities, scene: self, worldLayer: worldLayer, bossLayer: bossLayer, effectLayer: effectLayer)
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
        case let e as PowerUpCollectedEvent:
            self.showFloatingScore(value: e.value, atLogical: e.position)
        case let e as EnemyDiedEvent:
            self.showEnemyDeathEffect(for: e.entity)
            // Hide timer when boss dies
            if e.entity.component(ofType: BossComponent.self) != nil {
                self.hideTimeBonusTimer()
            }
        case let e as BossIntroStartedEvent:
            // Show timer when midboss with time bonus spawns
            if let bossComp = e.bossEntity.component(ofType: BossComponent.self), bossComp.hasTimeBonus {
                self.showTimeBonusTimer()
            }
        case let e as TimeBonusAwardedEvent:
            self.showTimeBonusText(bonus: e.bonusPoints, atLogical: e.position)
        case is BombActivatedEvent:
            self.showBombFlashEffect()
        case let e as StageTransitionEvent:
            self.handleStageTransition(nextStageId: e.nextStageId, totalScore: e.totalScore)
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
        uiLayer.addChild(menuNode)  // Add to UI layer
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
    
    // MARK: - Time Bonus Timer UI
    
    private func createTimeBonusTimer() {
        let label = SKLabelNode(text: "TIME 00.00")
        label.fontName = "Menlo-Bold"
        label.fontSize = 16
        label.fontColor = .white
        label.horizontalAlignmentMode = .right
        label.verticalAlignmentMode = .top
        label.position = CGPoint(x: size.width - 10, y: size.height - 10)
        label.zPosition = 1001  // Above everything
        label.isHidden = true
        uiLayer.addChild(label)
        self.timeBonusLabel = label
    }
    
    private func showTimeBonusTimer() {
        timeBonusLabel?.isHidden = false
    }
    
    private func hideTimeBonusTimer() {
        timeBonusLabel?.isHidden = true
    }
    
    private func updateTimeBonusTimer() {
        guard let label = timeBonusLabel, !label.isHidden else { return }
        
        // Find active midboss with time bonus
        let bosses = GameFacade.shared.entities.getEntities(with: BossComponent.self)
        guard let boss = bosses.first,
              let bossComp = boss.component(ofType: BossComponent.self),
              bossComp.hasTimeBonus else {
            hideTimeBonusTimer()
            return
        }
        
        let remainingTime = max(0, bossComp.timeLimit - bossComp.elapsedTime)
        let rounded = round(remainingTime * 100) / 100
        label.text = "TIME \(rounded)"
        
        // Change color based on remaining time (red when running out)
        if remainingTime < 5.0 {
            label.fontColor = .red
        } else if remainingTime < 10.0 {
            label.fontColor = .yellow
        } else {
            label.fontColor = .white
        }
    }
    
    private func showTimeBonusText(bonus: Int, atLogical position: CGPoint) {
        let scaleX = size.width / GameFacade.playArea.width
        let scaleY = size.height / GameFacade.playArea.height
        let scenePosition = CGPoint(x: position.x * scaleX, y: position.y * scaleY)
        
        let label = SKLabelNode(text: "BONUS \(bonus)")
        label.fontName = "Menlo-Bold"
        label.fontSize = 28 * max(scaleX, scaleY)
        label.fontColor = .yellow  // Yellow for bonus (like TH06)
        label.position = scenePosition
        label.zPosition = 350  // Above everything else
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        // Longer duration for bonus text (2 seconds)
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        let remove = SKAction.removeFromParent()
        let bonusAction = SKAction.sequence([.group([moveUp, fadeOut]), remove])
        
        effectLayer.addChild(label)
        label.run(bonusAction)
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
        effectLayer.addChild(node)  // Add to effect layer
        node.run(grazeEffectAction)  // Use cached action
        run(grazeSoundAction)  // Use cached sound action
    }
    
    private func showHitEffect(atLogical position: CGPoint) {
        let scaleX = size.width / GameFacade.playArea.width
        let scaleY = size.height / GameFacade.playArea.height
        let scenePosition = CGPoint(x: position.x * scaleX, y: position.y * scaleY)
        let radius: CGFloat = 4 * max(scaleX, scaleY)
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = scenePosition
        node.strokeColor = .white
        node.lineWidth = 1.5
        node.fillColor = .clear
        node.alpha = 1.0
        node.zPosition = 300
        effectLayer.addChild(node)
        node.run(hitEffectAction)
    }
    
    /// Show floating score number at collection position (TH06 style)
    private func showFloatingScore(value: Int, atLogical position: CGPoint) {
        // Skip if value is 0 (bombs/lives don't award score)
        guard value > 0 else { return }
        
        let scaleX = size.width / GameFacade.playArea.width
        let scaleY = size.height / GameFacade.playArea.height
        let scenePosition = CGPoint(x: position.x * scaleX, y: position.y * scaleY)
        
        let label = SKLabelNode(text: "\(value)")
        label.fontName = "Menlo-Bold"
        label.fontSize = 20 * max(scaleX, scaleY)
        label.fontColor = value >= 100000 ? .yellow : .white  // Yellow for high value (matching TH06)
        label.position = scenePosition
        label.zPosition = 250  // Above items, below bosses
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        effectLayer.addChild(label)
        label.run(floatingScoreAction)
    }
    
    /// Show enemy death effect (TH06 style)
    private func showEnemyDeathEffect(for enemyEntity: GKEntity) {
        guard let transform = enemyEntity.component(ofType: TransformComponent.self) else { return }
        
        let scaleX = size.width / GameFacade.playArea.width
        let scaleY = size.height / GameFacade.playArea.height
        let scenePosition = CGPoint(x: transform.position.x * scaleX, y: transform.position.y * scaleY)
        let radius: CGFloat = 24 * max(scaleX, scaleY)
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = scenePosition
        node.strokeColor = .white
        node.lineWidth = 2.0
        node.fillColor = .clear
        node.alpha = 1.0
        node.zPosition = 200
        
        effectLayer.addChild(node)
        node.run(enemyDeathAction)
    }
    
    /// Show bomb flash effect (white screen flash)
    private func showBombFlashEffect() {
        let flashOverlay = SKSpriteNode(color: .white, size: size)
        flashOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flashOverlay.alpha = 0.8  // Start at 80% opacity
        flashOverlay.zPosition = 999  // Above everything except UI
        flashOverlay.blendMode = .add  // Additive blending for brighter flash
        addChild(flashOverlay)
        flashOverlay.run(bombFlashAction)
    }
    
    /// Handle stage transition: wait for items to be collected, then notify for scene change
    private func handleStageTransition(nextStageId: Int, totalScore: Int) {
        // Wait 1 second to allow points/items to be collected after boss defeat
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run {
                GameFacade.shared.fireEvent(SceneReadyForTransitionEvent(nextStageId: nextStageId, totalScore: totalScore))
            }
        ]))
    }
}
