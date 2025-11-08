//
//  ScoreScene.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import SpriteKit

/// Simple score scene shown between stages
final class ScoreScene: SKScene {
    private let totalScore: Int
    private let nextStageId: Int
    private let onContinue: () -> Void
    
    init(totalScore: Int, nextStageId: Int, onContinue: @escaping () -> Void) {
        self.totalScore = totalScore
        self.nextStageId = nextStageId
        self.onContinue = onContinue
        super.init(size: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        buildUI()
        // Auto-continue after short delay; also allow click/space to skip
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in self?.onContinue() }
        ]))
    }
    
    private func buildUI() {
        let title = SKLabelNode(text: "STAGE CLEAR")
        title.fontName = "Menlo-Bold"
        title.fontSize = 34
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        addChild(title)
        
        let score = SKLabelNode(text: "SCORE: \(totalScore)")
        score.fontName = "Menlo"
        score.fontSize = 26
        score.fontColor = .white
        score.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(score)
        
        let hint = SKLabelNode(text: "NEXT: STAGE \(nextStageId)  (press any key)")
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
