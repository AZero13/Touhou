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
    var entityManager: EntityManaging { get }
    var eventBus: EventDispatching { get }
    var currentStage: Int { get }
    var isTimeFrozen: Bool { get set }
    var isInNotStartedState: Bool { get }
    var playArea: CGRect { get }
    
    // MARK: - Lifecycle
    func update(_ currentTime: TimeInterval)
    func restartGame()
    func startNewRun()
    func startStage(stageId: Int)
    func endStage()
    
    // MARK: - Entity registration
    func registerEntity(_ entity: GKEntity)
    func unregisterEntity(_ entity: GKEntity)
    
    // MARK: - Events
    func registerListener(_ listener: EventListener)
    func unregisterListener(_ listener: EventListener)
    func fireEvent(_ event: GameEvent)
    func processEvents()
    
    // MARK: - Entity spawning (absorbed from EntityFacade)
    var player: GKEntity? { get }
    @discardableResult func spawnBoss(data: BossData) -> GKEntity
    @discardableResult func spawnFairy(position: CGPoint, attackPattern: EnemyPattern,
                                       patternConfig: PatternConfig, shotInterval: TimeInterval,
                                       dropItem: ItemType?) -> GKEntity
    func spawnBullet(position: CGPoint, velocity: CGVector, bulletType: BulletComponent.BulletType,
                     ownedByPlayer: Bool, physics: PhysicsConfig, visual: VisualConfig,
                     behavior: BehaviorConfig)
    func spawnItem(type: ItemType, at position: CGPoint, velocity: CGVector)
    func destroy(_ entity: GKEntity)
    func destroyAllBullets(where filter: ((BulletComponent) -> Bool)?)
    
    // MARK: - Combat (absorbed from CombatFacade)
    func damage(_ entity: GKEntity, amount: Int)
    func heal(_ entity: GKEntity, amount: Int)
    func gainLives(_ amount: Int)
    func loseLife()
    func gainBombs(_ amount: Int)
    func loseBomb()
    func gainPower(_ amount: Int)
    func losePower(_ amount: Int)
    func addScore(_ amount: Int)
    func activateBomb(playerEntity: GKEntity)
    func spawnEnemyBullet(_ command: BulletSpawnCommand)
    func spawnEnemyLaser(_ command: LaserSpawnCommand)
    func fireItemCollectionEvent(itemType: ItemType, value: Int, position: CGPoint)
}
