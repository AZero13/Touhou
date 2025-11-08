//
//  ItemAttractionSystem.swift
//  Touhou
//
//  Created by Rose on 11/04/25.
//

import Foundation
import GameplayKit
import CoreGraphics

final class ItemAttractionSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
    }
    
    func handleEvent(_ event: GameEvent) {
        switch event {
        case let died as EnemyDiedEvent:
            if died.entity.component(ofType: BossComponent.self) != nil {
                attractItems(ofTypes: [.point, .pointBullet])
            }
        case let attract as AttractItemsEvent:
            attractItems(ofTypes: attract.itemTypes)
        default:
            break
        }
    }
    
    private func attractItems(ofTypes types: [ItemType]) {
        for item in entityManager.getAllComponents(ItemComponent.self) {
            if types.contains(item.itemType) {
                item.isAttractedToPlayer = true
            }
        }
    }
}


