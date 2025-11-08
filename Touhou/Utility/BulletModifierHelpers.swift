//
//  BulletModifierHelpers.swift
//  Touhou
//
//  Created by Rose on 11/01/25.
//

import Foundation
import GameplayKit

/// Helper utilities to apply motion modifiers to bullets via selectors
enum BulletModifierHelpers {
    /// Apply modifier function to bullets matching selector
    static func applyToBullets(
        entityManager: EntityManager,
        selector: BulletSelector,
        modifier: (GKEntity, BulletMotionModifiersComponent) -> Void
    ) {
        let bullets = entityManager.getEntities(with: BulletComponent.self)
        for entity in bullets {
            guard let bullet = entity.component(ofType: BulletComponent.self) else { continue }
            if !selector.matches(bullet: bullet) { continue }
            
            let mods = entity.component(ofType: BulletMotionModifiersComponent.self)
                ?? BulletMotionModifiersComponent()
            if entity.component(ofType: BulletMotionModifiersComponent.self) == nil {
                entity.addComponent(mods)
            }
            modifier(entity, mods)
        }
    }
    
    /// Freeze all bullets (both player and enemy) - set timeScale = 0
    static func freezeAllBullets(entityManager: EntityManager) {
        applyToBullets(entityManager: entityManager, selector: .all) { _, mods in
            mods.timeScale = 0.0
        }
    }
    
    /// Freeze all enemy bullets (set timeScale = 0)
    static func freezeEnemyBullets(entityManager: EntityManager) {
        applyToBullets(entityManager: entityManager, selector: .enemy) { _, mods in
            mods.timeScale = 0.0
        }
    }
    
    /// Unfreeze bullets matching selector (set timeScale = 1.0)
    static func unfreezeBullets(entityManager: EntityManager, selector: BulletSelector) {
        applyToBullets(entityManager: entityManager, selector: selector) { _, mods in
            mods.timeScale = 1.0
        }
    }
    
    /// Unfreeze all bullets
    static func unfreezeAllBullets(entityManager: EntityManager) {
        applyToBullets(entityManager: entityManager, selector: .all) { _, mods in
            mods.timeScale = 1.0
        }
    }
    
    /// Set timeScale for bullets matching selector
    static func setTimeScale(entityManager: EntityManager, selector: BulletSelector, scale: CGFloat) {
        applyToBullets(entityManager: entityManager, selector: selector) { _, mods in
            mods.timeScale = scale
        }
    }
}

/// Selector for targeting specific bullet groups
enum BulletSelector {
    case all
    case enemy
    case player
    case tags(Set<String>)
    case groupId(Int)
    case patternId(Int)
    
    @inlinable
    func matches(bullet: BulletComponent) -> Bool {
        switch self {
        case .all:
            return true
        case .enemy:
            return !bullet.ownedByPlayer
        case .player:
            return bullet.ownedByPlayer
        case .tags(let requiredTags):
            return !requiredTags.isDisjoint(with: bullet.tags)
        case .groupId(let id):
            return bullet.groupId == id
        case .patternId(let id):
            return bullet.patternId == id
        }
    }
}

