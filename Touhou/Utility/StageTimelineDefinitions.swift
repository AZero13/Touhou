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
import GameplayKit

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
            .addAction(
                at: 60.0,
                action: { entityManager, eventBus in
                    // Clear arena before boss spawns
                    let enemies = entityManager.getEntities(with: EnemyComponent.self)
                    for enemy in enemies {
                        if enemy.component(ofType: BossComponent.self) == nil {
                            GameFacade.shared.entities.destroy(enemy)
                        }
                    }
                    // Clear bullets (convertBulletsToPoints requires context, so just clear for default stage)
                    BulletUtility.clearEnemyBullets(entityManager: entityManager, destroyEntity: GameFacade.shared.entities.destroy)
                }
            )
            .addBoss(
                at: 61.5,
                name: "Stage Boss",
                health: 300,
                position: CGPoint(x: 192, y: 360),
                phaseNumber: 1,
                attackPattern: .tripleShot,
                patternConfig: PatternConfig(
                    physics: PhysicsConfig(speed: 120),
                    visual: VisualConfig(shape: .star, color: .purple),
                    bulletCount: 8,
                    spread: 80,
                    spiralSpeed: 12
                )
            )
            .build()
    }
}

