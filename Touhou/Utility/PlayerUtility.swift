//
//  PlayerUtility.swift
//  Touhou
//
//  Created by Assistant on 11/01/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// Centralized player utility functions for scripts (like th06's g_Player.AngleToPlayer)
enum PlayerUtility {
    /// Get player position, or nil if player doesn't exist
    static func getPosition(entityManager: EntityManager) -> CGPoint? {
        return entityManager.getPlayerEntity()?.component(ofType: TransformComponent.self)?.position
    }
    
    /// Calculate angle from given position to player (in radians, 0 = right, π/2 = down)
    /// Returns nil if player doesn't exist
    @inlinable
    static func angleToPlayer(from position: CGPoint, playerPosition: CGPoint) -> CGFloat {
        let dx = playerPosition.x - position.x
        let dy = playerPosition.y - position.y
        return atan2(dy, dx)
    }
    
    /// Calculate angle from given position to player (in radians, 0 = right, π/2 = down)
    /// Returns nil if player doesn't exist
    static func angleToPlayer(from position: CGPoint, entityManager: EntityManager) -> CGFloat? {
        guard let playerPos = getPosition(entityManager: entityManager) else { return nil }
        return angleToPlayer(from: position, playerPosition: playerPos)
    }
    
    /// Calculate velocity vector towards player from given position with specified speed
    /// Returns nil if player doesn't exist
    @inlinable
    static func velocityToPlayer(from position: CGPoint, playerPosition: CGPoint, speed: CGFloat) -> CGVector {
        let angle = angleToPlayer(from: position, playerPosition: playerPosition)
        return CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
    }
    
    /// Calculate velocity vector towards player from given position with specified speed
    /// Returns nil if player doesn't exist
    static func velocityToPlayer(from position: CGPoint, speed: CGFloat, entityManager: EntityManager) -> CGVector? {
        guard let playerPos = getPosition(entityManager: entityManager) else { return nil }
        return velocityToPlayer(from: position, playerPosition: playerPos, speed: speed)
    }
    
    /// Calculate distance from given position to player
    /// Returns nil if player doesn't exist
    @inlinable
    static func distanceToPlayer(from position: CGPoint, playerPosition: CGPoint) -> CGFloat {
        let dx = playerPosition.x - position.x
        let dy = playerPosition.y - position.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Calculate distance from given position to player
    /// Returns nil if player doesn't exist
    static func distanceToPlayer(from position: CGPoint, entityManager: EntityManager) -> CGFloat? {
        guard let playerPos = getPosition(entityManager: entityManager) else { return nil }
        return distanceToPlayer(from: position, playerPosition: playerPos)
    }
}


