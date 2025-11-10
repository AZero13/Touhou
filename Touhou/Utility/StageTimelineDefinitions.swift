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
    /// Delegates to Stage1Timeline for organization
    static func createStage1Timeline() -> StageTimeline {
        return Stage1Timeline.create()
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

