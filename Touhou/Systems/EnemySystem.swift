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
    
    private var lastShotTime: TimeInterval = 0
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
        
        // Load stage script
        loadStageScript()
    }
    
    func update(deltaTime: TimeInterval) {
        stageTimer += deltaTime
        
        // Check for enemies to spawn based on stage script
        spawnEnemiesFromScript()
        
        // Update enemy movement and shooting
        updateEnemyMovement(deltaTime: deltaTime)
        updateEnemyShooting(deltaTime: deltaTime)
        
        // If all scripted enemies have spawned and been cleared, move to score scene
        if !stageCompleteDispatched,
           stageScript.allSatisfy({ $0.hasSpawned }),
           entityManager.getEntities(with: EnemyComponent.self).isEmpty {
            stageCompleteDispatched = true
            eventBus.fire(StageTransitionEvent(nextStageId: 2))
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        // Handle events as needed
    }
    
    // MARK: - Private Methods
    
    private func loadStageScript() {
        // Stage 1 script - enemies spawn at specific times with different patterns and visual variety
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
