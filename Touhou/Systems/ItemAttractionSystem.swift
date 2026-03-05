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
    private weak var engine: GameEngine!
    
    func initialize(engine: GameEngine) {
        self.engine = engine
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
        for item in engine.entityManager.getAllComponents(ItemComponent.self) {
            if types.contains(item.itemType) {
                item.isAttractedToPlayer = true
            }
        }
    }
}


