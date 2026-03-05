//
//  EnemyComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// EnemyComponent - handles enemy state, movement, shooting, and scoring
final class EnemyComponent: GKComponent {
    enum EnemyType: Equatable {
        case fairy
        case boss
    }
    var enemyType: EnemyType
    var scoreValue: Int
    var dropItem: ItemType? // What item this enemy drops (nil = no drop)
    var attackPattern: BulletPattern
    
    init(enemyType: EnemyType, scoreValue: Int, dropItem: ItemType? = nil, 
         attackPattern: BulletPattern) {
        self.enemyType = enemyType
        self.scoreValue = scoreValue
        self.dropItem = dropItem
        self.attackPattern = attackPattern
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    // MARK: - GameplayKit Update
    
    override func update(deltaTime: TimeInterval) {
        guard let entity = entity,
              let transform = entity.component(ofType: TransformComponent.self) else { return }
        
        // Check if boss is defeated
        let bossComponent = entity.component(ofType: BossComponent.self)
        let isDefeated = bossComponent?.isDefeated ?? false
        
        // Update target-based movement (for bosses) or constant velocity (for fairies)
        if transform.isMovingToTarget {
            transform.updateTargetMovement(deltaTime: deltaTime)
        } else if !isDefeated {
            // Apply constant velocity for fairies (or non-defeated bosses)
            transform.position.x += transform.velocity.dx * deltaTime
            transform.position.y += transform.velocity.dy * deltaTime
        }
        // If defeated and not moving to target, don't apply any movement
        
        // Mark enemies that go off bottom of screen for destruction (not bosses)
        if enemyType == .fairy && transform.position.y < GameFacade.playArea.minY - 50 {
            GameFacade.shared.destroy(entity)
            return
        }
        
        // Handle shooting
        if !GameFacade.shared.isTimeFrozen {
            handleShooting(deltaTime: deltaTime)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleShooting(deltaTime: TimeInterval) {
        guard let transform = entity?.component(ofType: TransformComponent.self) else { return }
        let position = transform.position
        
        let playerPosition = GameFacade.shared.entityManager.getPlayerEntity()?.component(ofType: TransformComponent.self)?.position
        
        let output = attackPattern.update(dt: deltaTime, position: position, target: playerPosition)
        
        for cmd in output.bullets {
            GameFacade.shared.spawnEnemyBullet(cmd)
        }
        
        for laser in output.lasers {
            let anchored = LaserSpawnCommand(
                position: laser.position,
                angle: laser.angle,
                length: laser.length,
                width: laser.width,
                previewWidth: laser.previewWidth,
                duration: laser.duration,
                warmup: laser.warmup,
                startDelay: laser.startDelay,
                activationOverride: laser.activationOverride,
                color: laser.color,
                damage: laser.damage,
                tickInterval: laser.tickInterval,
                anchor: entity
            )
            GameFacade.shared.spawnEnemyLaser(anchored)
        }
    }
}
