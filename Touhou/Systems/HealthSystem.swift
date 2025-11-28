//
//  HealthSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

final class HealthSystem: GameSystem {
    private var entityManager: EntityManaging!
    private var eventBus: EventDispatching!
    
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
        if let bossComponent = event.entity.component(ofType: BossComponent.self),
           let healthComponent = event.entity.component(ofType: HealthComponent.self) {
            
            // Check if this is a multi-phase boss and current phase is defeated
            if bossComponent.totalPhases > 1 && bossComponent.currentPhase < bossComponent.totalPhases {
                // Phase transition: move to next phase
                bossComponent.currentPhase += 1
                let nextPhaseMaxHealth = bossComponent.phaseHealths[bossComponent.currentPhase - 1]
                bossComponent.currentPhaseHealth = nextPhaseMaxHealth
                // Update HealthComponent to reflect new phase
                healthComponent.updateMaxHealth(nextPhaseMaxHealth)
                healthComponent.health = nextPhaseMaxHealth
                
                // Change attack pattern for new phase (if needed)
                if let enemyComponent = event.entity.component(ofType: EnemyComponent.self) {
                    // Update pattern based on phase (e.g., phase 1 = rumiaShot, phase 2 = rumiaShot2)
                    if bossComponent.currentPhase == 2 {
                        enemyComponent.attackPattern = .rumiaShot2
                    }
                }
                
                // Convert bullets to points on phase transition
                BulletUtility.convertBulletsToPoints(entityManager: entityManager, context: context)
                eventBus.fire(AttractItemsEvent(itemTypes: [.point, .pointBullet]))
                
                // Fire phase transition event
                eventBus.fire(BossPhaseTransitionEvent(bossEntity: event.entity, newPhase: bossComponent.currentPhase))
                return  // Don't defeat boss yet
            }
            
            // All phases defeated - boss is fully defeated
            guard !bossComponent.isDefeated else { return }
            bossComponent.isDefeated = true
            
            // Check if this is a midboss (phaseNumber == 0)
            let isMidboss = bossComponent.phaseNumber == 0
            
            // Midbosses flee away, stage bosses vanish immediately
            if isMidboss {
                makeBossFlee(entity: event.entity, bossComponent: bossComponent)
            } else {
                // Stage boss: mark for destruction so it vanishes immediately
                // This allows checkStageCompletion to detect the boss is gone
                entityManager.markForDestruction(event.entity)
            }
            
            // Boss defeated
            BulletUtility.convertBulletsToPoints(entityManager: entityManager, context: context)
            eventBus.fire(AttractItemsEvent(itemTypes: [.point, .pointBullet]))
            
            // Award time bonus if applicable (only once, before boss flees/vanishes)
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
            
            // Fire event to hide boss UI immediately
            eventBus.fire(BossDefeatedEvent(bossEntity: event.entity))
        } else {
            // Regular enemy defeated - drop items
            if let itemType = event.dropItem,
               let transform = event.entity.component(ofType: TransformComponent.self) {
                context.entities.spawnItem(type: itemType, at: transform.position, velocity: CGVector(dx: 0, dy: 40))
            }
        }
    }
    
    private func makeBossFlee(entity: GKEntity, bossComponent: BossComponent) {
        guard let transform = entity.component(ofType: TransformComponent.self),
              let enemyComponent = entity.component(ofType: EnemyComponent.self) else { return }
        
        // Clear any ongoing movement pattern
        bossComponent.clearMovementPattern()
        
        // Clear any existing target movement
        transform.clearTargetMovement()
        
        // Disable shooting
        enemyComponent.shotInterval = .infinity
        
        // Make midboss fly upward to escape (force movement even though defeated)
        let playArea = GameFacade.playArea
        let escapePosition = CGPoint(x: playArea.midX, y: playArea.height + 50) // Above screen
        transform.moveTo(position: escapePosition, duration: 1.5, force: true)
        
        print("HealthSystem: Midboss \(bossComponent.name) defeated, fleeing upward")
    }
    
}
