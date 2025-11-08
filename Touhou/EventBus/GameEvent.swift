//
//  GameEvent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// Base protocol for all game events
protocol GameEvent: Sendable {
    var timestamp: TimeInterval { get }
}

/// Collision categories for strongly-typed collision events
enum CollisionKind: Sendable {
    case playerBulletHitEnemy
    case enemyBulletHitPlayer
    case enemyTouchPlayer
}

// MARK: - Gameplay & Logic Events

struct EnemyDiedEvent: GameEvent, @unchecked Sendable {
    let timestamp: TimeInterval
    let entity: GKEntity
    let scoreValue: Int
    let dropItem: ItemType?
    
    init(entity: GKEntity, scoreValue: Int, dropItem: ItemType? = nil) {
        self.timestamp = CACurrentMediaTime()
        self.entity = entity
        self.scoreValue = scoreValue
        self.dropItem = dropItem
    }
}

struct PlayerDiedEvent: GameEvent, @unchecked Sendable {
    let timestamp: TimeInterval
    let entity: GKEntity
    
    init(entity: GKEntity) {
        self.timestamp = CACurrentMediaTime()
        self.entity = entity
    }
}

struct PlayerRespawnedEvent: GameEvent, @unchecked Sendable {
    let timestamp: TimeInterval
    let entity: GKEntity
    
    init(entity: GKEntity) {
        self.timestamp = CACurrentMediaTime()
        self.entity = entity
    }
}

struct CollisionOccurredEvent: GameEvent, @unchecked Sendable {
    let timestamp: TimeInterval
    let entityA: GKEntity
    let entityB: GKEntity
    let collisionType: CollisionKind
    let hitPosition: CGPoint  // Position captured before entity destruction
    
    init(entityA: GKEntity, entityB: GKEntity, collisionType: CollisionKind, hitPosition: CGPoint) {
        self.timestamp = CACurrentMediaTime()
        self.entityA = entityA
        self.entityB = entityB
        self.collisionType = collisionType
        self.hitPosition = hitPosition
    }
}

struct BombActivatedEvent: GameEvent, @unchecked Sendable {
    let timestamp: TimeInterval
    let playerEntity: GKEntity
    
    init(playerEntity: GKEntity) {
        self.timestamp = CACurrentMediaTime()
        self.playerEntity = playerEntity
    }
}

struct BulletsConvertedToPointsEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    
    init() {
        self.timestamp = CACurrentMediaTime()
    }
}

// MARK: - Item Attraction

/// Global signal to attract certain item types to the player (e.g., after boss defeat)
struct AttractItemsEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let itemTypes: [ItemType]
    
    init(itemTypes: [ItemType]) {
        self.timestamp = CACurrentMediaTime()
        self.itemTypes = itemTypes
    }
}

// MARK: - Player & Resource Events

struct PowerUpCollectedEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let itemType: ItemType
    let value: Int
    let position: CGPoint  // Position where item was collected
    
    init(itemType: ItemType, value: Int, position: CGPoint) {
        self.timestamp = CACurrentMediaTime()
        self.itemType = itemType
        self.value = value
        self.position = position
    }
}

struct GrazeEvent: GameEvent, @unchecked Sendable {
    let timestamp: TimeInterval
    let bulletEntity: GKEntity
    let grazeValue: Int
    
    init(bulletEntity: GKEntity, grazeValue: Int) {
        self.timestamp = CACurrentMediaTime()
        self.bulletEntity = bulletEntity
        self.grazeValue = grazeValue
    }
}

struct EnemyHitEvent: GameEvent, @unchecked Sendable {
    let timestamp: TimeInterval
    let enemyEntity: GKEntity
    let hitPosition: CGPoint
    
    init(enemyEntity: GKEntity, hitPosition: CGPoint) {
        self.timestamp = CACurrentMediaTime()
        self.enemyEntity = enemyEntity
        self.hitPosition = hitPosition
    }
}

struct ScoreChangedEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let newTotal: Int
    
    init(newTotal: Int) {
        self.timestamp = CACurrentMediaTime()
        self.newTotal = newTotal
    }
}

struct PowerLevelChangedEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let newTotal: Int
    
    init(newTotal: Int) {
        self.timestamp = CACurrentMediaTime()
        self.newTotal = newTotal
    }
}

struct LivesChangedEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let newTotal: Int
    
    init(newTotal: Int) {
        self.timestamp = CACurrentMediaTime()
        self.newTotal = newTotal
    }
}

struct BombsChangedEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let newTotal: Int
    
    init(newTotal: Int) {
        self.timestamp = CACurrentMediaTime()
        self.newTotal = newTotal
    }
}

// MARK: - Scene & Presentation Events

struct StageTransitionEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let nextStageId: Int
    let totalScore: Int
    
    init(nextStageId: Int, totalScore: Int) {
        self.timestamp = CACurrentMediaTime()
        self.nextStageId = nextStageId
        self.totalScore = totalScore
    }
}

struct SceneReadyForTransitionEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let nextStageId: Int
    let totalScore: Int
    
    init(nextStageId: Int, totalScore: Int) {
        self.timestamp = CACurrentMediaTime()
        self.nextStageId = nextStageId
        self.totalScore = totalScore
    }
}

struct StageStartedEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let stageId: Int
    
    init(stageId: Int) {
        self.timestamp = CACurrentMediaTime()
        self.stageId = stageId
    }
}

struct StageEndedEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let stageId: Int
    
    init(stageId: Int) {
        self.timestamp = CACurrentMediaTime()
        self.stageId = stageId
    }
}

struct BossIntroStartedEvent: GameEvent, @unchecked Sendable {
    let timestamp: TimeInterval
    let bossEntity: GKEntity
    
    init(bossEntity: GKEntity) {
        self.timestamp = CACurrentMediaTime()
        self.bossEntity = bossEntity
    }
}


struct PlaySoundEffectEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let sfxName: String
    let volume: Float
    
    init(sfxName: String, volume: Float = 1.0) {
        self.timestamp = CACurrentMediaTime()
        self.sfxName = sfxName
        self.volume = volume
    }
}

struct PlayMusicTrackEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let trackName: String
    let fadeIn: Bool
    
    init(trackName: String, fadeIn: Bool = true) {
        self.timestamp = CACurrentMediaTime()
        self.trackName = trackName
        self.fadeIn = fadeIn
    }
}

// MARK: - Game State Events

struct GamePausedEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    
    init() {
        self.timestamp = CACurrentMediaTime()
    }
}

struct GameResumedEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    
    init() {
        self.timestamp = CACurrentMediaTime()
    }
}

struct PauseMenuUpdateEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let selectedOption: PauseMenuOption
    
    init(selectedOption: PauseMenuOption) {
        self.timestamp = CACurrentMediaTime()
        self.selectedOption = selectedOption
    }
}

struct PauseMenuHiddenEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    
    init() {
        self.timestamp = CACurrentMediaTime()
    }
}

struct GameOverEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let finalScore: Int
    
    init(finalScore: Int) {
        self.timestamp = CACurrentMediaTime()
        self.finalScore = finalScore
    }
}

struct HighScoreChangedEvent: GameEvent, Sendable {
    let timestamp: TimeInterval
    let newHighScore: Int
    
    init(newHighScore: Int) {
        self.timestamp = CACurrentMediaTime()
        self.newHighScore = newHighScore
    }
}
