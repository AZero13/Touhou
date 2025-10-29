//
//  EnemyFactory.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// EnemyFactory centralizes creation of enemy entities
final class EnemyFactory {
    static func createFairy(position: CGPoint, pattern: EnemyPattern, patternConfig: PatternConfig, entityManager: EntityManager) -> GKEntity {
        let entity = entityManager.createEntity()
        entity.addComponent(EnemyComponent(
            enemyType: .fairy,
            scoreValue: 100,
            dropItem: .power,
            attackPattern: pattern,
            patternConfig: patternConfig,
            shotInterval: 2.0
        ))
        entity.addComponent(TransformComponent(position: position, velocity: CGVector(dx: 0, dy: -50)))
        entity.addComponent(HitboxComponent(enemyHitbox: 12))
        entity.addComponent(HealthComponent(current: 1, max: 1))
        return entity
    }
}


