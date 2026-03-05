//
//  GameHUD.swift
//  Touhou
//
//  Created by Antigravity on 11/27/25.
//

import SpriteKit
import GameplayKit

@MainActor
class GameHUD {
    // MARK: - Properties
    private weak var scene: SKScene?
    private var uiLayer: SKNode
    private weak var engine: GameEngine?
    
    // Pause menu UI
    private var pauseMenuNode: SKNode?
    private var closeLabel: SKLabelNode?
    private var restartLabel: SKLabelNode?
    
    // Midboss timer UI
    private var timeBonusLabel: SKLabelNode?
    
    // Dialogue UI
    private var dialogueBox: SKNode?
    private var dialogueSpeakerLabel: SKLabelNode?
    private var dialogueTextLabel: SKLabelNode?
    private var dialogueAnnotationLabel: SKLabelNode?
    private var spellNameLabel: SKLabelNode?
    private var currentDialogue: DialogueSequence?
    private var currentDialogueIndex: Int = 0
    private var wasTimeFrozenBeforeDialogue: Bool = false
    
    // Timer state tracking for timeout sound
    private var lastTimerSeconds: Int = -1
    
    // MARK: - Initialization
    init(uiLayer: SKNode) {
        self.uiLayer = uiLayer
    }
    
    func setup(in scene: SKScene, engine: GameEngine) {
        self.scene = scene
        self.engine = engine
        
        createPauseMenu(size: scene.size)
        createTimeBonusTimer(size: scene.size)
        createDialogueBox(size: scene.size)
        createSpellNameLabel(size: scene.size)
    }
    
    // MARK: - Pause Menu
    
    private func createPauseMenu(size: CGSize) {
        let menuNode = SKNode()
        menuNode.name = Constants.NodeName.pauseMenu
        menuNode.isHidden = true
        
        // Title
        let titleLabel = SKLabelNode(text: "PAUSE")
        titleLabel.fontName = Constants.Font.bold
        titleLabel.fontSize = Constants.UI.titleFontSize
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        menuNode.addChild(titleLabel)
        
        // Close option
        let close = SKLabelNode(text: "CLOSE")
        close.fontName = Constants.Font.main
        close.fontSize = Constants.UI.headerFontSize
        close.fontColor = .white
        close.position = CGPoint(x: size.width / 2, y: size.height / 2)
        close.name = Constants.NodeName.closeButton
        menuNode.addChild(close)
        self.closeLabel = close
        
        // Restart option
        let restart = SKLabelNode(text: "RESTART")
        restart.fontName = Constants.Font.main
        restart.fontSize = Constants.UI.headerFontSize
        restart.fontColor = .white
        restart.position = CGPoint(x: size.width / 2, y: size.height / 2 - 40)
        restart.name = Constants.NodeName.restartButton
        menuNode.addChild(restart)
        self.restartLabel = restart
        
        // Add dark overlay
        let overlay = SKSpriteNode(color: .black, size: size)
        overlay.alpha = 0.7
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = -1
        menuNode.addChild(overlay)
        
        menuNode.zPosition = Constants.ZLayer.pauseMenu // Above everything
        uiLayer.addChild(menuNode)
        self.pauseMenuNode = menuNode
    }
    
    func showPauseMenu() {
        pauseMenuNode?.isHidden = false
    }
    
    func hidePauseMenu() {
        pauseMenuNode?.isHidden = true
    }
    
    func updatePauseMenuSelection(selectedOption: PauseMenuOption) {
        // Highlight selected option (white), dim unselected (gray)
        switch selectedOption {
        case .close:
            closeLabel?.fontColor = .white
            closeLabel?.fontName = Constants.Font.bold
            restartLabel?.fontColor = .gray
            restartLabel?.fontName = Constants.Font.main
        case .restart:
            closeLabel?.fontColor = .gray
            closeLabel?.fontName = Constants.Font.main
            restartLabel?.fontColor = .white
            restartLabel?.fontName = Constants.Font.bold
        }
    }
    
    // MARK: - Dialogue UI
    
