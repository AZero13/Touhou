//
//  ViewController.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Cocoa
import SpriteKit

class ViewController: NSViewController {

    @IBOutlet weak var GameplayView: SKView!
    @IBOutlet weak var HighScoreLabel: NSTextField!
    @IBOutlet weak var ScoreLabel: NSTextField!
    @IBOutlet weak var LivesLabel: NSTextField!
    @IBOutlet weak var BombsLabel: NSTextField!
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
    }
    

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

