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
        if stageScript.allSatisfy({ $0.hasSpawned }) && !bossSpawned {
            // Despawn any remaining regular enemies and all bullets before boss appears
            let enemies = entityManager.getEntities(with: EnemyComponent.self)
            for enemy in enemies {
                // Only despawn non-boss enemies (bosses have BossComponent)
                if enemy.component(ofType: BossComponent.self) == nil {
                    GameFacade.shared.getCommandQueue().enqueue(.destroyEntity(enemy))
                }
            }
            
            // Despawn all bullets
            CommandQueue.despawnAllBullets(entityManager: entityManager)
            
            let boss = EnemyFactory.createBoss(name: "Stage Boss", position: CGPoint(x: 192, y: 360), entityManager: entityManager)
            bossSpawned = true
            scheduleBossSpellcard(boss: boss)
        }
        
        // After boss defeated (no enemies remain), move to score scene once
        if bossSpawned && !stageCompleteDispatched && entityManager.getEntities(with: EnemyComponent.self).isEmpty {
            stageCompleteDispatched = true
            let nextId = GameFacade.shared.getCurrentStage() >= GameFacade.maxStage ? (GameFacade.maxStage + 1) : (GameFacade.shared.getCurrentStage() + 1)
            eventBus.fire(StageTransitionEvent(nextStageId: nextId))
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        if let s = event as? StageStartedEvent {
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
            let enemy = EnemyFactory.createFairy(position: position, pattern: pattern, patternConfig: patternConfig, entityManager: entityManager)
            if let shootable = enemy.component(ofType: EnemyComponent.self) {
                let scheduler = GameFacade.shared.getTaskScheduler()
                let steps: [TaskScheduler.Step] = [
                    .run { entityManager, commandQueue in
                        // Skip shooting if time is frozen (only scripted boss shooting should happen during freeze)
                        if GameFacade.shared.isFrozen() {
                            return
                        }
                        guard let t = enemy.component(ofType: TransformComponent.self) else { return }
                        let players = entityManager.getEntities(with: PlayerComponent.self)
                        let playerPosition = players.first?.component(ofType: TransformComponent.self)?.position
                        let commands = shootable.getBulletCommands(from: t.position, targetPosition: playerPosition)
                        for c in commands { commandQueue.enqueue(.spawnBullet(c, ownedByPlayer: false)) }
                    }
                ]
                _ = scheduler.schedule(owner: enemy, steps: steps, repeatEvery: shootable.shotInterval)
            }
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
                GameFacade.shared.getCommandQueue().enqueue(.destroyEntity(enemy))
            }
        }
    }
    
    private func updateEnemyShooting(deltaTime: TimeInterval) {
        // Shooting is driven by TaskScheduler via scheduled tasks on spawn.
    }
    
    /// Schedule boss spellcard pattern (extracted for flexibility - can be configured per boss/spellcard)
    private func scheduleBossSpellcard(boss: GKEntity) {
        guard boss.component(ofType: EnemyComponent.self) != nil else { return }
        let scheduler = GameFacade.shared.getTaskScheduler()
        
        // Sakuya freeze gimmick spellcard - for testing
        let freezeSteps: [TaskScheduler.Step] = [
            // Freeze everything globally
            .run { entityManager, _ in
                print("FREEZE: Freezing everything")
                GameFacade.shared.setTimeFrozen(true)
                BulletModifierHelpers.freezeAllBullets(entityManager: entityManager)
            },
            .wait(1.0), // Longer freeze duration
            // Spawn aimed bullets at player (visible but frozen)
            .run { entityManager, commandQueue in
                print("FREEZE: After wait, spawning bullets")
                guard let t = boss.component(ofType: TransformComponent.self) else {
                    print("FREEZE: Boss transform missing")
                    return
                }
                let players = entityManager.getEntities(with: PlayerComponent.self)
                guard let playerPos = players.first?.component(ofType: TransformComponent.self)?.position else {
                    print("FREEZE: Player position missing")
                    return
                }
                
                print("FREEZE: Spawning bullets at boss pos \(t.position) aiming at player \(playerPos)")
                
                // Calculate angle to player
                let dx = playerPos.x - t.position.x
                let dy = playerPos.y - t.position.y
                let angle = atan2(dy, dx)
                let speed: CGFloat = 180
                let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                
                // Spawn multiple aimed bullets for visibility
                for i in 0..<3 {
                    let offset = CGFloat(i - 1) * 10.0 // Spread slightly
                    let offsetX = cos(angle + .pi/2) * offset
                    let offsetY = sin(angle + .pi/2) * offset
                    
                    let freezeBullet = BulletSpawnCommand(
                        position: CGPoint(x: t.position.x + offsetX, y: t.position.y + offsetY),
                        velocity: velocity,
                        bulletType: .enemyBullet,
                        physics: PhysicsConfig(speed: speed, damage: 1),
                        visual: VisualConfig(size: .small, shape: .circle, color: .red)
                    )
                    commandQueue.enqueue(.spawnBullet(freezeBullet, ownedByPlayer: false))
                }
                print("FREEZE: Bullets spawned")
            },
            .wait(0.3), // Brief pause so bullets are visible frozen
            // Unfreeze everything
            .run { entityManager, _ in
                print("FREEZE: Unfreezing everything")
                GameFacade.shared.setTimeFrozen(false)
                BulletModifierHelpers.unfreezeAllBullets(entityManager: entityManager)
            }
        ]
        // Repeat freeze pattern every 4 seconds
        _ = scheduler.schedule(owner: boss, steps: freezeSteps, repeatEvery: 4.0)
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
