//
//  BulletUtility.swift
//  Touhou
//
//  Created by Rose on 11/01/25.
//

import Foundation
import GameplayKit

/// Centralized bullet utility functions for clearing, selecting, and modifying bullets
/// Eliminates duplication and provides consistent API for bullet operations
enum BulletUtility {
    /// Clear all bullets matching selector (uses CommandQueue)
    static func clearBullets(entityManager: EntityManager, destroyEntity: (GKEntity) -> Void, selector: BulletSelector = .all) {
        CommandQueue.despawnAllBullets(entityManager: entityManager, destroyEntity: destroyEntity) { bullet in
            selector.matches(bullet: bullet)
        }
    }
    
    /// Clear all enemy bullets
    static func clearEnemyBullets(entityManager: EntityManager, destroyEntity: (GKEntity) -> Void) {
        clearBullets(entityManager: entityManager, destroyEntity: destroyEntity, selector: .enemy)
    }
    
    /// Clear all player bullets
    static func clearPlayerBullets(entityManager: EntityManager, destroyEntity: (GKEntity) -> Void) {
        clearBullets(entityManager: entityManager, destroyEntity: destroyEntity, selector: .player)
    }
    
    /// Clear bullets with specific tags
    static func clearBulletsWithTags(entityManager: EntityManager, destroyEntity: (GKEntity) -> Void, tags: Set<String>) {
        clearBullets(entityManager: entityManager, destroyEntity: destroyEntity, selector: .tags(tags))
    }
    
    /// Clear bullets with specific group ID
    static func clearBulletsWithGroupId(entityManager: EntityManager, destroyEntity: (GKEntity) -> Void, groupId: Int) {
        clearBullets(entityManager: entityManager, destroyEntity: destroyEntity, selector: .groupId(groupId))
    }
    
    /// Get all bullet entities matching selector
    static func getBullets(entityManager: EntityManager, selector: BulletSelector = .all) -> [GKEntity] {
        let bullets = entityManager.getEntities(with: BulletComponent.self)
        return bullets.filter { entity in
            guard let bullet = entity.component(ofType: BulletComponent.self) else { return false }
            return selector.matches(bullet: bullet)
        }
    }
    
    /// Count bullets matching selector
    static func countBullets(entityManager: EntityManager, selector: BulletSelector = .all) -> Int {
        return getBullets(entityManager: entityManager, selector: selector).count
    }
    
    /// Convert all enemy bullets to point items (TH06 boss death/phase transition style)
    static func convertBulletsToPoints(entityManager: EntityManager, context: GameRuntimeContext) {
        let enemyBullets = getBullets(entityManager: entityManager, selector: .enemy)
        
        for bullet in enemyBullets {
            guard let transform = bullet.component(ofType: TransformComponent.self) else { continue }
            
            // Spawn a pointBullet item at bullet position
            context.entities.spawnItem(type: .pointBullet, at: transform.position, velocity: .zero)
            
            // Destroy the bullet
            entityManager.markForDestruction(bullet)
        }
    }
}

