//
//  Stage1Timeline.swift
//  Touhou
//
//  Created by Rose on 11/01/25.
//
//  Stage 1 timeline definitions
//  Separated from StageTimelineDefinitions for better organization

import Foundation
import CoreGraphics
import GameplayKit

/// Stage 1 timeline definitions
enum Stage1Timeline {
    
    /// Create timeline for stage 1
    /// TH06 Stage 1: Two enemies from far edge fly down, fairies come horizontally two-by-two
    static func create() -> StageTimeline {
        let playArea = GameFacade.playArea
        let centerX = playArea.midX
        // Fairy hitbox is 12 pixels, so spacing is 12 pixels (1 unit) apart
        let fairySize: CGFloat = 12 // Enemy hitbox size (1 unit)
        
        // Build timeline step by step (like ECL script with explicit calls)
        var builder = TimelineBuilder.create()
        
        // Two enemies from far edges fly down
        builder = builder.addEnemy(
            at: 0.5,
            type: .fairy,
            position: CGPoint(x: 20, y: 400), // Left edge
            velocity: CGVector(dx: 0, dy: -50), // Fly straight down
            dropItem: .power,
            autoShoot: false // Shooting controlled by timeline
        )
        builder = builder.addEnemy(
            at: 0.5,
            type: .fairy,
            position: CGPoint(x: playArea.width - 20, y: 400), // Right edge
            velocity: CGVector(dx: 0, dy: -50), // Fly straight down
            dropItem: .point,
            autoShoot: false
        )
        
        // Fairies come horizontally from center, two-by-two
        // 12 pairs total, each pair gets closer to center (but fairies in pair stay 1 unit apart)
        // Like ECL script: loop through pairs, each pair closer to center
        let pairCount = 12
        let startTime: TimeInterval = 1.0
        let timeBetweenPairs: TimeInterval = 0.5
        let maxDistanceFromCenter: CGFloat = 100 // How far from center the first pair starts
        
        for pairIndex in 0..<pairCount {
            let pairTime = startTime + (TimeInterval(pairIndex) * timeBetweenPairs)
            // Distance from center decreases - pairs get closer to center
            // First pair: far from center, last pair: close to center
            // Minimum distance is fairySize/2 so fairies never touch (always at least 1 unit apart)
            let distanceFromCenter = max(fairySize / 2.0, maxDistanceFromCenter * (1.0 - (CGFloat(pairIndex) / CGFloat(pairCount - 1))))
            // Fairies in each pair are equidistant from center (mirrored around centerX)
            // Left fairy is distanceFromCenter to the left of center
            // Right fairy is distanceFromCenter to the right of center
            // They are 2 * distanceFromCenter apart (minimum 1 unit, so never touching)
            
            // Left fairy (left side of center, equidistant from center)
            builder = builder.addEnemy(
                at: pairTime,
                type: .fairy,
                position: CGPoint(x: centerX - distanceFromCenter, y: 400),
                velocity: CGVector(dx: 0, dy: -50),
                dropItem: .power,
                autoShoot: false
            )
            // Right fairy (right side of center, equidistant from center)
            builder = builder.addEnemy(
                at: pairTime,
                type: .fairy,
                position: CGPoint(x: centerX + distanceFromCenter, y: 400),
                velocity: CGVector(dx: 0, dy: -50),
                dropItem: .point,
                autoShoot: false
            )
        }
        
        // Diagonal swoop fairies that fire at the player while crossing
        let diagonalWaveStart = startTime + TimeInterval(pairCount) * timeBetweenPairs + 1.0
        let diagonalInterval: TimeInterval = 0.45
        let diagonalWaveCount = 6
        let diagonalSpawnY: CGFloat = 420
        let horizontalSpeed: CGFloat = 90
        let downwardSpeed: CGFloat = -30
        
        for waveIndex in 0..<diagonalWaveCount {
            let spawnTime = diagonalWaveStart + TimeInterval(waveIndex) * diagonalInterval
            // Left entry moving rightwards
            builder = builder.addEnemy(
                at: spawnTime,
                type: .fairy,
                position: CGPoint(x: -24, y: diagonalSpawnY),
                velocity: CGVector(dx: horizontalSpeed, dy: downwardSpeed),
                dropItem: .point,
                autoShoot: true,
                attackPattern: .aimedShot,
                patternConfig: PatternConfig(
                    physics: PhysicsConfig(speed: 150),
                    visual: VisualConfig(color: .blue)
                ),
                shotInterval: 1.8
            )
            // Right entry moving leftwards
            builder = builder.addEnemy(
                at: spawnTime + 0.15,
                type: .fairy,
                position: CGPoint(x: playArea.width + 24, y: diagonalSpawnY),
                velocity: CGVector(dx: -horizontalSpeed, dy: downwardSpeed),
                dropItem: .power,
                autoShoot: true,
                attackPattern: .aimedShot,
                patternConfig: PatternConfig(
                    physics: PhysicsConfig(speed: 150),
                    visual: VisualConfig(color: .pink)
                ),
                shotInterval: 1.8
            )
        }
        
        // Trailing column of fairies that slow-push the player while shooting circle spreads
        let trailingWaveStart = diagonalWaveStart + TimeInterval(diagonalWaveCount) * diagonalInterval + 1.0
        let trailingOffsets: [CGFloat] = [-108, -54, 0, 54, 108]
        
        for (index, offset) in trailingOffsets.enumerated() {
            let spawnTime = trailingWaveStart + TimeInterval(index) * 0.4
            builder = builder.addEnemy(
                at: spawnTime,
                type: .fairy,
                position: CGPoint(x: centerX + offset, y: 420),
                velocity: CGVector(dx: 0, dy: -60),
                dropItem: .point,
                autoShoot: true,
                attackPattern: .circleShot,
                patternConfig: PatternConfig(
                    physics: PhysicsConfig(speed: 110),
                    visual: VisualConfig(color: .orange),
                    bulletCount: 10
                ),
                shotInterval: 2.2
            )
        }
        
        // Midboss enters after the extra fairy waves
        let midbossSpawnTime = trailingWaveStart + TimeInterval(trailingOffsets.count) * 0.4 + 1.5
        builder = builder.addAction(
            at: midbossSpawnTime,
            action: { _, _ in
                spawnRumiaMidboss()
            }
        )
        
        // Midboss movement pattern (based on TH06 Sub8)
        builder = addMidbossMovementPattern(builder: builder, startTime: midbossSpawnTime, playArea: playArea)
        
        return builder.build()
    }
    
