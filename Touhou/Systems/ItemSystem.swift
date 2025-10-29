//
//  ItemSystem.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

class ItemSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Move items and check collection
        let items = entityManager.getEntities(with: ItemComponent.self)
        for item in items {
            guard let transform = item.component(ofType: TransformComponent.self) else { continue }
            
            // Basic downward drift
            transform.position.y += transform.velocity.dy * deltaTime
            
            // Despawn off-screen
            if transform.position.y < -50 { entityManager.markForDestruction(item) }
            
            // Check collection with player
            if let player = entityManager.getEntities(with: PlayerComponent.self).first,
               let playerTransform = player.component(ofType: TransformComponent.self) {
                let dx = transform.position.x - playerTransform.position.x
                let dy = transform.position.y - playerTransform.position.y
                let distance = CGFloat(hypot(Double(dx), Double(dy)))
                let collectionRadius: CGFloat = player.component(ofType: HitboxComponent.self)?.itemCollectionZone ?? 20
                if distance < collectionRadius {
                    if let itemComp = item.component(ofType: ItemComponent.self) {
                        // Emit power-up collected
                        eventBus.fire(PowerUpCollectedEvent(itemType: itemComp.itemType, value: itemComp.value))
                        entityManager.markForDestruction(item)
                    }
                }
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        if let died = event as? EnemyDiedEvent {
            // Spawn a single item if enemy has a drop
            if let itemType = died.dropItem,
               let enemyTransform = died.entity.component(ofType: TransformComponent.self) {
                let item = entityManager.createEntity()
                item.addComponent(ItemComponent(itemType: itemType, value: itemType == .power ? 1 : (itemType == .point ? 10 : 1)))
                item.addComponent(TransformComponent(position: enemyTransform.position, velocity: CGVector(dx: 0, dy: -50)))
            }
        }
    }
}


