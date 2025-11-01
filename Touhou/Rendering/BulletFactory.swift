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
        // Apply TH06-style defaults for player homing amulets if behavior not specified
        let isPlayerHomingAmulet = ownedByPlayer && command.bulletType == .homingAmulet
        let defaultRetargetInterval: TimeInterval? = isPlayerHomingAmulet ? 0.066 : nil // ~4 frames @60fps
        let defaultMaxRetargets: Int? = isPlayerHomingAmulet ? nil : nil // unlimited when player homing
        let defaultRotationOffset: CGFloat = 0

        let bullet = BulletComponent(
            ownedByPlayer: ownedByPlayer,
            bulletType: command.bulletType,
            damage: command.physics.damage,
            size: command.visual.size,
            shape: command.visual.shape,
            color: command.visual.color,
            hasTrail: command.visual.hasTrail,
            trailLength: command.visual.trailLength
        )
        // Apply optional behavior settings post-init to avoid noisy constructors
        bullet.homingStrength = command.behavior.homingStrength
        bullet.maxTurnRate = command.behavior.maxTurnRate
        bullet.retargetInterval = command.behavior.retargetInterval ?? defaultRetargetInterval
        bullet.maxRetargets = command.behavior.maxRetargets ?? defaultMaxRetargets
        bullet.rotationOffset = (command.behavior.rotationOffset != 0 ? command.behavior.rotationOffset : defaultRotationOffset)
        // Identification fields for scripting/selectors
        bullet.groupId = command.groupId
        bullet.patternId = command.patternId
        bullet.tags = command.tags
        entity.addComponent(bullet)
        entity.addComponent(TransformComponent(position: command.position, velocity: command.velocity))
        return entity
    }
}


