//
//  HealthSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

final class HealthSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(context: GameRuntimeContext) {
        self.entityManager = context.entityManager
        self.eventBus = context.eventBus
    }
    
    func update(deltaTime: TimeInterval, context: GameRuntimeContext) {
        for healthComponent in entityManager.getAllComponents(HealthComponent.self) {
            if healthComponent.invulnerabilityTimer > 0 {
                healthComponent.invulnerabilityTimer -= deltaTime
            }
        }
    }
    
    func handleEvent(_ event: GameEvent, context: GameRuntimeContext) {
        switch event {
        case let collisionEvent as CollisionOccurredEvent:
            handleCollisionEvent(collisionEvent, context: context)
        case let died as EnemyDiedEvent:
            handleEnemyDeath(died, context: context)
        default:
            break
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        // Fallback for non-GameSystem listeners (shouldn't be called)
        fatalError("HealthSystem.handleEvent without context should not be called")
    }
    
    private func handleCollisionEvent(_ event: CollisionOccurredEvent, context: GameRuntimeContext) {
        switch event.collisionType {
        case .playerBulletHitEnemy:
            handleEnemyHit(event.entityB, hitPosition: event.hitPosition, context: context)
        case .enemyBulletHitPlayer, .enemyTouchPlayer:
            handlePlayerHit(event.entityB, context: context)
        }
    }
    
    private func handleEnemyHit(_ enemyEntity: GKEntity, hitPosition: CGPoint, context: GameRuntimeContext) {
        eventBus.fire(EnemyHitEvent(enemyEntity: enemyEntity, hitPosition: hitPosition))
        context.combat.damage(enemyEntity, amount: 1)
    }
    
    private func handlePlayerHit(_ playerEntity: GKEntity, context: GameRuntimeContext) {
        context.combat.loseLife()
    }
    
    private func handleEnemyDeath(_ event: EnemyDiedEvent, context: GameRuntimeContext) {
        let isBoss = event.entity.component(ofType: BossComponent.self) != nil
        
        if isBoss {
            BulletUtility.convertBulletsToPoints(entityManager: entityManager, context: context)
            eventBus.fire(AttractItemsEvent(itemTypes: [.point, .pointBullet]))
        } else {
            if let itemType = event.dropItem,
               let transform = event.entity.component(ofType: TransformComponent.self) {
                context.entities.spawnItem(type: itemType, at: transform.position, velocity: CGVector(dx: 0, dy: 40))
            }
        }
    }
}
