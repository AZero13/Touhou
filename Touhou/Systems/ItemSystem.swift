//
//  ItemSystem.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit
import CoreGraphics

/// Power item score table for Normal difficulty (when at full power >= 128)
/// Based on th06 reference: g_PowerItemScore[0..30]
private let powerItemScoreTable: [Int] = [
    10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 200, 300, 400, 500, 600, 700,
    800, 900, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 51200
]

/// Point item score calculation constants for Normal difficulty
private let pointItemTopScore = 100000      // Score when collected above y=128
private let pointItemBottomScore = 60000    // Base score when collected below y=128
private let pointItemPositionMultiplier = 100 // Multiplier for position-based scoring
private let pointItemThresholdY: CGFloat = 128 // Y position threshold (logical coordinates)

final class ItemSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Move items and check collection
        let items = entityManager.getEntities(with: ItemComponent.self)
        for item in items {
            guard let transform = item.component(ofType: TransformComponent.self) else { continue }
            
            // Basic downward drift
            transform.position.y += transform.velocity.dy * deltaTime
            
            // Despawn off-screen
            if transform.position.y < -50 { GameFacade.shared.getCommandQueue().enqueue(.destroyEntity(item)) }
            
            // Check collection with player
            if let player = entityManager.getEntities(with: PlayerComponent.self).first,
               let playerTransform = player.component(ofType: TransformComponent.self),
               let playerComp = player.component(ofType: PlayerComponent.self) {
                let dx = transform.position.x - playerTransform.position.x
                let dy = transform.position.y - playerTransform.position.y
                let distance = CGFloat(hypot(Double(dx), Double(dy)))
                let collectionRadius: CGFloat = player.component(ofType: HitboxComponent.self)?.itemCollectionZone ?? 20
                if distance < collectionRadius {
                    if let itemComp = item.component(ofType: ItemComponent.self) {
                        // Calculate value based on item type and position
                        let calculatedValue = calculateItemValue(
                            itemType: itemComp.itemType,
                            itemPosition: transform.position,
                            playerPower: playerComp.power,
                            powerItemCount: playerComp.powerItemCountForScore
                        )
                        
                        // Emit power-up collected with calculated value
                        eventBus.fire(PowerUpCollectedEvent(itemType: itemComp.itemType, value: calculatedValue))
                        GameFacade.shared.getCommandQueue().enqueue(.destroyEntity(item))
                    }
                }
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        if let died = event as? EnemyDiedEvent {
            // Spawn a single item if enemy has a drop
            if let itemType = died.dropItem,
               let enemyTransform = died.entity.component(ofType: TransformComponent.self) {
                GameFacade.shared.getCommandQueue().enqueue(.spawnItem(type: itemType, position: enemyTransform.position, velocity: CGVector(dx: 0, dy: -50)))
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Calculate item value based on th06 Normal difficulty rules
    private func calculateItemValue(itemType: ItemType, itemPosition: CGPoint, playerPower: Int, powerItemCount: Int) -> Int {
        switch itemType {
        case .point:
            // Point items: value based on y-position (Normal difficulty)
            if itemPosition.y < pointItemThresholdY {
                // Collected above threshold line: maximum value
                return pointItemTopScore
            } else {
                // Collected below threshold: decreasing value based on distance
                let yDiff = itemPosition.y - pointItemThresholdY
                let value = pointItemBottomScore - Int(yDiff * CGFloat(pointItemPositionMultiplier))
                return max(value, 0) // Ensure non-negative
            }
            
        case .power:
            // Power items: if at full power, use score table; otherwise return score value (10)
            if playerPower >= 128 {
                // At full power: return score value from table
                let index = min(powerItemCount, powerItemScoreTable.count - 1)
                return powerItemScoreTable[index]
            } else {
                // Not at full power: return score value (10), power increment handled separately
                return 10
            }
            
        case .bomb, .life:
            // Bombs and lives: no score value
            return 0
        }
    }
}


