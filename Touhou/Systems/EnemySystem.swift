//
//  EnemySystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// EnemySystem - handles enemy spawning and movement
class EnemySystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    private var stageTimer: TimeInterval = 0
    private var stageScript: [EnemySpawnEvent] = []
    
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
    }
    
    func handleEvent(_ event: GameEvent) {
        // Handle events as needed
    }
    
    // MARK: - Private Methods
    
    private func loadStageScript() {
        // Stage 1 script - enemies spawn at specific times with different patterns
        stageScript = [
            EnemySpawnEvent(time: 1.0, type: "fairy", position: CGPoint(x: 100, y: 400), pattern: .singleShot),
            EnemySpawnEvent(time: 2.5, type: "fairy", position: CGPoint(x: 200, y: 400), pattern: .tripleShot),
            EnemySpawnEvent(time: 4.0, type: "fairy", position: CGPoint(x: 300, y: 400), pattern: .aimedShot),
            EnemySpawnEvent(time: 6.0, type: "fairy", position: CGPoint(x: 150, y: 400), pattern: .circleShot),
            EnemySpawnEvent(time: 7.5, type: "fairy", position: CGPoint(x: 250, y: 400), pattern: .spiralShot),
            EnemySpawnEvent(time: 10.0, type: "fairy", position: CGPoint(x: 192, y: 400), pattern: .aimedShot), // Center
        ]
    }
    
    private func spawnEnemiesFromScript() {
        // Find enemies that should spawn now
        let enemiesToSpawn = stageScript.filter { spawnEvent in
            spawnEvent.time <= stageTimer && !spawnEvent.hasSpawned
        }
        
        for spawnEvent in enemiesToSpawn {
            spawnEnemy(type: spawnEvent.type, position: spawnEvent.position, pattern: spawnEvent.pattern)
            spawnEvent.hasSpawned = true
        }
    }
    
    private func spawnEnemy(type: String, position: CGPoint, pattern: EnemyPattern) {
        let entity = entityManager.createEntity()
        
        // Add components based on enemy type
        switch type {
        case "fairy":
            entity.addComponent(EnemyComponent(
                enemyType: "fairy",
                scoreValue: 100,
                dropTable: [.power: 0.3, .point: 0.7],
                attackPattern: pattern,
                shotInterval: 2.0
            ))
            entity.addComponent(TransformComponent(
                position: position,
                velocity: CGVector(dx: 0, dy: -50) // Move down slowly
            ))
            entity.addComponent(HitboxComponent(enemyHitbox: 12))
            entity.addComponent(HealthComponent(current: 1, max: 1))
            
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
                entityManager.markForDestruction(enemy)
            }
        }
    }
    
    private func updateEnemyShooting(deltaTime: TimeInterval) {
        let currentTime = CACurrentMediaTime()
        let enemies = entityManager.getEntities(with: EnemyComponent.self)
        
        for enemy in enemies {
            guard let enemyComp = enemy.component(ofType: EnemyComponent.self),
                  let transform = enemy.component(ofType: TransformComponent.self) else { continue }
            
            // Check if it's time for this enemy to shoot
            if currentTime - enemyComp.lastShotTime >= enemyComp.shotInterval {
                enemyComp.lastShotTime = currentTime
                
                // Get player position for aimed shots
                let players = entityManager.getEntities(with: PlayerComponent.self)
                let playerPosition = players.first?.component(ofType: TransformComponent.self)?.position
                
                // Get bullet commands from pattern
                let commands = enemyComp.attackPattern.getBulletCommands(
                    from: transform.position,
                    targetPosition: playerPosition
                )
                
                // Spawn bullets
                for command in commands {
                    let bulletEntity = entityManager.createEntity()
                    bulletEntity.addComponent(BulletComponent(
                        ownedByPlayer: false,
                        bulletType: command.bulletType,
                        damage: command.damage
                    ))
                    bulletEntity.addComponent(TransformComponent(
                        position: command.position,
                        velocity: command.velocity
                    ))
                }
            }
        }
    }
}

/// Enemy spawn event for stage scripting
class EnemySpawnEvent {
    let time: TimeInterval
    let type: String
    let position: CGPoint
    let pattern: EnemyPattern
    var hasSpawned: Bool = false
    
    init(time: TimeInterval, type: String, position: CGPoint, pattern: EnemyPattern) {
        self.time = time
        self.type = type
        self.position = position
        self.pattern = pattern
    }
}
