//
//  WinScene.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import SpriteKit

final class WinScene: SKScene {
    private let totalScore: Int
    private let onContinue: () -> Void
    
    init(totalScore: Int, onContinue: @escaping () -> Void) {
        self.totalScore = totalScore
        self.onContinue = onContinue
        super.init(size: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        buildUI()
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in self?.onContinue() }
        ]))
    }
    
    private func buildUI() {
        let title = SKLabelNode(text: "YOU WIN!")
        title.fontName = "Menlo-Bold"
        title.fontSize = 38
        title.fontColor = .systemGreen
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        addChild(title)
        
        let score = SKLabelNode(text: "FINAL SCORE: \(totalScore)")
        score.fontName = "Menlo"
        score.fontSize = 26
        score.fontColor = .white
        score.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(score)
        
        let hint = SKLabelNode(text: "Press any key to play again")
        hint.fontName = "Menlo"
        hint.fontSize = 16
        hint.fontColor = .gray
        hint.position = CGPoint(x: size.width / 2, y: size.height / 2 - 40)
        addChild(hint)
    }
    
    override func keyDown(with event: NSEvent) {
        onContinue()
    }
    
    override func mouseDown(with event: NSEvent) {
        onContinue()
    }
}
