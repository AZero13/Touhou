//
//  StageTimeline.swift
//  Touhou
//
//  Created by Rose on 11/01/25.
//
//  Timeline system for stage scripting
//  Works like TH06's timeline but uses existing enemy/pattern system
//  Supports spawning enemies at specific times with patterns

import Foundation
import CoreGraphics
import GameplayKit

/// Timeline event - something that happens at a specific time
enum TimelineEvent {
    /// Spawn an enemy at a position with movement pattern
    case spawnEnemy(
        type: EnemyComponent.EnemyType,
        position: CGPoint,
        velocity: CGVector,
        dropItem: ItemType?,
        autoShoot: Bool = false, // If false, shooting is controlled by timeline
        attackPattern: EnemyPattern? = nil,
        patternConfig: PatternConfig? = nil,
        shotInterval: TimeInterval? = nil
    )
    
    /// Make an enemy shoot (for enemies spawned with autoShoot: false)
    case enemyShoot(
        enemySelector: (EntityManager) -> [GKEntity], // Function to find enemies
        pattern: EnemyPattern,
        patternConfig: PatternConfig
    )
    
    /// Spawn bullets directly (for patterns that don't need enemies)
    case spawnBullets([BulletSpawnCommand])
    
    /// Custom action (closure for complex behaviors)
    case custom((EntityManager, EventBus) -> Void)
}

/// Stage timeline - orchestrates stage events over time
/// Similar to TH06's timeline function but works with existing systems
final class StageTimeline {
    struct Step {
        /// Time in seconds when this event occurs
        let time: TimeInterval
        /// Event to execute
        let event: TimelineEvent
    }
    
    private let steps: [Step]
    private var currentStepIndex: Int = 0
    private var timer: TimeInterval = 0
    private var isActive: Bool = false
    private var entityManager: EntityManager?
    private var eventBus: EventBus?
    
    init(steps: [Step]) {
        // Sort steps by time to ensure correct execution order
        self.steps = steps.sorted { $0.time < $1.time }
    }
    
    /// Initialize with entity manager and event bus
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    /// Start the timeline
    func start() {
        timer = 0
        currentStepIndex = 0
        isActive = true
    }
    
    /// Stop the timeline
    func stop() {
        isActive = false
    }
    
    /// Update the timeline (call each frame)
    func update(deltaTime: TimeInterval) {
        guard isActive, let entityManager = entityManager, let eventBus = eventBus else { return }
        
        // Always advance time (like TH06)
        timer += deltaTime
        
        // Check if boss is present (TH06 blocks spawns during boss fights)
        let bossPresent = !entityManager.getEntities(with: BossComponent.self).isEmpty
        
        // Process all steps that are due
        while currentStepIndex < steps.count {
            let step = steps[currentStepIndex]
            if timer >= step.time {
                // Execute event, but skip enemy spawns if boss is present (like TH06)
                if case .spawnEnemy = step.event, bossPresent {
                    print("StageTimeline: Skipping enemy spawn (boss present)")
                } else {
                    executeEvent(step.event, entityManager: entityManager, eventBus: eventBus)
                }
                currentStepIndex += 1
            } else {
                break
            }
        }
        
        // Timeline complete when all steps processed
        if currentStepIndex >= steps.count {
            isActive = false
        }
    }
    
    /// Check if timeline is complete
    var isComplete: Bool {
        return !isActive && currentStepIndex >= steps.count
    }
    
    // MARK: - Private Methods
    
    private func executeEvent(_ event: TimelineEvent, entityManager: EntityManager, eventBus: EventBus) {
        switch event {
        case .spawnEnemy(let type, let position, let velocity, let dropItem, let autoShoot, let attackPattern, let patternConfig, let shotInterval):
            spawnEnemy(
                type: type,
                position: position,
                velocity: velocity,
                dropItem: dropItem,
                autoShoot: autoShoot,
                attackPattern: attackPattern,
                patternConfig: patternConfig,
                shotInterval: shotInterval,
                entityManager: entityManager
            )
            
        case .enemyShoot(let selector, let pattern, let patternConfig):
            let enemies = selector(entityManager)
            for enemy in enemies {
                guard let transform = enemy.component(ofType: TransformComponent.self) else { continue }
                let playerPosition = GameFacade.shared.entities.player?.component(ofType: TransformComponent.self)?.position
                let commands = pattern.getBulletCommands(from: transform.position, targetPosition: playerPosition, config: patternConfig)
                for cmd in commands {
                    GameFacade.shared.combat.spawnEnemyBullet(cmd)
                }
            }
            
        case .spawnBullets(let commands):
            for cmd in commands {
                GameFacade.shared.combat.spawnEnemyBullet(cmd)
            }
            
        case .custom(let action):
            action(entityManager, eventBus)
        }
    }
    
