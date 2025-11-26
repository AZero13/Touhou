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
        if let bossComponent = event.entity.component(ofType: BossComponent.self) {
            // Check if this is a midboss (phaseNumber == 0)
            let isMidboss = bossComponent.phaseNumber == 0
            
            if isMidboss {
                // Midboss defeated - make it fly away instead of despawning
                makeMidbossFlee(entity: event.entity, bossComponent: bossComponent)
            }
            
            // Boss defeated
            BulletUtility.convertBulletsToPoints(entityManager: entityManager, context: context)
            eventBus.fire(AttractItemsEvent(itemTypes: [.point, .pointBullet]))
            
            // Award time bonus if applicable
            if bossComponent.hasTimeBonus && !bossComponent.isTimeExpired {
                let bonus = bossComponent.calculateTimeBonus()
                if bonus > 0 {
                    if let transform = event.entity.component(ofType: TransformComponent.self) {
                        eventBus.fire(TimeBonusAwardedEvent(
                            bonusPoints: bonus,
                            bossName: bossComponent.name,
                            position: transform.position
                        ))
                        context.combat.addScore(bonus)
                    }
                }
            }
        } else {
            // Regular enemy defeated - drop items
            if let itemType = event.dropItem,
               let transform = event.entity.component(ofType: TransformComponent.self) {
                context.entities.spawnItem(type: itemType, at: transform.position, velocity: CGVector(dx: 0, dy: 40))
            }
        }
    }
    
    private func makeMidbossFlee(entity: GKEntity, bossComponent: BossComponent) {
        guard let transform = entity.component(ofType: TransformComponent.self),
              let enemyComponent = entity.component(ofType: EnemyComponent.self) else { return }
        
        // Disable shooting
        enemyComponent.shotInterval = .infinity
        
        // Make midboss fly upward to escape
        let playArea = GameFacade.playArea
        let escapePosition = CGPoint(x: playArea.midX, y: playArea.height + 50) // Above screen
        transform.moveTo(position: escapePosition, duration: 1.5)
        
        print("HealthSystem: Midboss \(bossComponent.name) defeated, fleeing upward")
    }
}
