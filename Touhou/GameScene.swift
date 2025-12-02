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
    
    private var hud: GameHUD!
    private var gameEngine: GameEngine!
    
    // Spell card effect (follows boss during fight)
    private var spellCardContainer: SKNode?
    private var spellCardCircle: SKShapeNode?
    private var currentBossEntity: GKEntity?
    
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
    
    // Sound actions
    private var playerShootSoundAction: SKAction!
    private var enemyHitSoundAction: SKAction!
    private var enemyDeathSoundAction: SKAction!
    private var playerHitSoundAction: SKAction!
    private var itemPickupSoundAction: SKAction!
    private var bombSoundAction: SKAction!
    private var bossSpellSoundAction: SKAction!
    private var pauseSoundAction: SKAction!
    
    init(size: CGSize, gameEngine: GameEngine) {
        self.gameEngine = gameEngine
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        
        // Initialize render system
        renderSystem = RenderSystem()
        
        // World layer
        worldLayer = SKNode()
        worldLayer.name = Constants.NodeName.worldLayer
        addChild(worldLayer)
        
        // Boss UI (healthbar)
        bossLayer = SKNode()
        bossLayer.name = Constants.NodeName.bossLayer
        bossLayer.isHidden = true  // Hidden until boss appears
        bossLayer.zPosition = Constants.ZLayer.boss  // Above effect layer (spell card effect is at 400)
        addChild(bossLayer)
        
        effectLayer = SKNode()
        effectLayer.name = Constants.NodeName.effectLayer
        effectLayer.zPosition = Constants.ZLayer.effect  // Spell card effects go here
        addChild(effectLayer)
        
        uiLayer = SKNode()
        uiLayer.name = Constants.NodeName.uiLayer
        addChild(uiLayer)
        
        // Initialize HUD
        hud = GameHUD(uiLayer: uiLayer)
        hud.setup(in: self, engine: gameEngine)

        // Create cached actions for effects
        setupEffectActions()
        
        // Register for game events
        gameEngine.registerListener(self)
        
        // Only start a new run if we're in NotStarted state (i.e., app just launched)
        // Don't reset if we're transitioning between stages (scene is recreated but game continues)
        if gameEngine.isInNotStartedState {
            gameEngine.startNewRun()
        }
    }
    
    private func setupEffectActions() {
        let grazeExpand = SKAction.scale(to: 2.5, duration: 0.2)
        let grazeFade = SKAction.fadeOut(withDuration: 0.2)
        grazeEffectAction = .sequence([.group([grazeExpand, grazeFade]), .removeFromParent()])
        
        let hitExpand = SKAction.scale(to: 3.0, duration: 0.15)
        let hitFade = SKAction.fadeOut(withDuration: 0.15)
        hitEffectAction = .sequence([.group([hitExpand, hitFade]), .removeFromParent()])
        
        // Sound effects (files expected in project bundle)
        grazeSoundAction = SKAction.playSoundFileNamed("graze.wav", waitForCompletion: false)
        playerShootSoundAction = SKAction.playSoundFileNamed("plst00.wav", waitForCompletion: false)
        enemyHitSoundAction = SKAction.playSoundFileNamed("enep00.wav", waitForCompletion: false)
        enemyDeathSoundAction = SKAction.playSoundFileNamed("enep01.wav", waitForCompletion: false)
        playerHitSoundAction = SKAction.playSoundFileNamed("pldead00.wav", waitForCompletion: false)
        itemPickupSoundAction = SKAction.playSoundFileNamed("item00.wav", waitForCompletion: false)
        bombSoundAction = SKAction.playSoundFileNamed("cat00.wav", waitForCompletion: false)
        bossSpellSoundAction = SKAction.playSoundFileNamed("cat01.wav", waitForCompletion: false)
        pauseSoundAction = SKAction.playSoundFileNamed("pause.wav", waitForCompletion: false)
        
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
        // Check for dialogue advancement (before game update)
        if hud.isDialogueActive {
            gameEngine.update(currentTime)
            let input = InputManager.shared.currentInput
            if input.shoot.justPressed {
                hud.advanceDialogue()
            }
            
            // Update boss UI (bar and timer)
            hud.updateBossUI(bossLayer: bossLayer)
            return
        }
        
        // Update game logic (this will also update InputManager)
        gameEngine.update(currentTime)
        
        // Update boss UI (bar and timer)
        hud.updateBossUI(bossLayer: bossLayer)
        
        // Update spell card effect to follow boss
        updateSpellCardEffect()
    }
    
    override func didFinishUpdate() {
        // Update rendering after all actions and physics have been processed
        // This ensures that any position changes from actions won't be overwritten
        if let renderSystem = renderSystem {
            renderSystem.sync(entities: gameEngine.entities, scene: self, worldLayer: worldLayer, bossLayer: bossLayer, effectLayer: effectLayer)
        }
    }
    
    // MARK: - Keyboard Input
    
    override func keyDown(with event: NSEvent) {
        InputManager.shared.setKeyPressed(event.keyCode)
    }
    
    override func keyUp(with event: NSEvent) {
        InputManager.shared.setKeyReleased(event.keyCode)
    }
    
    // MARK: - EventListener
    
    @MainActor
    func handleEvent(_ event: GameEvent) {
        switch event {
        case is GamePausedEvent:
            run(pauseSoundAction)
            hud.showPauseMenu()
            self.pauseMenuEffect()
        case is PlayerShootEvent:
            run(playerShootSoundAction)
        case is ItemCollectedEvent:
            run(itemPickupSoundAction)
        case is GameResumedEvent:
            self.resumeSpellCardEffect()
        case is PauseMenuHiddenEvent:
            hud.hidePauseMenu()
        case let e as PauseMenuUpdateEvent:
            hud.updatePauseMenuSelection(selectedOption: e.selectedOption)
        case let e as GrazeEvent:
            self.playGrazeEffect(for: e.bulletEntity)
        case let e as EnemyHitEvent:
            run(enemyHitSoundAction)
            self.showHitEffect(atLogical: e.hitPosition)
        case let e as PowerUpCollectedEvent:
            self.showFloatingScore(value: e.value, atLogical: e.position)
        case let e as EnemyDiedEvent:
            run(enemyDeathSoundAction)
            self.showEnemyDeathEffect(for: e.entity)
        case is BossDefeatedEvent:
            // Boss defeated - hide health bar and timer immediately (boss will flee or vanish)
            hud.hideBossUI(bossLayer: bossLayer)
            // Remove spell card effect (spell card succeeded)
            removeSpellCardEffect()
            // Spell card name and timer should vanish when spell ends
            hud.hideSpellName()
        case is BossFledEvent:
            // Boss fled - remove spell card effect (spell card ended)
            removeSpellCardEffect()
            // Spell card name and timer should vanish when spell ends (midboss flee)
            hud.hideSpellName()
            hud.hideBossUI(bossLayer: bossLayer)
        case let e as BossIntroStartedEvent:
            run(bossSpellSoundAction)
            // Create persistent spell card effect around boss
            createSpellCardEffect(for: e.bossEntity)
            // Boss UI will be shown automatically by updateBossUI()
            // Show initial spell name based on boss type/phase (TH06-style)
            showSpellNameIfNeeded(for: e.bossEntity, phase: 1)
        case let e as BossPhaseTransitionEvent:
            // Phase change (multi-phase boss) - update spell name
            showSpellNameIfNeeded(for: e.bossEntity, phase: e.newPhase)
        case let e as TimeBonusAwardedEvent:
            self.showTimeBonusText(bonus: e.bonusPoints)
        case let e as TimeBonusFailedEvent:
            self.showFailedText(atLogical: e.position)
            // Remove spell card effect (spell card failed - time expired)
            removeSpellCardEffect()
            // Spell card name and timer should vanish when spell ends (time out)
            hud.hideSpellName()
            hud.hideBossUI(bossLayer: bossLayer)
        case let e as DialogueTriggeredEvent:
            hud.startDialogue(dialogueId: e.dialogueId)
        case is BombActivatedEvent:
            run(bombSoundAction)
            self.showBombFlashEffect()
        case let e as StageTransitionEvent:
            self.handleStageTransition(nextStageId: e.nextStageId, totalScore: e.totalScore)
        default:
            break
        }
    }
    
    /// Map specific bosses/phases to spell card names (currently Rumia only).
    private func showSpellNameIfNeeded(for bossEntity: GKEntity, phase: Int) {
        guard let bossComp = bossEntity.component(ofType: BossComponent.self) else { return }
        
        // Only handle Rumia for now
        guard bossComp.name.contains("Rumia") else { return }
        
        // Midboss (phaseNumber == 0): Moon Sign "Moonlight Ray"
        if bossComp.phaseNumber == 0 {
            hud.showSpellName("Moon Sign \"Moonlight Ray\"")
            return
        }
        
        // Stage boss phases
        switch phase {
        case 1:
            // First spell card
            hud.showSpellName("Night Sign \"Night Bird\"")
        case 2:
            // Second spell card
            hud.showSpellName("Darkness Sign \"Demarcation\"")
        default:
            break
        }
    }
    
    private func pauseMenuEffect() {
        self.pauseSpellCardEffect()
    }
    
    private func showTimeBonusText(bonus: Int) {
        // Always show bonus text in the center of the screen
        let centerPosition = CGPoint(x: size.width / 2, y: size.height / 2)
        
        let label = SKLabelNode(text: "BONUS \(bonus)")
        label.fontName = "Menlo-Bold"
        label.fontSize = 28
        label.fontColor = .yellow  // Yellow for bonus (like TH06)
        label.position = centerPosition
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
    
    private func showFailedText(atLogical position: CGPoint) {
        let scaleX = size.width / gameEngine.playArea.width
        let scaleY = size.height / gameEngine.playArea.height
        let scenePosition = CGPoint(x: position.x * scaleX, y: position.y * scaleY)
        
        let label = SKLabelNode(text: "FAILED")
        label.fontName = "Menlo-Bold"
        label.fontSize = 28 * max(scaleX, scaleY)
        label.fontColor = .red  // Red for failed
        label.position = scenePosition
        label.zPosition = 350  // Above everything else
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        // Fade out over 2 seconds
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 2.0)
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        let remove = SKAction.removeFromParent()
        let failAction = SKAction.sequence([.group([moveUp, fadeOut]), remove])
        
        effectLayer.addChild(label)
        label.run(failAction)
    }

    // MARK: - Effects
    private func playGrazeEffect(for bulletEntity: GKEntity) {
        if let transform = bulletEntity.component(ofType: TransformComponent.self) {
            self.showGrazeEffect(atLogical: transform.position)
        }
    }

    private func showGrazeEffect(atLogical position: CGPoint) {
        let scaleX = size.width / gameEngine.playArea.width
        let scaleY = size.height / gameEngine.playArea.height
        let scenePosition = CGPoint(x: position.x * scaleX, y: position.y * scaleY)
        let radius: CGFloat = 8 * max(scaleX, scaleY)
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = scenePosition
        node.strokeColor = .white
        node.lineWidth = 1.0
        node.alpha = 1.0
        node.zPosition = Constants.ZLayer.grazeEffect
        effectLayer.addChild(node)  // Add to effect layer
        node.run(grazeEffectAction)  // Use cached action
        run(grazeSoundAction)  // Use cached sound action
    }
    
    private func showHitEffect(atLogical position: CGPoint) {
        let scaleX = size.width / gameEngine.playArea.width
        let scaleY = size.height / gameEngine.playArea.height
        let scenePosition = CGPoint(x: position.x * scaleX, y: position.y * scaleY)
        let radius: CGFloat = 4 * max(scaleX, scaleY)
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = scenePosition
        node.strokeColor = .white
        node.lineWidth = 1.5
        node.fillColor = .clear
        node.alpha = 1.0
        node.zPosition = Constants.ZLayer.hitEffect
        effectLayer.addChild(node)
        node.run(hitEffectAction)
    }
    
    /// Show floating score number at collection position (TH06 style)
    private func showFloatingScore(value: Int, atLogical position: CGPoint) {
        // Skip if value is 0 (bombs/lives don't award score)
        guard value > 0 else { return }
        
        let scaleX = size.width / gameEngine.playArea.width
        let scaleY = size.height / gameEngine.playArea.height
        let scenePosition = CGPoint(x: position.x * scaleX, y: position.y * scaleY)
        
        let label = SKLabelNode(text: "\(value)")
        label.fontName = "Menlo-Bold"
        label.fontSize = 20 * max(scaleX, scaleY)
        label.fontColor = value >= 100000 ? .yellow : .white  // Yellow for high value (matching TH06)
        label.position = scenePosition
        label.zPosition = Constants.ZLayer.floatingScore  // Above items, below bosses
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        effectLayer.addChild(label)
        label.run(floatingScoreAction)
    }
    
    /// Show enemy death effect (TH06 style)
    private func showEnemyDeathEffect(for enemyEntity: GKEntity) {
        guard let transform = enemyEntity.component(ofType: TransformComponent.self) else { return }
        
        let scaleX = size.width / gameEngine.playArea.width
        let scaleY = size.height / gameEngine.playArea.height
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
    
    /// Create persistent spell card effect around boss (pentagram, spinning circle, rotating text)
    private func createSpellCardEffect(for bossEntity: GKEntity) {
        // Remove any existing spell card effect
        removeSpellCardEffect()
        
        currentBossEntity = bossEntity
        
        let scaleX = size.width / gameEngine.playArea.width
        let scaleY = size.height / gameEngine.playArea.height
        let scale = max(scaleX, scaleY)
        
        // Create container node for all spell card elements (follows boss position)
        let container = SKNode()
        container.zPosition = Constants.ZLayer.spellCard  // Above everything
        effectLayer.addChild(container)
        spellCardContainer = container
        
        // Create pentagram node (will spin clockwise)
        let pentagramNode = SKNode()
        container.addChild(pentagramNode)
        let pentagramRadius: CGFloat = 80 * scale
        let pentagram = createPentagram(radius: pentagramRadius)
        pentagram.strokeColor = .red
        pentagram.fillColor = .clear
        pentagram.lineWidth = 2.0
        pentagram.alpha = 0.9
        pentagramNode.addChild(pentagram)
        
        // Create red circle with pulsing opacity (TH06 style)
        let circleRadius: CGFloat = 100 * scale
        let circle = SKShapeNode(circleOfRadius: circleRadius)
        circle.strokeColor = .red
        circle.fillColor = .clear
        circle.lineWidth = 2.0
        circle.alpha = 0.6  // Start at lower opacity for pulsing effect
        container.addChild(circle)
        spellCardCircle = circle
        
        // Create text container (will spin counter-clockwise, opposite to pentagram)
        let textContainer = SKNode()
        container.addChild(textContainer)
        
        // Create "SPELL CARD" text arranged in a circle, curving along the circle
        // Repeat the text multiple times to fill the circle
        let textRadius: CGFloat = 90 * scale
        let textString = "SPELL CARD"
        let repetitions = 3  // Repeat 3 times around the circle
        let fullText = String(repeating: textString, count: repetitions)
        let textCount = fullText.count
        
        var characterIndex = 0
        let textNodes: [SKLabelNode] = fullText.compactMap { character in
            // Calculate angle for this character (distribute evenly around circle)
            let angle = (CGFloat(characterIndex) / CGFloat(textCount)) * 2 * .pi - .pi / 2  // Start at top
            characterIndex += 1
            
            let x = cos(angle) * textRadius
            let y = sin(angle) * textRadius
            
            let label = SKLabelNode(text: String(character))
            label.fontName = "Menlo-Bold"
            label.fontSize = 14 * scale
            label.fontColor = .white
            label.position = CGPoint(x: x, y: y)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            // Rotate to be tangent to the circle (perpendicular to radius)
            // For text to curve along circle, rotation = angle + π/2
            label.zRotation = angle + .pi / 2
            return label
        }
        
        for textNode in textNodes {
            textContainer.addChild(textNode)
        }
        
        // Pentagram spins clockwise (continuous loop)
        let pentagramSpin = SKAction.rotate(byAngle: 2 * .pi, duration: 2.0)
        let pentagramSpinForever = SKAction.repeatForever(pentagramSpin)
        pentagramNode.run(pentagramSpinForever)
        
        // Text container spins counter-clockwise (opposite to pentagram)
        let textSpin = SKAction.rotate(byAngle: -2 * .pi, duration: 2.0)
        let textSpinForever = SKAction.repeatForever(textSpin)
        textContainer.run(textSpinForever)
        
        // Pulsing opacity effect for circle (TH06 style)
        let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 1.0)
        let fadeOut = SKAction.fadeAlpha(to: 0.4, duration: 1.0)
        let pulseSequence = SKAction.sequence([fadeIn, fadeOut])
        let pulseForever = SKAction.repeatForever(pulseSequence)
        circle.run(pulseForever)
        
        // Pulsing opacity effect for pentagram (subtle)
        let pentagramFadeIn = SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        let pentagramFadeOut = SKAction.fadeAlpha(to: 0.7, duration: 1.2)
        let pentagramPulseSequence = SKAction.sequence([pentagramFadeIn, pentagramFadeOut])
        let pentagramPulseForever = SKAction.repeatForever(pentagramPulseSequence)
        pentagram.run(pentagramPulseForever)
    }
    
    /// Update spell card effect to follow boss position
    private func updateSpellCardEffect() {
        // Don't update when paused
        guard !gameEngine.isTimeFrozen else { return }
        
        guard let container = spellCardContainer,
              let bossEntity = currentBossEntity,
              let transform = bossEntity.component(ofType: TransformComponent.self) else {
            return
        }
        
        // Update position to follow boss
        let scaleX = size.width / gameEngine.playArea.width
        let scaleY = size.height / gameEngine.playArea.height
        let scenePosition = CGPoint(x: transform.position.x * scaleX, y: transform.position.y * scaleY)
        container.position = scenePosition
    }
    
    /// Pause spell card effect animations
    private func pauseSpellCardEffect() {
        guard let container = spellCardContainer,
              let circle = spellCardCircle else { return }
        
        // Pause all actions
        container.isPaused = true
        circle.isPaused = true
    }
    
    /// Resume spell card effect animations
    private func resumeSpellCardEffect() {
        guard let container = spellCardContainer,
              let circle = spellCardCircle else { return }
        
        // Resume all actions
        container.isPaused = false
        circle.isPaused = false
    }
    
    /// Remove spell card effect when boss is defeated
    private func removeSpellCardEffect() {
        spellCardContainer?.removeFromParent()
        spellCardContainer = nil
        spellCardCircle = nil
        currentBossEntity = nil
    }
    
    /// Create a pentagram shape
    private func createPentagram(radius: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let points = 5
        var vertices: [CGPoint] = []
        
        // Calculate pentagram vertices
        for i in 0..<points {
            let angle = (CGFloat(i) * 2 * .pi / CGFloat(points)) - .pi / 2  // Start at top
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            vertices.append(CGPoint(x: x, y: y))
        }
        
        // Draw pentagram: connect every other point
        path.move(to: vertices[0])
        path.addLine(to: vertices[2])
        path.addLine(to: vertices[4])
        path.addLine(to: vertices[1])
        path.addLine(to: vertices[3])
        path.closeSubpath()
        
        let shape = SKShapeNode(path: path)
        return shape
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
            SKAction.run { [weak self] in
                self?.gameEngine.fireEvent(SceneReadyForTransitionEvent(nextStageId: nextStageId, totalScore: totalScore))
            }
        ]))
    }
}
