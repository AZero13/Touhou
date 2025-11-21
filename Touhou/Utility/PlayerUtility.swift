//
//  PlayerUtility.swift
//  Touhou
//
//  Created by Rose on 11/01/25.
//

import Foundation
import CoreGraphics
import GameplayKit

enum PlayerUtility {
    @inlinable
    static func getPosition(entityManager: EntityManager) -> CGPoint? {
        entityManager.getPlayerEntity()?.component(ofType: TransformComponent.self)?.position
    }
    
    @inlinable
    static func angleToPlayer(from position: CGPoint, playerPosition: CGPoint) -> CGFloat {
        atan2(playerPosition.y - position.y, playerPosition.x - position.x)
    }
    
    @inlinable
    static func angleToPlayer(from position: CGPoint, entityManager: EntityManager) -> CGFloat? {
        guard let playerPos = getPosition(entityManager: entityManager) else { return nil }
        return angleToPlayer(from: position, playerPosition: playerPos)
    }
    
    @inlinable
    static func velocityToPlayer(from position: CGPoint, playerPosition: CGPoint, speed: CGFloat) -> CGVector {
        let angle = angleToPlayer(from: position, playerPosition: playerPosition)
        return CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
    }
    
    @inlinable
    static func velocityToPlayer(from position: CGPoint, speed: CGFloat, entityManager: EntityManager) -> CGVector? {
        guard let playerPos = getPosition(entityManager: entityManager) else { return nil }
        return velocityToPlayer(from: position, playerPosition: playerPos, speed: speed)
    }
    
    @inlinable
    static func distanceToPlayer(from position: CGPoint, playerPosition: CGPoint) -> CGFloat {
        let dx = playerPosition.x - position.x
        let dy = playerPosition.y - position.y
        return sqrt(dx * dx + dy * dy)
    }
    
    @inlinable
    static func distanceToPlayer(from position: CGPoint, entityManager: EntityManager) -> CGFloat? {
        guard let playerPos = getPosition(entityManager: entityManager) else { return nil }
        return distanceToPlayer(from: position, playerPosition: playerPos)
    }
}
