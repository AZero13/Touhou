//
//  GameEvent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// Base protocol for all game events
protocol GameEvent {
    var timestamp: TimeInterval { get }
}

/// Collision categories for strongly-typed collision events
enum CollisionKind {
    case playerBulletHitEnemy
    case enemyBulletHitPlayer
    case enemyTouchPlayer
}

// MARK: - Gameplay & Logic Events

struct EnemyDiedEvent: GameEvent {
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

struct PlayerDiedEvent: GameEvent {
    let timestamp: TimeInterval
    let entity: GKEntity
    
    init(entity: GKEntity) {
        self.timestamp = CACurrentMediaTime()
        self.entity = entity
    }
}

struct PlayerRespawnedEvent: GameEvent {
    let timestamp: TimeInterval
    let entity: GKEntity
    
    init(entity: GKEntity) {
        self.timestamp = CACurrentMediaTime()
        self.entity = entity
    }
}

struct CollisionOccurredEvent: GameEvent {
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

struct BombActivatedEvent: GameEvent {
    let timestamp: TimeInterval
    let playerEntity: GKEntity
    
    init(playerEntity: GKEntity) {
        self.timestamp = CACurrentMediaTime()
        self.playerEntity = playerEntity
    }
}


// MARK: - Player & Resource Events

struct PowerUpCollectedEvent: GameEvent {
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

struct GrazeEvent: GameEvent {
    let timestamp: TimeInterval
    let bulletEntity: GKEntity
    let grazeValue: Int
    
    init(bulletEntity: GKEntity, grazeValue: Int) {
        self.timestamp = CACurrentMediaTime()
        self.bulletEntity = bulletEntity
        self.grazeValue = grazeValue
    }
}

struct EnemyHitEvent: GameEvent {
    let timestamp: TimeInterval
    let enemyEntity: GKEntity
    let hitPosition: CGPoint  // Position where the hit occurred (bullet position)
    
    init(enemyEntity: GKEntity, hitPosition: CGPoint) {
        self.timestamp = CACurrentMediaTime()
        self.enemyEntity = enemyEntity
        self.hitPosition = hitPosition
    }
}

struct ScoreChangedEvent: GameEvent {
    let timestamp: TimeInterval
    let newTotal: Int
    
    init(newTotal: Int) {
        self.timestamp = CACurrentMediaTime()
        self.newTotal = newTotal
    }
}

struct PowerLevelChangedEvent: GameEvent {
    let timestamp: TimeInterval
    let newTotal: Int
    
    init(newTotal: Int) {
        self.timestamp = CACurrentMediaTime()
        self.newTotal = newTotal
    }
}

struct LivesChangedEvent: GameEvent {
    let timestamp: TimeInterval
    let newTotal: Int
    
    init(newTotal: Int) {
        self.timestamp = CACurrentMediaTime()
        self.newTotal = newTotal
    }
}

struct BombsChangedEvent: GameEvent {
    let timestamp: TimeInterval
    let newTotal: Int
    
    init(newTotal: Int) {
        self.timestamp = CACurrentMediaTime()
        self.newTotal = newTotal
    }
}

// MARK: - Scene & Presentation Events

struct StageTransitionEvent: GameEvent {
    let timestamp: TimeInterval
    let nextStageId: Int
    
    init(nextStageId: Int) {
        self.timestamp = CACurrentMediaTime()
        self.nextStageId = nextStageId
    }
}

struct StageStartedEvent: GameEvent {
    let timestamp: TimeInterval
    let stageId: Int
    
    init(stageId: Int) {
        self.timestamp = CACurrentMediaTime()
        self.stageId = stageId
    }
}

struct StageEndedEvent: GameEvent {
    let timestamp: TimeInterval
    let stageId: Int
    
    init(stageId: Int) {
        self.timestamp = CACurrentMediaTime()
        self.stageId = stageId
    }
}

struct BossIntroStartedEvent: GameEvent {
    let timestamp: TimeInterval
    let bossEntity: GKEntity
    
    init(bossEntity: GKEntity) {
        self.timestamp = CACurrentMediaTime()
        self.bossEntity = bossEntity
    }
}


struct PlaySoundEffectEvent: GameEvent {
    let timestamp: TimeInterval
    let sfxName: String
    let volume: Float
    
    init(sfxName: String, volume: Float = 1.0) {
        self.timestamp = CACurrentMediaTime()
        self.sfxName = sfxName
        self.volume = volume
    }
}

struct PlayMusicTrackEvent: GameEvent {
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

struct GamePausedEvent: GameEvent {
    let timestamp: TimeInterval
    
    init() {
        self.timestamp = CACurrentMediaTime()
    }
}

struct GameResumedEvent: GameEvent {
    let timestamp: TimeInterval
    
    init() {
        self.timestamp = CACurrentMediaTime()
    }
}

struct PauseMenuUpdateEvent: GameEvent {
    let timestamp: TimeInterval
    let selectedOption: PauseMenuOption
    
    init(selectedOption: PauseMenuOption) {
        self.timestamp = CACurrentMediaTime()
        self.selectedOption = selectedOption
    }
}

struct PauseMenuHiddenEvent: GameEvent {
    let timestamp: TimeInterval
    
    init() {
        self.timestamp = CACurrentMediaTime()
    }
}

struct GameOverEvent: GameEvent {
    let timestamp: TimeInterval
    let finalScore: Int
    
    init(finalScore: Int) {
        self.timestamp = CACurrentMediaTime()
        self.finalScore = finalScore
    }
}

struct HighScoreChangedEvent: GameEvent {
    let timestamp: TimeInterval
    let newHighScore: Int
    
    init(newHighScore: Int) {
        self.timestamp = CACurrentMediaTime()
        self.newHighScore = newHighScore
    }
}
