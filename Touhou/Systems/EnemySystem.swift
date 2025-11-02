//
//  EnemySystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// EnemySystem - handles enemy spawning and movement
final class EnemySystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    private var stageTimer: TimeInterval = 0
    private var stageScript: [EnemySpawnEvent] = []
    private var stageCompleteDispatched: Bool = false
    private var bossSpawned: Bool = false
    
    private var lastShotTime: TimeInterval = 0
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
        
        // Load stage script for initial stage explicitly to avoid re-entrancy
        loadStageScript(stageId: 1)
    }
    
    func update(deltaTime: TimeInterval) {
        stageTimer += deltaTime
        
        // Check for enemies to spawn based on stage script
        spawnEnemiesFromScript()
        
        // Update enemy movement and shooting
        updateEnemyMovement(deltaTime: deltaTime)
        updateEnemyShooting(deltaTime: deltaTime)
        
        // If all scripted enemies have spawned and none remain, spawn boss once
        // Also check that we actually have a script (empty scripts shouldn't trigger boss)
        if !stageScript.isEmpty && stageScript.allSatisfy({ $0.hasSpawned }) && !bossSpawned {
            // Despawn any remaining regular enemies and all bullets before boss appears
            let enemies = entityManager.getEntities(with: EnemyComponent.self)
            for enemy in enemies {
                // Only despawn non-boss enemies (bosses have BossComponent)
                if enemy.component(ofType: BossComponent.self) == nil {
                    GameFacade.shared.entities.destroy(enemy)
                }
            }
            
            // Despawn all bullets
            BulletUtility.clearBullets(entityManager: entityManager)
            
            let boss = EnemyFactory.createBoss(name: "Stage Boss", position: CGPoint(x: 192, y: 360), entityManager: entityManager)
            bossSpawned = true
            scheduleBossSpellcard(boss: boss)
        }
        
        // After boss defeated (no enemies remain), move to score scene once
        if bossSpawned && !stageCompleteDispatched {
            let remainingEnemies = entityManager.getEntities(with: EnemyComponent.self)
            if remainingEnemies.isEmpty {
                stageCompleteDispatched = true
                let currentStage = GameFacade.shared.getCurrentStage()
                let nextId = currentStage >= GameFacade.maxStage ? (GameFacade.maxStage + 1) : (currentStage + 1)
                print("Boss defeated! Transitioning from stage \(currentStage) to stage \(nextId)")
                eventBus.fire(StageTransitionEvent(nextStageId: nextId))
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        if let s = event as? StageStartedEvent {
            print("EnemySystem: Stage \(s.stageId) started, resetting state")
            stageTimer = 0
            stageCompleteDispatched = false
            bossSpawned = false
            loadStageScript(stageId: s.stageId)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadStageScript(stageId: Int) {
        // Stage 1 script - enemies spawn at specific times with different patterns and visual variety
        switch stageId {
        case 1:
        stageScript = [
            // Basic red circles
            EnemySpawnEvent(time: 1.0, type: EnemyComponent.EnemyType.fairy, position: CGPoint(x: 100, y: 400), 
                           pattern: .singleShot, parameters: PatternConfig(
                               physics: PhysicsConfig(speed: 120),
                               visual: VisualConfig(shape: .circle, color: .red)
                           )),
            
            // Blue diamonds in triple shot
            EnemySpawnEvent(time: 2.5, type: EnemyComponent.EnemyType.fairy, position: CGPoint(x: 200, y: 400), 
                           pattern: .tripleShot, parameters: PatternConfig(
                               physics: PhysicsConfig(speed: 100),
                               visual: VisualConfig(shape: .diamond, color: .blue),
                               spread: 60
                           )),
            
            // Green aimed shots
            EnemySpawnEvent(time: 4.0, type: EnemyComponent.EnemyType.fairy, position: CGPoint(x: 300, y: 400), 
                           pattern: .aimedShot, parameters: PatternConfig(
                               physics: PhysicsConfig(speed: 140),
                               visual: VisualConfig(shape: .circle, color: .green)
                           )),
            
            // Purple stars in circle pattern
            EnemySpawnEvent(time: 6.0, type: EnemyComponent.EnemyType.fairy, position: CGPoint(x: 150, y: 400), 
                           pattern: .circleShot, parameters: PatternConfig(
                               physics: PhysicsConfig(speed: 80),
                               visual: VisualConfig(shape: .star, color: .purple),
                               bulletCount: 12
                           )),
            
            // Orange squares in spiral
            EnemySpawnEvent(time: 7.5, type: EnemyComponent.EnemyType.fairy, position: CGPoint(x: 250, y: 400), 
                           pattern: .spiralShot, parameters: PatternConfig(
                               physics: PhysicsConfig(speed: 90),
                               visual: VisualConfig(shape: .square, color: .orange),
                               bulletCount: 8,
                               spiralSpeed: 15
                           )),
            
            // Large yellow circles
            EnemySpawnEvent(time: 10.0, type: EnemyComponent.EnemyType.fairy, position: CGPoint(x: 192, y: 400), 
                           pattern: .aimedShot, parameters: PatternConfig(
                               physics: PhysicsConfig(speed: 160),
                               visual: VisualConfig(size: .large, shape: .circle, color: .yellow)
                           )),
        ]
        default:
        let speed = CGFloat(120 + (stageId - 1) * 20)
        stageScript = [
            EnemySpawnEvent(time: 1.0, type: .fairy, position: CGPoint(x: 80, y: 400), pattern: .aimedShot, parameters: PatternConfig(physics: PhysicsConfig(speed: speed))),
            EnemySpawnEvent(time: 2.0, type: .fairy, position: CGPoint(x: 192, y: 400), pattern: .tripleShot, parameters: PatternConfig(physics: PhysicsConfig(speed: speed - 10))),
            EnemySpawnEvent(time: 3.0, type: .fairy, position: CGPoint(x: 300, y: 400), pattern: .circleShot, parameters: PatternConfig(physics: PhysicsConfig(speed: speed - 20), bulletCount: 10))
        ]
        }
    }
    
    private func spawnEnemiesFromScript() {
        // Find enemies that should spawn now
        let enemiesToSpawn = stageScript.filter { spawnEvent in
            spawnEvent.time <= stageTimer && !spawnEvent.hasSpawned
        }
        
        for spawnEvent in enemiesToSpawn {
            spawnEnemy(type: spawnEvent.type, position: spawnEvent.position, pattern: spawnEvent.pattern, patternConfig: spawnEvent.parameters)
            spawnEvent.hasSpawned = true
        }
    }
    
    private func spawnEnemy(type: EnemyComponent.EnemyType, position: CGPoint, pattern: EnemyPattern, patternConfig: PatternConfig) {
        switch type {
        case .fairy:
            // Enemy shooting is now handled in EnemyComponent.update() - no TaskScheduler needed!
            let enemy = EnemyFactory.createFairy(position: position, pattern: pattern, patternConfig: patternConfig, entityManager: entityManager)
            _ = enemy // Silence unused warning
        default:
            break
        }
    }
    
    private func updateEnemyMovement(deltaTime: TimeInterval) {
        // During freeze, only bosses can move (and only bosses exist during boss fights)
        // No need to check - if freeze is active and enemies exist, they're bosses that should move
        let enemies = entityManager.getEntities(with: EnemyComponent.self)
        
        for enemy in enemies {
            guard let transform = enemy.component(ofType: TransformComponent.self) else { continue }
            
            // Move enemy down
            transform.position.y += transform.velocity.dy * deltaTime
            
            // Mark enemies that go off bottom of screen for destruction
            if transform.position.y < -50 {
                GameFacade.shared.entities.destroy(enemy)
            }
        }
    }
    
    private func updateEnemyShooting(deltaTime: TimeInterval) {
        // Shooting is driven by TaskScheduler via scheduled tasks on spawn.
    }
    
    /// Schedule boss spellcard pattern (extracted for flexibility - can be configured per boss/spellcard)
    /// Each boss should define their own spellcards based on stage/boss identity
    private func scheduleBossSpellcard(boss: GKEntity) {
        guard boss.component(ofType: EnemyComponent.self) != nil else { return }
        // Spellcards will be defined per-boss later
        // For now, bosses use their default shooting pattern from EnemyComponent
    }
}

/// Enemy spawn event for stage scripting
class EnemySpawnEvent {
    let time: TimeInterval
    let type: EnemyComponent.EnemyType
    let position: CGPoint
    let pattern: EnemyPattern
    let parameters: PatternConfig
    var hasSpawned: Bool = false
    
    init(time: TimeInterval, type: EnemyComponent.EnemyType, position: CGPoint, pattern: EnemyPattern, parameters: PatternConfig) {
        self.time = time
        self.type = type
        self.position = position
        self.pattern = pattern
        self.parameters = parameters
    }
}
