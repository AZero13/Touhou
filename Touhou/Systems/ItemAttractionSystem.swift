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
    
    func initialize(context: GameRuntimeContext) {
        self.entityManager = context.entityManager
        self.eventBus = context.eventBus
    }
    
    func update(deltaTime: TimeInterval, context: GameRuntimeContext) {
    }
    
    func handleEvent(_ event: GameEvent, context: GameRuntimeContext) {
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
    
    func handleEvent(_ event: GameEvent) {
        // Fallback for non-GameSystem listeners (shouldn't be called)
        fatalError("ItemAttractionSystem.handleEvent without context should not be called")
    }
    
    private func attractItems(ofTypes types: [ItemType]) {
        for item in entityManager.getAllComponents(ItemComponent.self) {
            if types.contains(item.itemType) {
                item.isAttractedToPlayer = true
            }
        }
    }
}


