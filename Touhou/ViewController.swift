//
//  ViewController.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController, EventListener {

    @IBOutlet weak var GameplayView: SKView!
    @IBOutlet weak var HighScoreLabel: NSTextField!
    @IBOutlet weak var ScoreLabel: NSTextField!
    @IBOutlet weak var LivesLabel: NSTextField!
    @IBOutlet weak var BombsLabel: NSTextField!
    @IBOutlet weak var PowerLabel: NSTextField!
    @IBOutlet weak var ValueLabel: NSTextField!
    @IBOutlet weak var GrazeLabel: NSTextField!
    
    // MARK: - UI flash tasks
    private var scoreFlashTask: Task<Void, Never>?
    private var highScoreFlashTask: Task<Void, Never>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        GameplayView.showsFPS = true
        GameplayView.showsNodeCount = true
        GameplayView.ignoresSiblingOrder = true
        
        // Present initial gameplay scene
        presentGameplayScene()
        
        // Register for game events to keep UI in sync
        GameFacade.shared.registerListener(self)
    }
    
    // MARK: - Scene Presentation
    
    private func presentGameplayScene(transition: SKTransition? = nil) {
        let scene = GameScene()
        scene.scaleMode = .aspectFill
        scene.size = GameplayView.bounds.size
        if let t = transition {
            GameplayView.presentScene(scene, transition: t)
        } else {
            GameplayView.presentScene(scene)
        }
    }
    
    private func presentWinScene(totalScore: Int) {
        let scene = WinScene(totalScore: totalScore) { [weak self] in
            GameFacade.shared.startNewRun()
            let fade = SKTransition.fade(withDuration: 0.5)
            self?.presentGameplayScene(transition: fade)
        }
        scene.scaleMode = .aspectFill
        scene.size = GameplayView.bounds.size
        GameplayView.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }
    
    private func presentScoreScene(totalScore: Int, nextStageId: Int) {
        if nextStageId > GameFacade.maxStage {
            presentWinScene(totalScore: totalScore)
            return
        }
        let scene = ScoreScene(totalScore: totalScore, nextStageId: nextStageId) { [weak self] in
            GameFacade.shared.startStage(stageId: nextStageId)
            // Move in from top when leaving score scene to return to gameplay
            let moveInDown = SKTransition.moveIn(with: .down, duration: 1.0)
            moveInDown.pausesIncomingScene = true // Pause new gameplay scene until transition completes
            self?.presentGameplayScene(transition: moveInDown)
        }
        scene.scaleMode = .aspectFill
        scene.size = GameplayView.bounds.size
        // Move in from bottom when going to score scene
        let moveInUp = SKTransition.moveIn(with: .up, duration: 1.0)
        moveInUp.pausesOutgoingScene = true // Pause outgoing gameplay scene during transition
        GameplayView.presentScene(scene, transition: moveInUp)
    }
    

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: - EventListener
    @MainActor
    func handleEvent(_ event: GameEvent) {
        switch event {
        case let e as ScoreChangedEvent:
            self.ScoreLabel.stringValue = "SCORE: \(e.newTotal)"
            self.flash(label: self.ScoreLabel)
        case let e as HighScoreChangedEvent:
            self.HighScoreLabel.stringValue = "HIGH SCORE: \(e.newHighScore)"
            self.flash(label: self.HighScoreLabel)
        case let e as LivesChangedEvent:
            self.LivesLabel.stringValue = "LIVES: \(e.newTotal)"
        case let e as BombsChangedEvent:
            self.BombsLabel.stringValue = "BOMBS: \(e.newTotal)"
        case let e as PowerLevelChangedEvent:
            self.PowerLabel.stringValue = "POWER: \(e.newTotal)"
        case let e as GrazeEvent:
            self.GrazeLabel.stringValue = "GRAZE: +\(e.grazeValue)"
        case let e as PowerUpCollectedEvent:
            if e.value > 0 {
                self.ValueLabel.stringValue = "VALUE: \(e.value)"
            }
        case let e as SceneReadyForTransitionEvent:
            // Scene has faded out, now present the score scene
            presentScoreScene(totalScore: e.totalScore, nextStageId: e.nextStageId)
        default:
            break
        }
    }

    // MARK: - Private helpers
    private func flash(label: NSTextField) {
        label.textColor = .systemPink
        if label === ScoreLabel {
            scoreFlashTask?.cancel()
            scoreFlashTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.ScoreLabel.textColor = .labelColor
            }
        } else if label === HighScoreLabel {
            highScoreFlashTask?.cancel()
            highScoreFlashTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.HighScoreLabel.textColor = .labelColor
            }
        }
    }
    
    // MARK: - Cleanup
    deinit {
        // Cancel async tasks to prevent them from running after deallocation
        scoreFlashTask?.cancel()
        highScoreFlashTask?.cancel()
        
        // Note: EventBus uses weak references (WeakEventListener), so listeners are automatically
        // cleaned up when deallocated. No explicit unregister needed, but EventBus will
        // clean up nil references during its next processEvents() call.
        // If explicit cleanup is desired, it should be done before deallocation (e.g., in viewWillDisappear).
    }
}

