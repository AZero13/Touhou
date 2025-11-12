//
//  BulletModifierSystem.swift
//  Touhou
//
//  Created by Rose on 11/01/25.
//
//  System that applies bullet modifiers over time
//  Allows bullets to change behavior (rotation, speed, etc.) at specific times
//  Mimics TH06's ins_46, ins_48 rotation commands

import Foundation
import GameplayKit

/// Scheduled modifier change for bullets
struct BulletModifierChange {
    let delay: TimeInterval
    let selector: BulletSelector
    let modifier: (BulletMotionModifiersComponent) -> Void
}

/// System that applies bullet modifiers over time
/// Used for patterns like TH06 Sub0 that rotate bullets at specific times
final class BulletModifierSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    private var scheduledChanges: [BulletModifierChange] = []
    private var timer: TimeInterval = 0
    private var isActive: Bool = false
    
    func initialize(context: GameRuntimeContext) {
        self.entityManager = context.entityManager
        self.eventBus = context.eventBus
    }
    
    func update(deltaTime: TimeInterval, context: GameRuntimeContext) {
        guard isActive else { return }
        
        timer += deltaTime
        
        // Process scheduled changes that are due
        var remainingChanges: [BulletModifierChange] = []
        for change in scheduledChanges {
            if timer >= change.delay {
                // Apply the modifier to matching bullets
                let bullets = entityManager.getEntities(with: BulletComponent.self)
                for entity in bullets {
                    guard let bullet = entity.component(ofType: BulletComponent.self) else { continue }
                    if !change.selector.matches(bullet: bullet) { continue }
                    
                    let mods = entity.component(ofType: BulletMotionModifiersComponent.self)
                        ?? BulletMotionModifiersComponent()
                    if entity.component(ofType: BulletMotionModifiersComponent.self) == nil {
                        entity.addComponent(mods)
                    }
                    change.modifier(mods)
                }
            } else {
                remainingChanges.append(change)
            }
        }
        scheduledChanges = remainingChanges
        
        // Stop when all changes are processed
        if scheduledChanges.isEmpty {
            isActive = false
        }
    }
    
    func handleEvent(_ event: GameEvent, context: GameRuntimeContext) {
        // Reset on stage start
        if event is StageStartedEvent {
            scheduledChanges.removeAll()
            timer = 0
            isActive = false
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        // Fallback for non-GameSystem listeners (shouldn't be called)
        fatalError("BulletModifierSystem.handleEvent without context should not be called")
    }
    
    // MARK: - Public API
    
    /// Schedule a modifier change for bullets matching selector
    /// delay: Time in seconds from now when to apply the change
    func scheduleChange(delay: TimeInterval, selector: BulletSelector, modifier: @escaping (BulletMotionModifiersComponent) -> Void) {
        scheduledChanges.append(BulletModifierChange(
            delay: timer + delay,
            selector: selector,
            modifier: modifier
        ))
        isActive = true
    }
    
    /// Start a rotation sequence for bullets matching selector
    /// Example: After 2 seconds, set angle lock, then after 0.667 seconds change angle, then after 1.333 seconds remove lock
    func scheduleRotationSequence(selector: BulletSelector, steps: [(delay: TimeInterval, angleLock: CGFloat?)]) {
        var cumulativeDelay: TimeInterval = 0
        for step in steps {
            cumulativeDelay += step.delay
            scheduleChange(delay: cumulativeDelay, selector: selector) { mods in
                mods.angleLock = step.angleLock
            }
        }
    }
    
    /// Start the system (called when patterns that need modifiers start)
    func start() {
        timer = 0
        isActive = true
    }
    
    /// Stop the system
    func stop() {
        isActive = false
        scheduledChanges.removeAll()
    }
}

