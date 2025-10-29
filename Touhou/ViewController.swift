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
    
    // MARK: - UI flash timers
    private var scoreFlashTimer: Timer?
    private var highScoreFlashTimer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()

        GameplayView.showsFPS = true
        GameplayView.showsNodeCount = true
        GameplayView.ignoresSiblingOrder = true
        
        // Create and present a scene
        let scene = GameScene()
        scene.scaleMode = .aspectFill
        scene.size = GameplayView.bounds.size
        
        GameplayView.presentScene(scene)
        
        // Register for game events to keep UI in sync
        GameFacade.shared.getEventBus().register(listener: self)
    }
    

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: - EventListener
    func handleEvent(_ event: GameEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
                // Show last graze value increment; a future system can emit aggregate if desired
                self.GrazeLabel.stringValue = "GRAZE: +\(e.grazeValue)"
            case let e as PowerUpCollectedEvent:
                // Optional: reflect last value pickup
                if e.itemType == .point {
                    self.ValueLabel.stringValue = "VALUE: \(e.value)"
                }
            default:
                break
            }
        }
    }

    // MARK: - Private helpers
    private func flash(label: NSTextField) {
        // Turn pink immediately
        label.textColor = .systemPink
        
        // Debounce back-to-default after 1s of inactivity per label
        if label === ScoreLabel {
            scoreFlashTimer?.invalidate()
            scoreFlashTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                self?.ScoreLabel.textColor = .labelColor
            }
        } else if label === HighScoreLabel {
            highScoreFlashTimer?.invalidate()
            highScoreFlashTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                self?.HighScoreLabel.textColor = .labelColor
            }
        }
    }
}

