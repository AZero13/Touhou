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
    private weak var engine: GameEngine!
    
    private var stageTimer: TimeInterval = 0
    private var stageTimeline: StageTimeline?
    private var stageCompleteDispatched: Bool = false
    private var bossSpawned: Bool = false  // True when stage boss entity has appeared
    private var dialogueTriggered: Bool = false  // True when dialogue has been triggered
    private var timelineCompleteTime: TimeInterval? // When timeline completed
    private var isBossArenaClearing: Bool = false
    private var bossSpawnDelayDeadline: TimeInterval?
    private var pendingBossSpawnDelay: TimeInterval?
    
    private enum Constants {
        static let offScreenBottomThreshold: CGFloat = -50.0 // Y position for off-screen (below)
        static let offScreenTopThreshold: CGFloat = 480.0 // Y position for off-screen (above)
        static let bossSpawnBreakDuration: TimeInterval = 1.5
        static let preBossDialogueDelay: TimeInterval = 1.5  // Time to wait for cleanup before dialogue
    }
    
    func initialize(engine: GameEngine) {
        self.engine = engine
        
        // Load stage script for initial stage explicitly to avoid re-entrancy
        loadStageScript(stageId: 1)
    }
    
    private var completionPending: Bool = false
    private var completionTimer: TimeInterval = 0
    private let completionDelay: TimeInterval = 3.0 // 3 seconds delay for item collection
    
    func update(deltaTime: TimeInterval) {
        stageTimer += deltaTime
        
        // Update timeline-based spawning
        updateSpawning(deltaTime: deltaTime)
        
        // Update enemy movement
        updateEnemyMovement(deltaTime: deltaTime)
        
        // Handle stage 1 boss dialogue trigger (boss spawning is handled by timeline)
        checkAndTriggerBossDialogue()
        processBossSpawnSequence()
        
        // Check for stage completion
        checkStageCompletion(deltaTime: deltaTime)
    }
    
    // MARK: - Update Helpers
    
    private func updateSpawning(deltaTime: TimeInterval) {
        guard let timeline = stageTimeline else { return }
        
        timeline.update(deltaTime: deltaTime)
        
        // Track when timeline completes
        if timeline.isComplete && timelineCompleteTime == nil {
            timelineCompleteTime = stageTimer
            print("EnemySystem: ✓ Timeline complete at time \(stageTimer), stage \(engine.currentStage)")
            
            // Clear all enemies and bullets when timeline completes (for stage 1 dialogue)
            clearRegularEnemies()
            BulletUtility.convertBulletsToPoints(engine: engine)
            print("EnemySystem: Cleared enemies and bullets for boss dialogue")
        }
    }
    
    private func checkAndTriggerBossDialogue() {
        // Stage 1: Trigger dialogue when timeline completes and arena is clear
        // Boss spawning is handled by timeline, but we need to trigger dialogue first
        guard engine.currentStage == 1, !dialogueTriggered else { return }
        
        // Wait for cleanup to complete before triggering dialogue
        guard let completeTime = timelineCompleteTime else { return }
        
        let timeSinceComplete = stageTimer - completeTime
        
        // Check if cleanup is done (enemies and bullets cleared)
        let remainingEnemies = engine.entityManager.getEntities(with: EnemyComponent.self)
            .filter { $0.component(ofType: BossComponent.self) == nil }
        let remainingBullets = engine.entityManager.getEntities(with: BulletComponent.self)
        
        // Trigger dialogue after delay and when arena is clear
        if timeSinceComplete >= Constants.preBossDialogueDelay && 
           remainingEnemies.isEmpty && 
           remainingBullets.isEmpty {
            print("EnemySystem: ✓ Arena cleared, triggering stage 1 boss dialogue NOW")
            engine.fireEvent(DialogueTriggeredEvent(dialogueId: "stage1_boss"))
            dialogueTriggered = true  // Prevent re-triggering dialogue
        }
    }
    
    private func clearRegularEnemies() {
        let enemies = engine.entityManager.getEntities(with: EnemyComponent.self)
        for enemy in enemies {
            // Only despawn non-boss enemies (bosses have BossComponent)
            if enemy.component(ofType: BossComponent.self) == nil {
                engine.destroy(enemy)
            }
        }
    }
    
    private func beginBossArrivalSequence(delay: TimeInterval = Constants.bossSpawnBreakDuration) {
        // This is called when SpawnStageBossEvent is received (stage 1 dialogue flow)
        // Boss spawning is handled by timeline, but we need to clear arena first
        guard !bossSpawned,
              !isBossArenaClearing,
              bossSpawnDelayDeadline == nil,
              pendingBossSpawnDelay == nil else { return }
        
        pendingBossSpawnDelay = delay
        isBossArenaClearing = true
        
        // Clear arena before boss appears
        clearRegularEnemies()
        BulletUtility.clearBullets(entityManager: engine.entityManager, destroyEntity: engine.destroy)
    }
    
    private func processBossSpawnSequence() {
        if isBossArenaClearing {
            let remainingEnemies = engine.entityManager
                .getEntities(with: EnemyComponent.self)
                .filter { $0.component(ofType: BossComponent.self) == nil }
            let activeBullets = engine.entityManager.getEntities(with: BulletComponent.self)
            
            if remainingEnemies.isEmpty && activeBullets.isEmpty {
                isBossArenaClearing = false
                let delay = pendingBossSpawnDelay ?? Constants.bossSpawnBreakDuration
                bossSpawnDelayDeadline = ProcessInfo.processInfo.systemUptime + delay
                pendingBossSpawnDelay = nil
            }
        }
        
        if let deadline = bossSpawnDelayDeadline {
            let now = ProcessInfo.processInfo.systemUptime
            if now >= deadline {
                bossSpawnDelayDeadline = nil
                // Spawn boss using unified spawning mechanism (same as timeline)
                spawnStageBoss()
            }
        }
    }
    
    private func spawnStageBoss() {
        // Unified boss spawning - same mechanism used by timeline
        // Rumia has 2 phases: first uses rumiaShot, second uses rumiaShot2
        let boss = engine.spawnBoss(
            name: "Stage Boss",
            health: 300,
            position: CGPoint(x: 192, y: 360),
            phaseNumber: 1,
            attackPattern: .rumiaShot,
            patternConfig: PatternConfig(
                physics: PhysicsConfig(speed: 100),
                visual: VisualConfig(size: .small, shape: .circle, color: .red)
            ),
            shotInterval: 1.2,
            totalPhases: 2,
            phaseHealths: [300, 300]  // Two phases, 300 health each
        )
        bossSpawned = true
        engine.fireEvent(BossIntroStartedEvent(bossEntity: boss))
        print("EnemySystem: Stage boss spawned via unified system with \(boss.component(ofType: BossComponent.self)?.totalPhases ?? 1) phases")
    }

    private func checkStageCompletion(deltaTime: TimeInterval) {
        guard !stageCompleteDispatched else { return }
        
        // Check if stage boss (phase 1+) currently exists and is not marked for destruction
        let stageBosses = engine.entityManager.getEntities(with: BossComponent.self).filter { entity in
            let bossComp = entity.component(ofType: BossComponent.self)
            let isStageBoss = (bossComp?.phaseNumber ?? 0) >= 1
            let isNotMarked = !engine.entityManager.isMarkedForDestruction(entity)
            return isStageBoss && isNotMarked
        }
        
        // If stage boss exists but bossSpawned isn't true yet, mark it
        if !stageBosses.isEmpty && !bossSpawned {
            print("EnemySystem: Stage boss entity detected, marking bossSpawned = true")
            bossSpawned = true
        }
        
        // Only trigger completion if boss WAS spawned and is NOW defeated (empty or all marked for destruction)
        if bossSpawned && stageBosses.isEmpty {
            // Also check that regular enemies are gone (excluding those marked for destruction)
            let remainingEnemies = engine.entityManager.getEntities(with: EnemyComponent.self)
                .filter { !engine.entityManager.isMarkedForDestruction($0) }
            
            if remainingEnemies.isEmpty {
                // Start completion timer if not already pending
                if !completionPending {
                    print("EnemySystem: Boss defeated, starting completion timer (\(completionDelay)s)")
                    completionPending = true
                    completionTimer = completionDelay
                }
                
                // Update timer
                completionTimer -= deltaTime
                
                if completionTimer <= 0 {
                    stageCompleteDispatched = true
                    completionPending = false
                    
                    // Stage 1: trigger victory dialogue after boss defeated
                    if engine.currentStage == 1 {
                        print("EnemySystem: Stage boss defeated, triggering victory dialogue")
                        engine.fireEvent(DialogueTriggeredEvent(dialogueId: "stage1_victory"))
                    } else {
                        // Other stages: transition immediately
                        let nextId = engine.currentStage >= GameFacade.maxStage ? (GameFacade.maxStage + 1) : (engine.currentStage + 1)
                        let totalScore = engine.entityManager.getPlayerComponent()?.score ?? 0
                        print("Boss defeated! Transitioning from stage \(engine.currentStage) to stage \(nextId)")
                        engine.fireEvent(StageTransitionEvent(nextStageId: nextId, totalScore: totalScore))
                    }
                }
            }
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        if let s = event as? StageStartedEvent {
            print("EnemySystem: Stage \(s.stageId) started, resetting state")
            stageTimer = 0
            stageCompleteDispatched = false
            bossSpawned = false
            dialogueTriggered = false
            stageTimeline = nil
            timelineCompleteTime = nil
            isBossArenaClearing = false
            bossSpawnDelayDeadline = nil
            pendingBossSpawnDelay = nil
            loadStageScript(stageId: s.stageId)
        } else if event is SpawnStageBossEvent {
            // Stage 1: Dialogue triggers this event, clear arena before timeline spawns boss
            print("EnemySystem: SpawnStageBossEvent received, clearing arena for boss spawn")
            beginBossArrivalSequence()
        } else if let victory = event as? StageVictoryEvent {
            // Victory dialogue completed — trigger stage transition
            let nextId = victory.stageId >= GameFacade.maxStage ? (GameFacade.maxStage + 1) : (victory.stageId + 1)
            let totalScore = engine.entityManager.getPlayerComponent()?.score ?? 0
            print("EnemySystem: StageVictoryEvent for stage \(victory.stageId), transitioning to stage \(nextId)")
            engine.fireEvent(StageTransitionEvent(nextStageId: nextId, totalScore: totalScore))
        }
    }
    
    // MARK: - Private Methods
    
    private func loadStageScript(stageId: Int) {
        switch stageId {
        case 1:
            // Use timeline for stage 1 (defined in StageTimelineDefinitions)
            stageTimeline = StageTimelineDefinitions.createStage1Timeline()
            stageTimeline?.initialize(engine: engine)
            stageTimeline?.start()
        default:
            // Use timeline for default stages too
            stageTimeline = StageTimelineDefinitions.createDefaultStageTimeline(stageId: stageId)
            stageTimeline?.initialize(engine: engine)
            stageTimeline?.start()
        }
    }
    
    private func updateEnemyMovement(deltaTime: TimeInterval) {
        // During freeze, only bosses can move (and only bosses exist during boss fights)
        // No need to check - if freeze is active and enemies exist, they're bosses that should move
        let enemies = engine.entityManager.getEntities(with: EnemyComponent.self)
        
        for enemy in enemies {
            guard let transform = enemy.component(ofType: TransformComponent.self) else { continue }
            
            // Skip entities already marked for destruction to prevent duplicate processing
            if engine.entityManager.isMarkedForDestruction(enemy) {
                continue
            }
            
            // Movement is handled by EnemyComponent.update() (component system)
            // We only check for offscreen here to avoid duplicate position updates
            
            // Mark enemies that go offscreen for destruction
            let bossComponent = enemy.component(ofType: BossComponent.self)
            let isBoss = bossComponent != nil
            
            // Entities spawn at top (y ~420) and exit bottom (y < -50)
            // Bosses can also exit top when fleeing (y > 480)
            let offscreenBottom = transform.position.y < Constants.offScreenBottomThreshold
            let offscreenTop = isBoss && transform.position.y > Constants.offScreenTopThreshold
            
            if offscreenBottom || offscreenTop {
                if isBoss {
                    // Only allow bosses to despawn once defeated or timed out; otherwise keep them alive
                    if let bossComponent = bossComponent,
                       (bossComponent.isDefeated || bossComponent.isTimeExpired) {
                        print("EnemySystem: Boss went offscreen (y: \(transform.position.y)), despawning")
                        engine.fireEvent(BossFledEvent(bossEntity: enemy))
                        engine.destroy(enemy)
                    }
                } else {
                    engine.destroy(enemy)
                }
            }
        }
    }
}
