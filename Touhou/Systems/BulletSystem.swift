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
            
            // Apply motion modifiers (freeze/time scale, speed scaling, acceleration)
            let mods = entity.component(ofType: BulletMotionModifiersComponent.self)
            let timeScale: CGFloat = mods?.timeScale ?? 1.0
            let speedScale: CGFloat = mods?.speedScale ?? 1.0
            if timeScale <= 0 { continue }
            // Acceleration
            if let a = mods?.acceleration, (a.dx != 0 || a.dy != 0) {
                transform.velocity.dx += a.dx * deltaTime
                transform.velocity.dy += a.dy * deltaTime
            }
            // Angle lock (preserve facing while allowing speed changes)
            if let angle = mods?.angleLock {
                let speed = MathUtility.magnitude(transform.velocity)
                transform.velocity = MathUtility.velocity(angle: angle, speed: speed)
            }
            
            // Update position based on effective velocity
            transform.position.x += transform.velocity.dx * deltaTime * timeScale * speedScale
            transform.position.y += transform.velocity.dy * deltaTime * timeScale * speedScale
            
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
            BulletUtility.clearEnemyBullets(entityManager: entityManager)
        }
    }
}
