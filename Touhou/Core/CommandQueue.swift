//
//  CommandQueue.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// A small, typed command queue to buffer world mutations between system updates
final class CommandQueue {
    enum Command {
        case spawnBullet(BulletSpawnCommand, ownedByPlayer: Bool)
        case destroyEntity(GKEntity)
    }
    
    private var queue: [Command] = []
    
    func enqueue(_ command: Command) {
        queue.append(command)
    }
    
    func clear() {
        queue.removeAll()
    }
    
    /// Apply all queued commands immediately
    func process(entityManager: EntityManager) {
        guard !queue.isEmpty else { return }
        for command in queue {
            switch command {
            case let .spawnBullet(cmd, ownedByPlayer):
                spawnBullet(cmd, ownedByPlayer: ownedByPlayer, entityManager: entityManager)
            case let .destroyEntity(entity):
                entityManager.markForDestruction(entity)
            }
        }
        queue.removeAll()
    }
    
    // MARK: - Helpers
    private func spawnBullet(_ cmd: BulletSpawnCommand, ownedByPlayer: Bool, entityManager: EntityManager) {
        let entity = entityManager.createEntity()
        let bullet = BulletComponent(
            ownedByPlayer: ownedByPlayer,
            bulletType: cmd.bulletType,
            damage: cmd.physics.damage,
            homingStrength: cmd.behavior.homingStrength,
            maxTurnRate: cmd.behavior.maxTurnRate,
            size: cmd.visual.size,
            shape: cmd.visual.shape,
            color: cmd.visual.color,
            hasTrail: cmd.visual.hasTrail,
            trailLength: cmd.visual.trailLength
        )
        entity.addComponent(bullet)
        entity.addComponent(TransformComponent(position: cmd.position, velocity: cmd.velocity))
    }
}