    private func spawnEnemy(
        type: EnemyComponent.EnemyType,
        position: CGPoint,
        velocity: CGVector,
        dropItem: ItemType?,
        autoShoot: Bool,
        attackPattern: EnemyPattern?,
        patternConfig: PatternConfig?,
        shotInterval: TimeInterval?,
        entityManager: EntityManager
    ) {
        switch type {
        case .fairy:
            // If autoShoot is false, don't set attack pattern (shooting controlled by timeline)
            let pattern = autoShoot ? (attackPattern ?? .singleShot) : .singleShot
            let config = patternConfig ?? PatternConfig()
            let interval = shotInterval ?? 2.0
            
            let entity = entityManager.createEntity()
            entity.addComponent(EnemyComponent(
                enemyType: .fairy,
                scoreValue: 100,
                dropItem: dropItem,
                attackPattern: pattern,
                patternConfig: config,
                shotInterval: autoShoot ? interval : .infinity // Disable auto-shooting if false
            ))
            entity.addComponent(TransformComponent(position: position, velocity: velocity))
            entity.addComponent(HitboxComponent(enemyHitbox: 12))
            entity.addComponent(HealthComponent(health: 1, maxHealth: 1))
            GameFacade.shared.registerEntity(entity)
            
        case .boss:
            // Bosses are spawned by EnemySystem when timeline completes, not through timeline
            // This case exists for exhaustiveness but shouldn't be used
            break
        }
    }
}

/// Helper for building timelines
struct TimelineBuilder {
    private var steps: [StageTimeline.Step] = []
    
    static func create() -> TimelineBuilder {
        return TimelineBuilder()
    }
    
    /// Add an enemy spawn event
    func addEnemy(
        at time: TimeInterval,
        type: EnemyComponent.EnemyType,
        position: CGPoint,
        velocity: CGVector,
        dropItem: ItemType? = nil,
        autoShoot: Bool = false,
        attackPattern: EnemyPattern? = nil,
        patternConfig: PatternConfig? = nil,
        shotInterval: TimeInterval? = nil
    ) -> TimelineBuilder {
        var builder = self
        builder.steps.append(StageTimeline.Step(
            time: time,
            event: .spawnEnemy(
                type: type,
                position: position,
                velocity: velocity,
                dropItem: dropItem,
                autoShoot: autoShoot,
                attackPattern: attackPattern,
                patternConfig: patternConfig,
                shotInterval: shotInterval
            )
        ))
        return builder
    }
    
    /// Add an enemy shoot event (for enemies spawned with autoShoot: false)
    func addEnemyShoot(
        at time: TimeInterval,
        enemySelector: @escaping (EntityManager) -> [GKEntity],
        pattern: EnemyPattern,
        patternConfig: PatternConfig = PatternConfig()
    ) -> TimelineBuilder {
        var builder = self
        builder.steps.append(StageTimeline.Step(
            time: time,
            event: .enemyShoot(
                enemySelector: enemySelector,
                pattern: pattern,
                patternConfig: patternConfig
            )
        ))
        return builder
    }
    
    /// Add a bullet spawn event (bullets without enemies)
    func addBullets(
        at time: TimeInterval,
        commands: [BulletSpawnCommand]
    ) -> TimelineBuilder {
        var builder = self
        builder.steps.append(StageTimeline.Step(
            time: time,
            event: .spawnBullets(commands)
        ))
        return builder
    }
    
    /// Add a custom action
    func addAction(
        at time: TimeInterval,
        action: @escaping (EntityManager, EventBus) -> Void
    ) -> TimelineBuilder {
        var builder = self
        builder.steps.append(StageTimeline.Step(
            time: time,
            event: .custom(action)
        ))
        return builder
    }
    
    /// Build the timeline
    func build() -> StageTimeline {
        return StageTimeline(steps: steps)
    }
}

