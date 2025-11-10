//
//  StageTimelineDefinitions.swift
//  Touhou
//
//  Created by Rose on 11/01/25.
//
//  Stage timeline definitions - all stage scripting goes here
//  Separated from EnemySystem for better organization

import Foundation
import CoreGraphics

/// Stage timeline definitions
/// Each function creates a timeline for a specific stage
enum StageTimelineDefinitions {
    
    /// Create timeline for stage 1
    /// TH06 Stage 1: Two enemies from far edge fly down, fairies come horizontally two-by-two
    static func createStage1Timeline() -> StageTimeline {
        let playArea = GameFacade.playArea
        let centerX = playArea.midX
        // Fairy hitbox is 12 pixels, so spacing is 12 pixels (1 unit) apart
        let fairySize: CGFloat = 12 // Enemy hitbox size
        
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
        // 12 pairs total, each pair gets closer until touching
        // Like ECL script: explicit calls for each pair with decreasing spacing
        let pairCount = 12
        let startTime: TimeInterval = 1.0
        let timeBetweenPairs: TimeInterval = 0.5
        
        for pairIndex in 0..<pairCount {
            let pairTime = startTime + (TimeInterval(pairIndex) * timeBetweenPairs)
            // Spacing decreases from 12 units to 0 (touching)
            // First pair: 12 units apart, last pair: 0 units apart (touching)
            let spacing = fairySize * (1.0 - (CGFloat(pairIndex) / CGFloat(pairCount - 1)))
            
            // Left fairy
            builder = builder.addEnemy(
                at: pairTime,
                type: .fairy,
                position: CGPoint(x: centerX - spacing, y: 400),
                velocity: CGVector(dx: 0, dy: -50),
                dropItem: .power,
                autoShoot: false
            )
            // Right fairy
            builder = builder.addEnemy(
                at: pairTime,
                type: .fairy,
                position: CGPoint(x: centerX + spacing, y: 400),
                velocity: CGVector(dx: 0, dy: -50),
                dropItem: .point,
                autoShoot: false
            )
        }
        
        // Example: Make enemies shoot at specific times
        // (You can add more shooting events here)
        
        return builder.build()
    }
    
    /// Create timeline for a default stage (fallback)
    static func createDefaultStageTimeline(stageId: Int) -> StageTimeline {
        return TimelineBuilder.create()
            .addEnemy(
                at: 1.0,
                type: .fairy,
                position: CGPoint(x: 80, y: 400),
                velocity: CGVector(dx: 0, dy: -50),
                dropItem: .power,
                autoShoot: true,
                attackPattern: .aimedShot,
                patternConfig: PatternConfig(
                    physics: PhysicsConfig(speed: 120)
                ),
                shotInterval: 2.0
            )
            .addEnemy(
                at: 2.0,
                type: .fairy,
                position: CGPoint(x: 192, y: 400),
                velocity: CGVector(dx: 0, dy: -50),
                dropItem: .power,
                autoShoot: true,
                attackPattern: .tripleShot,
                patternConfig: PatternConfig(
                    physics: PhysicsConfig(speed: 110)
                ),
                shotInterval: 2.0
            )
            .addEnemy(
                at: 3.0,
                type: .fairy,
                position: CGPoint(x: 300, y: 400),
                velocity: CGVector(dx: 0, dy: -50),
                dropItem: .power,
                autoShoot: true,
                attackPattern: .circleShot,
                patternConfig: PatternConfig(
                    physics: PhysicsConfig(speed: 100),
                    bulletCount: 10
                ),
                shotInterval: 2.0
            )
            .build()
    }
}

