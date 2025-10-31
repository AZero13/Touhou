//
//  SceneCoordinator.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import SpriteKit
import GameplayKit

/// Coordinates SpriteKit scene presentation and transitions
@MainActor
final class SceneCoordinator: EventListener {
    static let shared = SceneCoordinator()
    private init() {
        GameFacade.shared.registerListener(self)
    }
    
    private weak var skView: SKView?
    
    func configure(with view: SKView) {
        self.skView = view
    }
    
    // MARK: - Public API
    func presentGameplayScene(transition: SKTransition? = nil) {
        guard let view = skView else { return }
        let scene = GameScene()
        scene.scaleMode = .aspectFill
        scene.size = view.bounds.size
        if let t = transition { view.presentScene(scene, transition: t) }
        else { view.presentScene(scene) }
    }
    
    func presentWinScene(totalScore: Int, transition: SKTransition? = nil) {
        guard let view = skView else { return }
        let scene = WinScene(totalScore: totalScore) { [weak self] in
            GameFacade.shared.startNewRun()
            let fade = SKTransition.fade(withDuration: 1.0)
            self?.presentGameplayScene(transition: fade)
        }
        scene.scaleMode = .aspectFill
        scene.size = view.bounds.size
        if let t = transition { view.presentScene(scene, transition: t) }
        else { view.presentScene(scene) }
    }
    
    func presentScoreScene(totalScore: Int, nextStageId: Int, transition: SKTransition? = nil) {
        guard let view = skView else { return }
        if nextStageId > GameFacade.maxStage {
            presentWinScene(totalScore: totalScore, transition: transition)
            return
        }
        let scene = ScoreScene(totalScore: totalScore, nextStageId: nextStageId) { [weak self] in
            GameFacade.shared.startStage(stageId: nextStageId)
            let fade = SKTransition.fade(withDuration: 1.0)
            self?.presentGameplayScene(transition: fade)
        }
        scene.scaleMode = .aspectFill
        scene.size = view.bounds.size
        if let t = transition { view.presentScene(scene, transition: t) }
        else { view.presentScene(scene) }
    }
    
    // MARK: - EventListener
    func handleEvent(_ event: GameEvent) {
        // When a stage transitions, show intermediate score scene
        if let e = event as? StageTransitionEvent {
            let score = GameFacade.shared.getEntityManager()
                .getEntities(with: PlayerComponent.self)
                .first?
                .component(ofType: PlayerComponent.self)?.score ?? 0
            let fade = SKTransition.fade(withDuration: 1.0)
            presentScoreScene(totalScore: score, nextStageId: e.nextStageId, transition: fade)
        }
    }
}


