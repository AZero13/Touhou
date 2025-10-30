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
        
        // Configure scene coordinator and present initial gameplay scene
        SceneCoordinator.shared.configure(with: GameplayView)
        SceneCoordinator.shared.presentGameplayScene()
        
        // Register for game events to keep UI in sync
        GameFacade.shared.getEventBus().register(listener: self)
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
}

