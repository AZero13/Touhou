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
    private var stageTimeline: StageTimeline?
    private var stageCompleteDispatched: Bool = false
    private var bossSpawned: Bool = false  // True when stage boss entity has appeared
    private var dialogueTriggered: Bool = false  // True when dialogue has been triggered
    private var timelineCompleteTime: TimeInterval? // When timeline completed
    
    private enum Constants {
        static let offScreenThreshold: CGFloat = -50.0 // Y position threshold for off-screen detection
        static let bossSpawnPosition = CGPoint(x: 192, y: 360)
        static let bossHealth: Int = 300
        static let bossPhaseNumber: Int = 1
    }
    
    func initialize(context: GameRuntimeContext) {
        self.entityManager = context.entityManager
        self.eventBus = context.eventBus
        
        // Load stage script for initial stage explicitly to avoid re-entrancy
        loadStageScript(stageId: 1, context: context)
    }
    
    func update(deltaTime: TimeInterval, context: GameRuntimeContext) {
        stageTimer += deltaTime
        
        // Update timeline or script-based spawning
        updateSpawning(deltaTime: deltaTime, context: context)
        
        // Update enemy movement
        updateEnemyMovement(deltaTime: deltaTime, context: context)
        
        // Check and handle boss spawning
        checkAndSpawnBoss(context: context)
        
        // Check for stage completion
        checkStageCompletion(context: context)
    }
    
    // MARK: - Update Helpers
    
    private func updateSpawning(deltaTime: TimeInterval, context: GameRuntimeContext) {
        if let timeline = stageTimeline {
            timeline.update(deltaTime: deltaTime)
            
            // Track when timeline completes
            if timeline.isComplete && timelineCompleteTime == nil {
                timelineCompleteTime = stageTimer
                print("EnemySystem: ✓ Timeline complete at time \(stageTimer), stage \(context.currentStage)")
            }
        } else {
            spawnEnemiesFromScript(context: context)
        }
    }
    
    private func checkAndSpawnBoss(context: GameRuntimeContext) {
        guard !bossSpawned else { return }
        
        // Don't spawn stage boss if a midboss (or any boss) is already active
        let existingBosses = entityManager.getEntities(with: BossComponent.self)
        if !existingBosses.isEmpty {
            // print("EnemySystem: Stage boss spawn blocked - existing boss(es) active")
            return
        }
        
        // Stage 1: Boss spawns via dialogue trigger (SpawnStageBossEvent), not time-based
        if context.currentStage == 1 {
            // Check if we should trigger dialogue (timeline complete + no bosses active)
            if let completeTime = timelineCompleteTime {
                let timeSinceComplete = stageTimer - completeTime
                print("EnemySystem: Stage 1 check - timeSinceComplete: \(timeSinceComplete), dialogueTriggered: \(dialogueTriggered)")
                // Trigger dialogue 2 seconds after timeline completes
                if timeSinceComplete >= 2.0 && !dialogueTriggered {
                    print("EnemySystem: ✓ Triggering stage 1 boss dialogue NOW")
                    eventBus.fire(DialogueTriggeredEvent(dialogueId: "stage1_boss"))
                    dialogueTriggered = true  // Prevent re-triggering dialogue
                }
            } else {
                print("EnemySystem: Stage 1 - waiting for timeline to complete (timelineCompleteTime is nil)")
            }
            return
        }
        
        // Other stages: time-based boss spawn (60 seconds after timeline completes)
        let shouldSpawnBoss: Bool
        if stageTimeline != nil {
            if let completeTime = timelineCompleteTime {
                shouldSpawnBoss = (stageTimer - completeTime) >= 60.0  // 1 minute delay
            } else {
                shouldSpawnBoss = false
            }
        } else {
            shouldSpawnBoss = !stageScript.isEmpty && stageScript.allSatisfy({ $0.hasSpawned })
        }
        
        if shouldSpawnBoss {
            spawnBoss(context: context)
        }
    }
    
    private func spawnBoss(context: GameRuntimeContext) {
        // Despawn any remaining regular enemies before boss appears
        clearRegularEnemies(context: context)
        
        // Despawn all bullets
        BulletUtility.clearBullets(entityManager: entityManager, destroyEntity: context.entities.destroy)
        
        // Spawn boss
        _ = context.entities.spawnBoss(
            name: "Stage Boss",
            health: Constants.bossHealth,
            position: Constants.bossSpawnPosition,
            phaseNumber: Constants.bossPhaseNumber,
            attackPattern: .tripleShot,
            patternConfig: PatternConfig(
                physics: PhysicsConfig(speed: 120),
                visual: VisualConfig(shape: .star, color: .purple),
                bulletCount: 8,
                spread: 80,
                spiralSpeed: 12
            )
        )
        bossSpawned = true
    }
    
    private func clearRegularEnemies(context: GameRuntimeContext) {
        let enemies = entityManager.getEntities(with: EnemyComponent.self)
        for enemy in enemies {
            // Only despawn non-boss enemies (bosses have BossComponent)
            if enemy.component(ofType: BossComponent.self) == nil {
                context.entities.destroy(enemy)
            }
        }
    }
    
    private func checkStageCompletion(context: GameRuntimeContext) {
        guard !stageCompleteDispatched else { return }
        
        // Check if stage boss (phase 1+) currently exists
        let stageBosses = entityManager.getEntities(with: BossComponent.self).filter { entity in
            entity.component(ofType: BossComponent.self)?.phaseNumber ?? 0 >= 1
        }
        
        // If stage boss exists but bossSpawned isn't true yet, mark it
        // This tracks that an actual boss entity has appeared
        if !stageBosses.isEmpty && !bossSpawned {
            print("EnemySystem: Stage boss entity detected, marking bossSpawned = true")
            bossSpawned = true
        }
        
        // Only trigger completion if boss WAS spawned and is NOW defeated
        if bossSpawned && stageBosses.isEmpty {
            let remainingEnemies = entityManager.getEntities(with: EnemyComponent.self)
            if remainingEnemies.isEmpty {
                stageCompleteDispatched = true
                
                // Stage 1: trigger victory dialogue after boss defeated
                if context.currentStage == 1 {
                    print("EnemySystem: Stage boss defeated, triggering victory dialogue")
                    eventBus.fire(DialogueTriggeredEvent(dialogueId: "stage1_victory"))
                } else {
                    // Other stages: transition immediately
                    let nextId = context.currentStage >= GameFacade.maxStage ? (GameFacade.maxStage + 1) : (context.currentStage + 1)
                    let totalScore = entityManager.getPlayerComponent()?.score ?? 0
                    print("Boss defeated! Transitioning from stage \(context.currentStage) to stage \(nextId)")
                    eventBus.fire(StageTransitionEvent(nextStageId: nextId, totalScore: totalScore))
                }
            }
        }
    }
    
    func handleEvent(_ event: GameEvent, context: GameRuntimeContext) {
        if let s = event as? StageStartedEvent {
            print("EnemySystem: Stage \(s.stageId) started, resetting state")
            stageTimer = 0
            stageCompleteDispatched = false
            bossSpawned = false
            dialogueTriggered = false
            stageTimeline = nil
            timelineCompleteTime = nil
            loadStageScript(stageId: s.stageId, context: context)
        } else if event is SpawnStageBossEvent {
            print("EnemySystem: SpawnStageBossEvent received, spawning stage boss immediately")
            spawnBoss(context: context)
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        // Fallback for non-GameSystem listeners (shouldn't be called)
        fatalError("EnemySystem.handleEvent without context should not be called")
    }
    
    // MARK: - Private Methods
    
    private func loadStageScript(stageId: Int, context: GameRuntimeContext) {
        switch stageId {
        case 1:
            // Use timeline for stage 1 (defined in StageTimelineDefinitions)
            stageTimeline = StageTimelineDefinitions.createStage1Timeline()
            stageTimeline?.initialize(entityManager: context.entityManager, eventBus: context.eventBus)
            stageTimeline?.start()
            stageScript = [] // Empty script - timeline handles spawning
        default:
            // Use timeline for default stages too
            stageTimeline = StageTimelineDefinitions.createDefaultStageTimeline(stageId: stageId)
            stageTimeline?.initialize(entityManager: context.entityManager, eventBus: context.eventBus)
            stageTimeline?.start()
            stageScript = [] // Empty script - timeline handles spawning
        }
    }
    
    private func spawnEnemiesFromScript(context: GameRuntimeContext) {
        // Find enemies that should spawn now
        let enemiesToSpawn = stageScript.filter { spawnEvent in
            spawnEvent.time <= stageTimer && !spawnEvent.hasSpawned
        }
        
        for spawnEvent in enemiesToSpawn {
            spawnEnemy(type: spawnEvent.type, position: spawnEvent.position, pattern: spawnEvent.pattern, patternConfig: spawnEvent.parameters, context: context)
            spawnEvent.hasSpawned = true
        }
    }
    
    private func spawnEnemy(type: EnemyComponent.EnemyType, position: CGPoint, pattern: EnemyPattern, patternConfig: PatternConfig, context: GameRuntimeContext) {
        switch type {
        case .fairy:
            // Use facade for entity creation
            context.entities.spawnFairy(
                position: position,
                attackPattern: pattern,
                patternConfig: patternConfig
            )
        case .boss:
            // Bosses are spawned separately by EnemySystem when timeline completes
            // This case exists for exhaustiveness but shouldn't be used in scripts
            break
        }
    }
    
    private func updateEnemyMovement(deltaTime: TimeInterval, context: GameRuntimeContext) {
        // During freeze, only bosses can move (and only bosses exist during boss fights)
        // No need to check - if freeze is active and enemies exist, they're bosses that should move
        let enemies = entityManager.getEntities(with: EnemyComponent.self)
        
        for enemy in enemies {
            guard let transform = enemy.component(ofType: TransformComponent.self) else { continue }
            
            // Move enemy down
            transform.position.y += transform.velocity.dy * deltaTime
            
            // Mark enemies that go off bottom of screen for destruction
            if transform.position.y < Constants.offScreenThreshold {
                context.entities.destroy(enemy)
            }
        }
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
