//
//  ItemAttractionSystem.swift
//  Touhou
//
//  Created by Assistant on 11/04/25.
//

import Foundation
import GameplayKit
import CoreGraphics

/// ItemAttractionSystem - centralizes logic for attracting items to the player
final class ItemAttractionSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // No per-frame work; item motion handled by ItemComponent
    }
    
    func handleEvent(_ event: GameEvent) {
        if let died = event as? EnemyDiedEvent {
            // When a boss dies, attract point-like items
            let isBoss = died.entity.component(ofType: BossComponent.self) != nil
            if isBoss {
                attractItems(ofTypes: [.point, .pointBullet])
            }
        } else if let attract = event as? AttractItemsEvent {
            attractItems(ofTypes: attract.itemTypes)
        }
    }
    
    private func attractItems(ofTypes types: [ItemType]) {
        let items = entityManager.getEntities(with: ItemComponent.self)
        for e in items {
            guard let item = e.component(ofType: ItemComponent.self) else { continue }
            if types.contains(item.itemType) {
                item.isAttractedToPlayer = true
            }
        }
    }
}


