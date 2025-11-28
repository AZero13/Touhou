//
//  GameEngine.swift
//  Touhou
//
//  Created by Antigravity on 11/27/25.
//

import Foundation
import GameplayKit

@MainActor
protocol GameEngine: AnyObject {
    var entities: EntityFacade { get }
    var entityManager: EntityManaging { get }
    var eventBus: EventDispatching { get }
    var currentStage: Int { get }
    var isTimeFrozen: Bool { get set }
    var isInNotStartedState: Bool { get }
    var playArea: CGRect { get }
    
    func update(_ currentTime: TimeInterval)
    func restartGame()
    func startNewRun()
    func startStage(stageId: Int)
    func endStage()
    
    func registerEntity(_ entity: GKEntity)
    func unregisterEntity(_ entity: GKEntity)
    
    func registerListener(_ listener: EventListener)
    func unregisterListener(_ listener: EventListener)
    func fireEvent(_ event: GameEvent)
    func processEvents()
    
    func activateBomb(playerEntity: GKEntity)
}
