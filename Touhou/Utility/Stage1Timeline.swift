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
        
        // Example: Make enemies shoot at specific times
        // (You can add more shooting events here)
        
        //Add more red fairies
        
        
        return builder.build()
    }
}

