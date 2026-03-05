//
//  RumiaPatterns.swift
//  Touhou
//

import Foundation
import CoreGraphics

struct RumiaPhase1Pattern: BulletPattern {
    private var timer: TimeInterval = 0
    private var isDone: Bool = false
    let config: PatternConfig
    let shotInterval: TimeInterval
    
    init(config: PatternConfig = PatternConfig(), shotInterval: TimeInterval = 1.2) {
        self.config = config
        self.shotInterval = shotInterval
        // Start almost ready to fire
        self.timer = shotInterval - 0.1
    }
    
    mutating func update(dt: TimeInterval, position: CGPoint, target: CGPoint?) -> PatternOutput {
        timer += dt
        var output = PatternOutput()
        
        // Fire every shotInterval
        if timer >= shotInterval {
            timer -= shotInterval
            let speed = config.physics.speed
            
            // Multiple downward streams of red circular bullets
            let streamAngles: [CGFloat] = [0.0, 0.06544985, 0.1308997, 0.19634955, 0.2617994]
            let bulletsPerStream = 8
            let streamSpacing: CGFloat = 8
            
            for (streamIndex, angleOffset) in streamAngles.enumerated() {
                let horizontalOffset = CGFloat(streamIndex - 2) * 20
                for i in 0..<bulletsPerStream {
                    let bulletPosition = CGPoint(x: position.x + horizontalOffset, y: position.y - CGFloat(i) * streamSpacing)
                    let velocity = CGVector(dx: sin(angleOffset) * speed, dy: -cos(angleOffset) * speed)
                    output.bullets.append(BulletSpawnCommand(
                        position: bulletPosition,
                        velocity: velocity,
                        bulletType: .enemyBullet,
                        physics: config.physics,
                        visual: VisualConfig(size: .small, shape: .circle, color: .red),
                        behavior: config.behavior
                    ))
                }
            }
            
            // Scattered yellow square bullets
            let scatteredBulletCount = 12
            let spreadAngle: CGFloat = .pi * 0.6
            for i in 0..<scatteredBulletCount {
                let angle = -spreadAngle / 2 + (spreadAngle * CGFloat(i) / CGFloat(scatteredBulletCount - 1))
                let velocity = CGVector(dx: sin(angle) * speed, dy: -cos(angle) * speed)
                let scatterOffset = CGFloat.random(in: -15...15)
                let bulletPosition = CGPoint(x: position.x + scatterOffset, y: position.y)
                output.bullets.append(BulletSpawnCommand(
                    position: bulletPosition,
                    velocity: velocity,
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: VisualConfig(size: .small, shape: .square, color: .yellow),
                    behavior: config.behavior
                ))
            }
            
            // Lasers for Phase 1
            let baseAngle = target.flatMap { MathUtility.angle(from: position, to: $0) } ?? -.pi / 2
            let laserCount = 5
            let warmup: TimeInterval = 0.5
            let stagger: TimeInterval = 0.5
            let activationTime = warmup + stagger * Double(laserCount - 1)
            let activeDuration: TimeInterval = 1.5
            let totalDuration = activationTime + activeDuration + 0.3
            
            for idx in 0..<laserCount {
                let startDelay = stagger * Double(idx)
                let length = max(260, config.physics.speed * 3)
                let width = max(12, config.spread * 0.22)
                let previewWidth = max(4, width * 0.25)
                
                output.lasers.append(LaserSpawnCommand(
                    position: position,
                    angle: baseAngle,
                    length: length,
                    width: width,
                    previewWidth: previewWidth,
                    duration: totalDuration,
                    warmup: warmup,
                    startDelay: startDelay,
                    activationOverride: activationTime,
                    color: config.visual.color,
                    damage: config.physics.damage,
                    tickInterval: 0.12,
                    anchor: nil
                ))
            }
        }
        
        return output
    }
    
    var isComplete: Bool { return isDone }
    mutating func reset() { timer = shotInterval - 0.1 }
}

struct RumiaPhase2Pattern: BulletPattern {
    private var timer: TimeInterval = 0
    private var isDone: Bool = false
    let config: PatternConfig
    let shotInterval: TimeInterval
    
    init(config: PatternConfig = PatternConfig(), shotInterval: TimeInterval = 1.2) {
        self.config = config
        self.shotInterval = shotInterval
        self.timer = shotInterval - 0.1
    }
    
    mutating func update(dt: TimeInterval, position: CGPoint, target: CGPoint?) -> PatternOutput {
        timer += dt
        var output = PatternOutput()
        
        if timer >= shotInterval {
            timer -= shotInterval
            let speed = config.physics.speed
            
            let firstWaveCount = 8
            let firstWaveAngle = 3.0
            let firstWaveAngleStep = 0.5
            for i in 0..<firstWaveCount {
                let angle = firstWaveAngle + CGFloat(i) * firstWaveAngleStep
                let velocity = CGVector(dx: sin(angle) * speed * 0.7, dy: -cos(angle) * speed * 0.7)
                output.bullets.append(BulletSpawnCommand(
                    position: position,
                    velocity: velocity,
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: VisualConfig(size: .small, shape: .circle, color: .red),
                    behavior: config.behavior
                ))
            }
            
            let secondWaveAngleStart: CGFloat = 6.2831855
            let secondWaveAngleEnd: CGFloat = 3.1415927
            let secondWaveAngleRange = secondWaveAngleEnd - secondWaveAngleStart
            for i in 0..<firstWaveCount {
                let angle = secondWaveAngleStart + (secondWaveAngleRange * CGFloat(i) / CGFloat(firstWaveCount - 1))
                let velocity = CGVector(dx: sin(angle) * speed * 0.7, dy: -cos(angle) * speed * 0.7)
                output.bullets.append(BulletSpawnCommand(
                    position: position,
                    velocity: velocity,
                    bulletType: .enemyBullet,
                    physics: config.physics,
                    visual: VisualConfig(size: .small, shape: .square, color: .yellow),
                    behavior: config.behavior
                ))
            }
            
            // Lasers for Phase 2
            let baseAngle = target.flatMap { MathUtility.angle(from: position, to: $0) } ?? -.pi / 2
            let laserCount = 5
            let warmup: TimeInterval = 0.5
            let stagger: TimeInterval = 0.5
            let activationTime = warmup + stagger * Double(laserCount - 1)
            let activeDuration: TimeInterval = 1.8
            let totalDuration = activationTime + activeDuration + 0.3
            
            for idx in 0..<laserCount {
                let startDelay = stagger * Double(idx)
                let length = max(280, config.physics.speed * 3)
                let width = max(12, config.spread * 0.28)
                let previewWidth = max(4, width * 0.25)
                
                output.lasers.append(LaserSpawnCommand(
                    position: position,
                    angle: baseAngle,
                    length: length,
                    width: width,
                    previewWidth: previewWidth,
                    duration: totalDuration,
                    warmup: warmup,
                    startDelay: startDelay,
                    activationOverride: activationTime,
                    color: config.visual.color,
                    damage: config.physics.damage,
                    tickInterval: 0.12,
                    anchor: nil
                ))
            }
        }
        
        return output
    }
    
    var isComplete: Bool { return isDone }
    mutating func reset() { timer = shotInterval - 0.1 }
}
