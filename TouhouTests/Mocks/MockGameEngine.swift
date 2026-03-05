//
//  MockGameEngine.swift
//  TouhouTests
//
//  Created by Antigravity on 11/27/25.
//

import Foundation
import CoreGraphics
import SpriteKit
import GameplayKit
@testable import Touhou

@MainActor
final class MockGameEngine: GameEngine {
    var entityManager: EntityManaging
    var eventBus: EventDispatching
    
    var mockEntityManager: MockEntityManager { entityManager as! MockEntityManager }
    var mockEventBus: MockEventBus { eventBus as! MockEventBus }
    var currentStage: Int = 1
    var isTimeFrozen: Bool = false
    var isInNotStartedState: Bool = false
    var playArea: CGRect = CGRect(x: 0, y: 0, width: 800, height: 600)
    var player: GKEntity? = nil
    
    // For tracking test state
    var scoreAdded: Int = 0
    var powerAdded: Int = 0
    var livesAdded: Int = 0
    
    init() {
        self.entityManager = MockEntityManager()
        self.eventBus = MockEventBus()
    }
    
    init(entityManager: MockEntityManager, eventBus: MockEventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(_ currentTime: TimeInterval) {}
    func restartGame() {}
    func startNewRun() {}
    func startStage(stageId: Int) {}
    func endStage() {}
    
    func registerEntity(_ entity: GKEntity) { mockEntityManager.addEntity(entity) }
    func unregisterEntity(_ entity: GKEntity) { mockEntityManager.removeEntity(entity) }
    
    func registerListener(_ listener: EventListener) { eventBus.register(listener: listener) }
    func unregisterListener(_ listener: EventListener) { eventBus.unregister(listener) }
    func fireEvent(_ event: GameEvent) { eventBus.fire(event) }
    func processEvents() { }
    
    func spawnBoss(data: BossData) -> GKEntity { GKEntity() }
    func spawnFairy(position: CGPoint, attackPattern: EnemyPattern, patternConfig: PatternConfig, shotInterval: TimeInterval, dropItem: ItemType?) -> GKEntity { GKEntity() }
    func spawnBullet(position: CGPoint, velocity: CGVector, bulletType: BulletComponent.BulletType, ownedByPlayer: Bool, physics: PhysicsConfig, visual: VisualConfig, behavior: BehaviorConfig) {}
    func spawnItem(type: ItemType, at position: CGPoint, velocity: CGVector) {}
    func destroy(_ entity: GKEntity) {}
    func destroyAllBullets(where filter: ((BulletComponent) -> Bool)?) {}
    
    func damage(_ entity: GKEntity, amount: Int) {}
    func heal(_ entity: GKEntity, amount: Int) {}
    func gainLives(_ amount: Int) { livesAdded += amount }
    func loseLife() {}
    func gainBombs(_ amount: Int) {}
    func loseBomb() {}
    func gainPower(_ amount: Int) { powerAdded += amount }
    func losePower(_ amount: Int) {}
    func addScore(_ amount: Int) { scoreAdded += amount }
    func activateBomb(playerEntity: GKEntity) {}
    func spawnEnemyBullet(_ command: BulletSpawnCommand) {}
    func spawnEnemyLaser(_ command: LaserSpawnCommand) {}
    func fireItemCollectionEvent(itemType: ItemType, value: Int, position: CGPoint) {}
}