    private func createDialogueBox(size: CGSize) {
        let boxNode = SKNode()
        boxNode.name = Constants.NodeName.dialogueBox
        boxNode.isHidden = true
        boxNode.zPosition = Constants.ZLayer.dialogue  // Above everything
        
        // Dark background box at bottom of screen
        let boxHeight: CGFloat = 140
        let background = SKSpriteNode(color: NSColor(white: 0.0, alpha: 0.85), size: CGSize(width: size.width, height: boxHeight))
        background.position = CGPoint(x: size.width / 2, y: boxHeight / 2)
        boxNode.addChild(background)
        
        // Speaker name label (top-left of box)
        let speakerLabel = SKLabelNode(text: "REIMU")
        speakerLabel.fontName = Constants.Font.bold
        speakerLabel.fontSize = 18
        speakerLabel.fontColor = .white
        speakerLabel.horizontalAlignmentMode = .left
        speakerLabel.verticalAlignmentMode = .top
        speakerLabel.position = CGPoint(x: 20, y: boxHeight - 10)
        boxNode.addChild(speakerLabel)
        self.dialogueSpeakerLabel = speakerLabel
        
        // Dialogue text label (center of box)
        let textLabel = SKLabelNode(text: "")
        textLabel.fontName = Constants.Font.main
        textLabel.fontSize = Constants.UI.defaultFontSize
        textLabel.fontColor = .white
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = size.width - 40
        textLabel.horizontalAlignmentMode = .left
        textLabel.verticalAlignmentMode = .top
        textLabel.position = CGPoint(x: 20, y: boxHeight - 40)
        boxNode.addChild(textLabel)
        self.dialogueTextLabel = textLabel
        
        // Annotation label (bottom-right)
        let annotationLabel = SKLabelNode(text: "")
        annotationLabel.fontName = Constants.Font.italic
        annotationLabel.fontSize = 14
        annotationLabel.fontColor = .gray
        annotationLabel.horizontalAlignmentMode = .right
        annotationLabel.verticalAlignmentMode = .bottom
        annotationLabel.position = CGPoint(x: size.width - 20, y: 10)
        boxNode.addChild(annotationLabel)
        self.dialogueAnnotationLabel = annotationLabel
        
        // Prompt indicator (bottom-right corner)
        let promptLabel = SKLabelNode(text: "Press Z to continue")
        promptLabel.fontName = Constants.Font.main
        promptLabel.fontSize = Constants.UI.smallFontSize
        promptLabel.fontColor = .lightGray
        promptLabel.horizontalAlignmentMode = .right
        promptLabel.verticalAlignmentMode = .bottom
        promptLabel.position = CGPoint(x: size.width - 20, y: 5)
        promptLabel.name = Constants.NodeName.promptIndicator
        
        // Blinking animation for prompt
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.5)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        promptLabel.run(.repeatForever(.sequence([fadeOut, fadeIn])))
        
        boxNode.addChild(promptLabel)
        
