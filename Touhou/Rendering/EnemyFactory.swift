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
        
        // Register with component systems after entity is fully set up
        GameFacade.shared.registerEntity(entity)
        
        return entity
    }
    
    static func createBoss(name: String, position: CGPoint, entityManager: EntityManager) -> GKEntity {
        let entity = entityManager.createEntity()
        entity.addComponent(BossComponent(name: name, health: 300))
        // Also treat boss as an enemy for collision/targeting and scoring
        entity.addComponent(EnemyComponent(
            enemyType: .custom("boss_\(name)"),
            scoreValue: 5000,
            dropItem: .life,
            attackPattern: .tripleShot,
            patternConfig: PatternConfig(physics: PhysicsConfig(speed: 120), visual: VisualConfig(shape: .star, color: .purple), bulletCount: 8, spread: 80, spiralSpeed: 12),
            shotInterval: 1.2
        ))
        entity.addComponent(TransformComponent(position: position, velocity: CGVector(dx: 0, dy: 0)))
        entity.addComponent(HitboxComponent(enemyHitbox: 16))
        entity.addComponent(HealthComponent(current: 20, max: 20))
        
        // Register with component systems after entity is fully set up
        GameFacade.shared.registerEntity(entity)
        
        return entity
    }
}


