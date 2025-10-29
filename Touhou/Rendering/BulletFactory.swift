//
//  BulletFactory.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// BulletFactory centralizes creation of bullet entities from high-level commands
final class BulletFactory {
    static func createEntity(from command: BulletSpawnCommand, ownedByPlayer: Bool, entityManager: EntityManager) -> GKEntity {
        let entity = entityManager.createEntity()
        let bullet = BulletComponent(
            ownedByPlayer: ownedByPlayer,
            bulletType: command.bulletType,
            damage: command.physics.damage,
            homingStrength: command.behavior.homingStrength,
            maxTurnRate: command.behavior.maxTurnRate,
            size: command.visual.size,
            shape: command.visual.shape,
            color: command.visual.color,
            hasTrail: command.visual.hasTrail,
            trailLength: command.visual.trailLength
        )
        entity.addComponent(bullet)
        entity.addComponent(TransformComponent(position: command.position, velocity: command.velocity))
        return entity
    }
}