        uiLayer.addChild(boxNode)
        self.dialogueBox = boxNode
    }
    
    func startDialogue(dialogueId: String) {
        print("GameHUD: Starting dialogue - \(dialogueId)")
        guard let dialogue = DialogueData.getDialogue(id: dialogueId) else {
            print("GameHUD: ERROR - Dialogue '\(dialogueId)' not found!")
            return
        }
        
        currentDialogue = dialogue
        currentDialogueIndex = 0
        wasTimeFrozenBeforeDialogue = engine?.isTimeFrozen ?? false
        engine?.isTimeFrozen = true
        
        // Show dialogue box
        dialogueBox?.isHidden = false
        
        // Display first line
        showDialogueLine(at: 0)
    }
    
    private func showDialogueLine(at index: Int) {
        guard let dialogue = currentDialogue, index < dialogue.lines.count else {
            endDialogue()
            return
        }
        
        let line = dialogue.lines[index]
        
        // Fire any trigger attached to this dialogue line (data-driven, no hardcoding)
        if let trigger = line.trigger {
            engine?.fireEvent(trigger)
        }
        
        // Update speaker name (data-driven via speakerName or default for speaker type)
        let displayName = line.speakerName ?? DialogueData.defaultSpeakerName(for: line.speaker)
        dialogueSpeakerLabel?.text = displayName
        
        switch line.speaker {
        case .reimu:
            dialogueSpeakerLabel?.fontColor = .white
        case .boss:
            dialogueSpeakerLabel?.fontColor = .yellow
        }
        
        // Update text
        dialogueTextLabel?.text = line.text
        
        // Update annotation (or hide if nil)
        if let annotation = line.annotation {
            dialogueAnnotationLabel?.text = annotation
            dialogueAnnotationLabel?.isHidden = false
        } else {
            dialogueAnnotationLabel?.isHidden = true
        }
    }
    
    func advanceDialogue() {
        guard currentDialogue != nil else { return }
        
        currentDialogueIndex += 1
        
        if let dialogue = currentDialogue, currentDialogueIndex < dialogue.lines.count {
            showDialogueLine(at: currentDialogueIndex)
        } else {
            endDialogue()
        }
    }
    
    private func endDialogue() {
        guard let dialogue = currentDialogue else { return }
        
        // Hide dialogue box
        dialogueBox?.isHidden = true
        engine?.isTimeFrozen = wasTimeFrozenBeforeDialogue
        
        // Fire dialogue completion event
        engine?.fireEvent(DialogueCompletedEvent(dialogueId: dialogue.id))
        
        // Fire completion event if one is attached (e.g., StageVictoryEvent)
        if let completionEvent = dialogue.completionEvent {
            engine?.fireEvent(completionEvent)
        }
        
        // Clear current dialogue
        currentDialogue = nil
        currentDialogueIndex = 0
    }
    
    var isDialogueActive: Bool {
        return dialogueBox?.isHidden == false
    }
    
    // MARK: - Time Bonus Timer UI
    
    private func createTimeBonusTimer(size: CGSize) {
        let label = SKLabelNode(text: "TIME 00")
        label.fontName = Constants.Font.bold
        label.fontSize = Constants.UI.defaultFontSize
        label.fontColor = .white
        label.horizontalAlignmentMode = .right
        label.verticalAlignmentMode = .top
        // Boss bar is at size.height - 60; place the timer safely below that
        label.position = CGPoint(x: size.width - 10, y: size.height - 90)
        label.zPosition = Constants.ZLayer.timeBonus  // Above everything
        label.isHidden = true
        uiLayer.addChild(label)
        self.timeBonusLabel = label
    }
    
    // MARK: - Spell Card Name UI
    
    private func createSpellNameLabel(size: CGSize) {
        let label = SKLabelNode(text: "")
        label.fontName = Constants.Font.bold
        label.fontSize = Constants.UI.defaultFontSize
        label.fontColor = .yellow
        label.horizontalAlignmentMode = .left
        // Use bottom alignment so the label grows upward from its position
        label.verticalAlignmentMode = .bottom
        // Left align to health bar (health bar starts at 10% from left: (width - width*0.8)/2 = width*0.1)
        let healthBarLeftX = size.width * 0.1
        label.position = CGPoint(x: healthBarLeftX, y: size.height / 2)
        label.zPosition = Constants.ZLayer.spellName
        label.isHidden = true
        uiLayer.addChild(label)
        self.spellNameLabel = label
    }
    
    /// Show the current spell card name (TH06 style): appear near center, float up above boss bar.
    func showSpellName(_ text: String) {
        guard let scene = scene else { return }
        
        if spellNameLabel == nil {
            createSpellNameLabel(size: scene.size)
        }
        guard let label = spellNameLabel else { return }
        
        label.removeAllActions()
        label.text = text
        label.alpha = 1.0
        label.isHidden = false
        
        let size = scene.size
        // Left align to health bar (health bar starts at 10% from left: (width - width*0.8)/2 = width*0.1)
        let healthBarLeftX = size.width * 0.1
        // Start slightly above center so the whole ascent stays visible
        let startPosition = CGPoint(x: healthBarLeftX, y: size.height * 0.55)
        label.position = startPosition
        
        // Target position: just above the boss health bar, left-aligned
        let barHeight: CGFloat = 12
        // Must stay in sync with RenderSystem's boss bar Y offset
        let barY = size.height - 60
        // Since verticalAlignmentMode is .bottom, this is the bottom of the text box.
        // Place it a few points above the bar, but well within the viewport.
        let targetY = barY + barHeight + 4
        let targetPosition = CGPoint(x: healthBarLeftX, y: targetY)
        
        let moveUp = SKAction.move(to: targetPosition, duration: 0.8)
        moveUp.timingMode = .easeOut
        label.run(moveUp)
    }
    
    func hideSpellName() {
        spellNameLabel?.isHidden = true
        spellNameLabel?.removeAllActions()
    }
    
    func updateBossUI(bossLayer: SKNode) {
        guard let engine = engine else { return }
        let bosses = engine.entityManager.getEntities(with: BossComponent.self)
        
        // No bosses? Hide all boss UI
        guard let boss = bosses.first,
              let bossComp = boss.component(ofType: BossComponent.self) else {
            bossLayer.isHidden = true
            timeBonusLabel?.isHidden = true
            hideSpellName()
            return
        }
        
        // Hide timer if boss is defeated
        if bossComp.isDefeated {
            timeBonusLabel?.isHidden = true
            // Hide health bar when boss is defeated (it will flee or vanish)
            bossLayer.isHidden = true
            hideSpellName()
            return
        }
        
        // Boss exists and not defeated - show boss bar
        bossLayer.isHidden = false
        
        // Update timer if boss has time bonus
        if bossComp.hasTimeBonus {
            timeBonusLabel?.isHidden = false
            let remainingTime = max(0, bossComp.timeLimit - bossComp.elapsedTime)
            let seconds = Int(ceil(remainingTime))
            timeBonusLabel?.text = "TIME \(seconds)"
            
            // Play timeout sound when timer ticks down while yellow or red
            if remainingTime < 10.0 && seconds < lastTimerSeconds && lastTimerSeconds >= 0 {
                // Timer is yellow/red and just ticked down - play timeout sound
                engine.eventBus.fire(TimerTickEvent())
            }
            lastTimerSeconds = seconds
            
            // Change color based on remaining time (red when running out)
            if remainingTime < 5.0 {
                timeBonusLabel?.fontColor = .red
            } else if remainingTime < 10.0 {
                timeBonusLabel?.fontColor = .yellow
            } else {
                timeBonusLabel?.fontColor = .white
            }
        } else {
            timeBonusLabel?.isHidden = true
            lastTimerSeconds = -1  // Reset timer tracking
        }
    }
    
    func hideBossUI(bossLayer: SKNode) {
        bossLayer.isHidden = true
        timeBonusLabel?.isHidden = true
        hideSpellName()
    }
}
