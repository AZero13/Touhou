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
        switch event {
        case let died as EnemyDiedEvent:
            // When a boss dies, attract point-like items
            // Use pattern matching: check if entity has BossComponent
            if died.entity.component(ofType: BossComponent.self) != nil {
                attractItems(ofTypes: [.point, .pointBullet])
            }
            
        case let attract as AttractItemsEvent:
            attractItems(ofTypes: attract.itemTypes)
            
        default:
            // Ignore other events
            break
        }
    }
    
    private func attractItems(ofTypes types: [ItemType]) {
        // Use getAllComponents to directly get item components without entity iteration
        for item in entityManager.getAllComponents(ItemComponent.self) {
            if types.contains(item.itemType) {
                item.isAttractedToPlayer = true
            }
        }
    }
}


