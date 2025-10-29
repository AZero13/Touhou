//
//  BulletSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// BulletSystem - handles bullet movement and lifecycle
final class BulletSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Get all bullet entities
        let bulletEntities = entityManager.getEntities(with: BulletComponent.self)
        
        for entity in bulletEntities {
            guard let transform = entity.component(ofType: TransformComponent.self) else { continue }
            
            // Update position based on velocity
            transform.position.x += transform.velocity.dx * deltaTime
            transform.position.y += transform.velocity.dy * deltaTime
            
            // Mark bullets that are out of bounds for destruction
            if transform.position.x < 0 || transform.position.x > 384 ||
               transform.position.y < 0 || transform.position.y > 448 {
                GameFacade.shared.getCommandQueue().enqueue(.destroyEntity(entity))
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        // Handle bomb events to clear bullets
        if event is BombActivatedEvent {
            // Clear all enemy bullets
            let bulletEntities = entityManager.getEntities(with: BulletComponent.self)
            for entity in bulletEntities {
                if let bullet = entity.component(ofType: BulletComponent.self),
                   !bullet.ownedByPlayer {
                    GameFacade.shared.getCommandQueue().enqueue(.destroyEntity(entity))
                }
            }
        }
    }
}
