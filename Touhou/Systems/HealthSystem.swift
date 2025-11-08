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
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        for healthComponent in entityManager.getAllComponents(HealthComponent.self) {
            if healthComponent.invulnerabilityTimer > 0 {
                healthComponent.invulnerabilityTimer -= deltaTime
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        switch event {
        case let collisionEvent as CollisionOccurredEvent:
            handleCollisionEvent(collisionEvent)
        case let died as EnemyDiedEvent:
            handleEnemyDeath(died)
        default:
            break
        }
    }
    
    private func handleCollisionEvent(_ event: CollisionOccurredEvent) {
        switch event.collisionType {
        case .playerBulletHitEnemy:
            handleEnemyHit(event.entityB, hitPosition: event.hitPosition)
        case .enemyBulletHitPlayer, .enemyTouchPlayer:
            handlePlayerHit(event.entityB)
        }
    }
    
    private func handleEnemyHit(_ enemyEntity: GKEntity, hitPosition: CGPoint) {
        eventBus.fire(EnemyHitEvent(enemyEntity: enemyEntity, hitPosition: hitPosition))
        GameFacade.shared.combat.damage(enemyEntity, amount: 1)
    }
    
    private func handlePlayerHit(_ playerEntity: GKEntity) {
        GameFacade.shared.combat.adjustLives(delta: -1)
    }
    
    private func handleEnemyDeath(_ event: EnemyDiedEvent) {
        let isBoss = event.entity.component(ofType: BossComponent.self) != nil
        
        if isBoss {
            BulletUtility.convertBulletsToPoints(entityManager: entityManager)
            eventBus.fire(AttractItemsEvent(itemTypes: [.point, .pointBullet]))
        } else {
            if let itemType = event.dropItem,
               let transform = event.entity.component(ofType: TransformComponent.self) {
                GameFacade.shared.entities.spawnItem(type: itemType, at: transform.position, velocity: CGVector(dx: 0, dy: 40))
            }
        }
    }
}