    private static func addMidbossMovementPattern(builder: TimelineBuilder, startTime: TimeInterval, playArea: CGRect) -> TimelineBuilder {
        var updatedBuilder = builder
        let centerX = playArea.midX
        
        // TH06 midboss moves between positions, pausing to shoot
        // Movement durations are 1 second each (60 frames at 60fps)
        let moveDuration = 1.0
        
        // After initial move to right (handled in spawn), continue pattern:
        // Move to center-top after 3.5 seconds
        updatedBuilder = updatedBuilder.addAction(
            at: startTime + 3.5,
            action: { entityManager, _ in
                if let boss = entityManager.getEntities(with: BossComponent.self).first,
                   let transform = boss.component(ofType: TransformComponent.self) {
                    transform.moveTo(position: CGPoint(x: centerX, y: 288), duration: moveDuration)
                }
            }
        )
        
        // Move to left side after 7 seconds
        updatedBuilder = updatedBuilder.addAction(
            at: startTime + 7.0,
            action: { entityManager, _ in
                if let boss = entityManager.getEntities(with: BossComponent.self).first,
                   let transform = boss.component(ofType: TransformComponent.self) {
                    transform.moveTo(position: CGPoint(x: playArea.minX + 64, y: 272), duration: moveDuration)
                }
            }
        )
        
        // Move to center-mid after 10.5 seconds
        updatedBuilder = updatedBuilder.addAction(
            at: startTime + 10.5,
            action: { entityManager, _ in
                if let boss = entityManager.getEntities(with: BossComponent.self).first,
                   let transform = boss.component(ofType: TransformComponent.self) {
                    transform.moveTo(position: CGPoint(x: centerX, y: 304), duration: moveDuration)
                }
            }
        )
        
        // Move to right side again after 14 seconds
        updatedBuilder = updatedBuilder.addAction(
            at: startTime + 14.0,
            action: { entityManager, _ in
                if let boss = entityManager.getEntities(with: BossComponent.self).first,
                   let transform = boss.component(ofType: TransformComponent.self) {
                    transform.moveTo(position: CGPoint(x: playArea.maxX - 64, y: 272), duration: moveDuration)
                }
            }
        )
        
        // Exit offscreen after 17.5 seconds
        updatedBuilder = updatedBuilder.addAction(
            at: startTime + 17.5,
            action: { entityManager, _ in
                if let boss = entityManager.getEntities(with: BossComponent.self).first,
                   let transform = boss.component(ofType: TransformComponent.self) {
                    transform.moveTo(position: CGPoint(x: centerX, y: 450), duration: moveDuration)
                }
            }
        )
        
        return updatedBuilder
    }
    
    private static func spawnRumiaMidboss() {
        let playArea = GameFacade.playArea
        let centerX = playArea.midX
        
        // Spawn offscreen top-center like in TH06
        let spawnPosition = CGPoint(x: centerX, y: 420)
        let rumia = GameFacade.shared.entities.spawnBoss(
            name: "Rumia (Midboss)",
            health: 180,
            position: spawnPosition,
            phaseNumber: 0,
            attackPattern: .spiralShot,
            patternConfig: PatternConfig(
                physics: PhysicsConfig(speed: 120),
                visual: VisualConfig(size: .medium, shape: .star, color: .purple),
                bulletCount: 12,
                spiralSpeed: 14
            ),
            shotInterval: 1.45,
            hasTimeBonus: true,
            timeLimit: 18.0,  // 18 seconds to defeat for bonus
            bonusPointsBase: 8000  // Max bonus: 8000 points
        )
        
        // Set score and drop
        if let enemyComponent = rumia.component(ofType: EnemyComponent.self) {
            enemyComponent.scoreValue = 4000
            enemyComponent.dropItem = .bomb
        }
        
        // Start movement pattern: move to first position
        if let transform = rumia.component(ofType: TransformComponent.self) {
            // Move to right side of screen over 1 second (like ECL ins_57(60, 320, 128))
            transform.moveTo(position: CGPoint(x: playArea.maxX - 64, y: 256), duration: 1.0)
        }
        
        // Fire boss intro event to trigger timer display
        GameFacade.shared.fireEvent(BossIntroStartedEvent(bossEntity: rumia))
    }
}

