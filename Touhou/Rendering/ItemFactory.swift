//
//  ItemFactory.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// ItemFactory centralizes creation of item entities
final class ItemFactory {
    static func createEntity(type: ItemType, position: CGPoint, velocity: CGVector, entityManager: EntityManager) -> GKEntity {
        let entity = entityManager.createEntity()
        entity.addComponent(ItemComponent(itemType: type, value: 0))
        entity.addComponent(TransformComponent(position: position, velocity: velocity))
        
        // Register with component systems after entity is fully set up
        GameFacade.shared.registerEntity(entity)
        
        return entity
    }
}


