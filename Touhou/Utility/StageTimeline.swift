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
    
    /// Spawn a boss at a position with attack pattern
    case spawnBoss(
        name: String,
        health: Int,
        position: CGPoint,
        phaseNumber: Int,
        attackPattern: EnemyPattern,
        patternConfig: PatternConfig,
        shotInterval: TimeInterval? = nil,
        hasTimeBonus: Bool = false,
        timeLimit: TimeInterval? = nil,
        bonusPointsBase: Int? = nil
    )
    
    /// Make an enemy shoot (for enemies spawned with autoShoot: false)
    case enemyShoot(
        enemySelector: (EntityManaging) -> [GKEntity], // Function to find enemies
        pattern: EnemyPattern,
        patternConfig: PatternConfig
    )
    
    /// Spawn bullets directly (for patterns that don't need enemies)
    case spawnBullets([BulletSpawnCommand])
    
    /// Custom action (closure for complex behaviors)
    case custom((EntityManaging, EventDispatching) -> Void)
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
    private var entityManager: EntityManaging?
    private var eventBus: EventDispatching?
    
    init(steps: [Step]) {
        // Sort steps by time to ensure correct execution order
        self.steps = steps.sorted { $0.time < $1.time }
    }
    
    /// Initialize with entity manager and event bus
    func initialize(entityManager: EntityManaging, eventBus: EventDispatching) {
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
                    // Skip spawn but still advance (like TH06)
                    // print("StageTimeline: Skipping enemy spawn at \(step.time) (boss present)")
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
            print("StageTimeline: ✓ All \(steps.count) steps complete, marking timeline complete")
            isActive = false
        }
    }
    
    /// Check if timeline is complete
    var isComplete: Bool {
        return !isActive && currentStepIndex >= steps.count
    }
    
    // MARK: - Private Methods
    
    private func executeEvent(_ event: TimelineEvent, entityManager: EntityManaging, eventBus: EventDispatching) {
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
            
        case .spawnBoss(let name, let health, let position, let phaseNumber, let attackPattern, let patternConfig, let shotInterval, let hasTimeBonus, let timeLimit, let bonusPointsBase):
            spawnBoss(
                name: name,
                health: health,
                position: position,
                phaseNumber: phaseNumber,
                attackPattern: attackPattern,
                patternConfig: patternConfig,
                shotInterval: shotInterval ?? 1.2,
                hasTimeBonus: hasTimeBonus,
                timeLimit: timeLimit,
                bonusPointsBase: bonusPointsBase,
                entityManager: entityManager,
                eventBus: eventBus
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
        entityManager: EntityManaging
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
            entity.addComponent(HitboxComponent(enemyHitbox: 9))
            entity.addComponent(HealthComponent(health: 1, maxHealth: 1))
            GameFacade.shared.registerEntity(entity)
            
        case .boss:
            // Bosses should be spawned via .spawnBoss timeline event, not .spawnEnemy
            // This case exists for exhaustiveness but shouldn't be used
            break
        }
    }
    
    private func spawnBoss(
        name: String,
        health: Int,
        position: CGPoint,
        phaseNumber: Int,
        attackPattern: EnemyPattern,
        patternConfig: PatternConfig,
        shotInterval: TimeInterval,
        hasTimeBonus: Bool,
        timeLimit: TimeInterval?,
        bonusPointsBase: Int?,
        entityManager: EntityManaging,
        eventBus: EventDispatching
    ) {
        let boss = GameFacade.shared.entities.spawnBoss(
            name: name,
            health: health,
            position: position,
            phaseNumber: phaseNumber,
            attackPattern: attackPattern,
            patternConfig: patternConfig,
            shotInterval: shotInterval,
            hasTimeBonus: hasTimeBonus,
            timeLimit: timeLimit ?? 20.0,
            bonusPointsBase: bonusPointsBase ?? 10000
        )
        
        // Fire boss intro event
        eventBus.fire(BossIntroStartedEvent(bossEntity: boss))
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
    
    /// Add a boss spawn event
    func addBoss(
        at time: TimeInterval,
        name: String,
        health: Int,
        position: CGPoint,
        phaseNumber: Int = 1,
        attackPattern: EnemyPattern = .tripleShot,
        patternConfig: PatternConfig = PatternConfig(),
        shotInterval: TimeInterval? = nil,
        hasTimeBonus: Bool = false,
        timeLimit: TimeInterval? = nil,
        bonusPointsBase: Int? = nil
    ) -> TimelineBuilder {
        var builder = self
        builder.steps.append(StageTimeline.Step(
            time: time,
            event: .spawnBoss(
                name: name,
                health: health,
                position: position,
                phaseNumber: phaseNumber,
                attackPattern: attackPattern,
                patternConfig: patternConfig,
                shotInterval: shotInterval,
                hasTimeBonus: hasTimeBonus,
                timeLimit: timeLimit,
                bonusPointsBase: bonusPointsBase
            )
        ))
        return builder
    }
    
    /// Add an enemy shoot event (for enemies spawned with autoShoot: false)
    func addEnemyShoot(
        at time: TimeInterval,
        enemySelector: @escaping (EntityManaging) -> [GKEntity],
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
        action: @escaping (EntityManaging, EventDispatching) -> Void
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

