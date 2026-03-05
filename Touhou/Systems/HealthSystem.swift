//
//  HealthSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

final class HealthSystem: GameSystem {
    private weak var engine: GameEngine!
    
    func initialize(engine: GameEngine) {
        self.engine = engine
    }
    
    func update(deltaTime: TimeInterval) {
        for healthComponent in engine.entityManager.getAllComponents(HealthComponent.self) {
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
        engine.fireEvent(EnemyHitEvent(enemyEntity: enemyEntity, hitPosition: hitPosition))
        engine.damage(enemyEntity, amount: 1)
    }
    
    private func handlePlayerHit(_ playerEntity: GKEntity) {
        engine.loseLife()
    }
    
    private func handleEnemyDeath(_ event: EnemyDiedEvent) {
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
                BulletUtility.convertBulletsToPoints(engine: engine)
                engine.fireEvent(AttractItemsEvent(itemTypes: [.point, .pointBullet]))
                
                // Fire phase transition event
                engine.fireEvent(BossPhaseTransitionEvent(bossEntity: event.entity, newPhase: bossComponent.currentPhase))
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
                engine.entityManager.markForDestruction(event.entity)
            }
            
            // Boss defeated
            BulletUtility.convertBulletsToPoints(engine: engine)
            engine.fireEvent(AttractItemsEvent(itemTypes: [.point, .pointBullet]))
            
            // Award time bonus if applicable (only once, before boss flees/vanishes)
            if bossComponent.hasTimeBonus && !bossComponent.isTimeExpired {
                let bonus = bossComponent.calculateTimeBonus()
                if bonus > 0 {
                    if let transform = event.entity.component(ofType: TransformComponent.self) {
                        engine.fireEvent(TimeBonusAwardedEvent(
                            bonusPoints: bonus,
                            bossName: bossComponent.name,
                            position: transform.position
                        ))
                        engine.addScore(bonus)
                    }
                }
            }
            
            // Fire event to hide boss UI immediately
            engine.fireEvent(BossDefeatedEvent(bossEntity: event.entity))
        } else {
            // Regular enemy defeated - drop items
            if let itemType = event.dropItem,
               let transform = event.entity.component(ofType: TransformComponent.self) {
                engine.spawnItem(type: itemType, at: transform.position, velocity: CGVector(dx: 0, dy: 40))
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
