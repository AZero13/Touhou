//
//  LaserComponent.swift
//  Touhou
//
//  Created by Rose on 12/05/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// Represents a continuous beam-style projectile (laser).
final class LaserComponent: GKComponent {
    // Base shape
    let length: CGFloat
    let width: CGFloat
    let angle: CGFloat
    
    // Animation phases
    let duration: TimeInterval
    let warmup: TimeInterval
    let fadeOut: TimeInterval
    
    // Optional end values for sweeping/morphing
    let endAngle: CGFloat?
    let endLength: CGFloat?
    let endWidth: CGFloat?
    
    let tickInterval: TimeInterval
    
    private var elapsed: TimeInterval = 0
    private var lastDamageTimestamps: [ObjectIdentifier: TimeInterval] = [:]
    private weak var anchorTransform: TransformComponent?
    
    // Current interpolated values (updated each frame, used by rendering system)
    var currentLength: CGFloat = 0
    var currentWidth: CGFloat = 0
    var currentAngle: CGFloat = 0
    var currentAlpha: CGFloat = 1
    
    init(length: CGFloat,
         width: CGFloat,
         angle: CGFloat,
         duration: TimeInterval,
         warmup: TimeInterval = 0.1,
         fadeOut: TimeInterval = 0.2,
         tickInterval: TimeInterval = 0.15,
         endAngle: CGFloat? = nil,
         endLength: CGFloat? = nil,
         endWidth: CGFloat? = nil,
         anchor: TransformComponent? = nil) {
        self.length = length
        self.width = width
        self.angle = angle
        self.duration = duration
        self.warmup = warmup
        self.fadeOut = fadeOut
        self.tickInterval = tickInterval
        self.endAngle = endAngle
        self.endLength = endLength
        self.endWidth = endWidth
        self.anchorTransform = anchor
        // Initialize current values to base values
        let minBeamLength = hypot(GameFacade.playArea.width, GameFacade.playArea.height) + 40
        self.currentLength = max(length, minBeamLength)
        self.currentWidth = width
        self.currentAngle = angle
        self.currentAlpha = 0 // start invisible until warmup completes
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime: TimeInterval) {
        guard let entity = entity,
              let transform = entity.component(ofType: TransformComponent.self) else { return }
        
        // Interpozlate angle/length/width over time for sweeps/morphs.
        let t = CGFloat(min(max(elapsed / max(duration, 0.0001), 0), 1))
        let eased = t // linear; can adjust if needed
        
        currentAngle = interpolate(from: angle, to: endAngle ?? angle, t: eased)
        let interpolatedLength = interpolate(from: length, to: endLength ?? length, t: eased)
        // Ensure the beam always extends offscreen in its travel direction
        let minBeamLength = hypot(GameFacade.playArea.width, GameFacade.playArea.height) + 40
        currentLength = max(interpolatedLength, minBeamLength)
        currentWidth = interpolate(from: width, to: endWidth ?? width, t: eased)
        
        // Keep transform in math space (0 = right, -π/2 = down); rendering applies sprite offset.
        transform.rotation = currentAngle
        // Note: Laser dimensions (currentLength, currentWidth) are stored in LaserComponent
        // and should be used by the rendering system. TransformComponent doesn't have a scale property.
        
        // Compute alpha for warmup / fade out
        if warmup > 0, elapsed < warmup {
            currentAlpha = CGFloat(elapsed / warmup)
        } else if fadeOut > 0, elapsed >= duration - fadeOut {
            let remaining = duration - elapsed
            currentAlpha = max(0, CGFloat(remaining / fadeOut))
        } else {
            currentAlpha = 1
        }
        
        // If anchored, follow the anchor transform.
        if let anchor = anchorTransform {
            transform.position = anchor.position
        }
        
        elapsed += deltaTime
        if elapsed >= duration {
            GameFacade.shared.entities.destroy(entity)
        }
    }
    
    func canDamage(_ target: GKEntity) -> Bool {
        let id = ObjectIdentifier(target)
        let now = CACurrentMediaTime()
        let last = lastDamageTimestamps[id] ?? 0
        if now - last >= tickInterval {
            lastDamageTimestamps[id] = now
            return true
        }
        return false
    }
    
    private func interpolate(from start: CGFloat, to end: CGFloat, t: CGFloat) -> CGFloat {
        return start + (end - start) * t
    }
}

