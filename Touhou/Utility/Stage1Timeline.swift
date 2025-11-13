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
        
        // More waves matching TH06 ECL (Sub2/Sub3 alternating pattern)
        let waveStart = diagonalWaveStart + TimeInterval(diagonalWaveCount) * diagonalInterval + 2.0
        
        // Wave pattern: Sub2/Sub3 alternating from left/right with varied timing
        let wavePositions: [(x: CGFloat, delay: TimeInterval, isLeft: Bool)] = [
            (32, 0, true), (256, 0.3, false), (128, 0.5, true),
            (352, 0.8, false), (24, 1.3, true), (304, 1.6, false),
            (144, 1.9, true), (344, 2.2, false), (32, 2.5, true),
            (240, 2.8, false), (24, 3.1, true), (304, 3.4, false),
            (144, 3.7, true), (344, 4.0, false), (32, 4.3, true),
            (240, 4.6, false)
        ]
        
        for wave in wavePositions {
            builder = builder.addEnemy(
                at: waveStart + wave.delay,
                type: .fairy,
                position: CGPoint(x: wave.x, y: 420),
                velocity: CGVector(dx: 0, dy: -50),
                dropItem: wave.isLeft ? .point : .power,
                autoShoot: true,
                attackPattern: .tripleShot,
                patternConfig: PatternConfig(
                    physics: PhysicsConfig(speed: 100),
                    visual: VisualConfig(color: wave.isLeft ? .green : .cyan)
                ),
                shotInterval: 2.0
            )
        }
        
        // Midboss spawns
        let midbossSpawnTime = waveStart + 6.0
        builder = builder.addAction(
            at: midbossSpawnTime,
            action: { _, _ in
                print("Stage1Timeline: Spawning midboss")
                Stage1Timeline.spawnRumiaMidbossNow()
            }
        )
        
        // More waves after midboss (continues while midboss is active)
        let postMidbossWaveStart = midbossSpawnTime + 8.0
        let finalBurstPositions: [(x: CGFloat, side: Bool)] = [
            (32, true), (64, true), (40, true), (72, true),
            (48, true), (80, true), (56, true), (88, true),
            (320, false), (352, false), (312, false), (344, false),
            (304, false), (336, false), (296, false), (328, false)
        ]
        
        for (index, pos) in finalBurstPositions.enumerated() {
            builder = builder.addEnemy(
                at: postMidbossWaveStart + TimeInterval(index) * 0.16,
                type: .fairy,
                position: CGPoint(x: pos.x, y: 420),
                velocity: CGVector(dx: 0, dy: -80),
                dropItem: .point,
                autoShoot: false  // No shooting, just fast dive
            )
        }
        
        return builder.build()
    }
    
    /// Public method for DialogueSystem to trigger midboss spawn
    static func triggerMidbossSpawn() {
        spawnRumiaMidbossNow()
    }
    
    private static func spawnRumiaMidbossNow() {
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
            
            // Schedule subsequent movements
            scheduleMidbossMovementPattern(transform: transform, playArea: playArea)
        }
        
        // Fire boss intro event to trigger timer display
        print("Stage1Timeline: Firing BossIntroStartedEvent for Rumia")
        GameFacade.shared.fireEvent(BossIntroStartedEvent(bossEntity: rumia))
        print("Stage1Timeline: Rumia spawned with hasTimeBonus: \(rumia.component(ofType: BossComponent.self)?.hasTimeBonus ?? false)")
    }
    
    private static func scheduleMidbossMovementPattern(transform: TransformComponent, playArea: CGRect) {
        let centerX = playArea.midX
        let moveDuration = 1.0
        
        // Schedule movements via dispatch queue (non-game-loop timing)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_500_000_000)  // 3.5 seconds
            transform.moveTo(position: CGPoint(x: centerX, y: 288), duration: moveDuration)
            
            try? await Task.sleep(nanoseconds: 3_500_000_000)  // +3.5 = 7 seconds total
            transform.moveTo(position: CGPoint(x: playArea.minX + 64, y: 272), duration: moveDuration)
            
            try? await Task.sleep(nanoseconds: 3_500_000_000)  // +3.5 = 10.5 seconds total
            transform.moveTo(position: CGPoint(x: centerX, y: 304), duration: moveDuration)
            
            try? await Task.sleep(nanoseconds: 3_500_000_000)  // +3.5 = 14 seconds total
            transform.moveTo(position: CGPoint(x: playArea.maxX - 64, y: 272), duration: moveDuration)
            
            try? await Task.sleep(nanoseconds: 3_500_000_000)  // +3.5 = 17.5 seconds total
            transform.moveTo(position: CGPoint(x: centerX, y: 450), duration: moveDuration)
        }
    }
}

