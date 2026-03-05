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
        attackPattern: BulletPattern? = nil
    )
    
    /// Spawn a boss at a position with attack pattern
    case spawnBoss(
        name: String,
        health: Int,
        position: CGPoint,
        phaseNumber: Int,
        attackPattern: BulletPattern,
        hasTimeBonus: Bool = false,
        timeLimit: TimeInterval? = nil,
        bonusPointsBase: Int? = nil
    )
    
    /// Make an enemy shoot (for enemies spawned with autoShoot: false)
    case enemyShoot(
        enemySelector: (EntityManaging) -> [GKEntity], // Function to find enemies
        pattern: BulletPattern
    )
    
    /// Spawn bullets directly (for patterns that don't need enemies)
    case spawnBullets([BulletSpawnCommand])
    
    /// Spawn a laser directly (no owning enemy needed)
    case spawnLaser(LaserSpawnCommand)
    
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
    
    /// Initialize with engine
    func initialize(engine: GameEngine) {
        self.entityManager = engine.entityManager
        self.eventBus = engine.eventBus
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
        
        // Pause the timeline while any boss (midboss or stage boss) is active
        // This prevents later waves from fast-forwarding during a boss fight
        if !entityManager.getEntities(with: BossComponent.self).isEmpty {
            return
        }
        
        // Advance time only when no boss is present
        timer += deltaTime
        
        // Process all steps that are due
        while currentStepIndex < steps.count {
            let step = steps[currentStepIndex]
            if timer >= step.time {
                // If a boss became active from a previous step in this frame, stop and wait
                if case .spawnEnemy = step.event,
                   !entityManager.getEntities(with: BossComponent.self).isEmpty {
                    break  // Do not advance; wait and spawn once the arena is clear
                }
                
                executeEvent(step.event, entityManager: entityManager, eventBus: eventBus)
                currentStepIndex += 1
                
                // If this step spawned a boss (e.g., midboss), halt progression immediately
                if !entityManager.getEntities(with: BossComponent.self).isEmpty {
                    break
                }
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
        case .spawnEnemy(let type, let position, let velocity, let dropItem, let autoShoot, let attackPattern):
            spawnEnemy(
                type: type,
                position: position,
                velocity: velocity,
                dropItem: dropItem,
                autoShoot: autoShoot,
                attackPattern: attackPattern,
                entityManager: entityManager
            )
            
        case .spawnBoss(let name, let health, let position, let phaseNumber, let attackPattern, let hasTimeBonus, let timeLimit, let bonusPointsBase):
            spawnBoss(
                name: name,
                health: health,
                position: position,
                phaseNumber: phaseNumber,
                attackPattern: attackPattern,
                hasTimeBonus: hasTimeBonus,
                timeLimit: timeLimit,
                bonusPointsBase: bonusPointsBase,
                entityManager: entityManager,
                eventBus: eventBus
            )
            
        case .enemyShoot(let selector, var pattern):
            let enemies = selector(entityManager)
            for enemy in enemies {
                guard let transform = enemy.component(ofType: TransformComponent.self) else { continue }
                let playerPosition = GameFacade.shared.entityManager.getPlayerEntity()?.component(ofType: TransformComponent.self)?.position
                let playerPosition = GameFacade.shared.entityManager.getPlayerEntity()?.component(ofType: TransformComponent.self)?.position
                let output = pattern.update(dt: 0, position: transform.position, target: playerPosition)
                
                for cmd in output.bullets {
                    GameFacade.shared.spawnEnemyBullet(cmd)
                }
                
                for laserCmd in output.lasers {
                    let anchored = LaserSpawnCommand(
                        position: laserCmd.position,
                        angle: laserCmd.angle,
                        length: laserCmd.length,
                        width: laserCmd.width,
                        duration: laserCmd.duration,
                        color: laserCmd.color,
                        damage: laserCmd.damage,
                        tickInterval: laserCmd.tickInterval,
                        anchor: enemy
                    )
                    GameFacade.shared.spawnEnemyLaser(anchored)
                }
            }
            
        case .spawnBullets(let commands):
            for cmd in commands {
                GameFacade.shared.spawnEnemyBullet(cmd)
            }
            
        case .spawnLaser(let laserCmd):
            GameFacade.shared.spawnEnemyLaser(laserCmd)
            
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
        attackPattern: BulletPattern?,
        entityManager: EntityManaging
    ) {
        switch type {
        case .fairy:
            let bulletPattern: BulletPattern
            if autoShoot {
                bulletPattern = attackPattern ?? SingleShotPattern(interval: 2.0)
            } else {
                bulletPattern = EmptyPattern()
            }
            
            let entity = entityManager.createEntity()
            entity.addComponent(EnemyComponent(
                enemyType: .fairy,
                scoreValue: 100,
                dropItem: dropItem,
                attackPattern: bulletPattern
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
        attackPattern: BulletPattern,
        hasTimeBonus: Bool,
        timeLimit: TimeInterval?,
        bonusPointsBase: Int?,
        entityManager: EntityManaging,
        eventBus: EventDispatching
    ) {
        let data = BossData(
            name: name,
            health: health,
            position: position,
            phaseNumber: phaseNumber,
            attackPattern: attackPattern,
        )
        let boss = GameFacade.shared.spawnBoss(data: data)
        
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
        attackPattern: BulletPattern? = nil
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
                attackPattern: attackPattern
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
        attackPattern: BulletPattern = TripleShotPattern(interval: 1.2),
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
        pattern: BulletPattern
    ) -> TimelineBuilder {
        var builder = self
        builder.steps.append(StageTimeline.Step(
            time: time,
            event: .enemyShoot(
                enemySelector: enemySelector,
                pattern: pattern
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
    
    /// Add a laser spawn event (direct)
    func addLaser(
        at time: TimeInterval,
        command: LaserSpawnCommand
    ) -> TimelineBuilder {
        var builder = self
        builder.steps.append(StageTimeline.Step(
            time: time,
            event: .spawnLaser(command)
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

