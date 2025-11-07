//
//  PowerSystem.swift
//  Touhou
//
//  Created by Assistant on 11/07/25.
//

import Foundation
import GameplayKit

/// PowerSystem - handles power level management and power-based bullet patterns
/// TH06 power system: 0-128, with thresholds at 8, 16, 32, 48, 64, 80, 96, 128
final class PowerSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    // TH06 power thresholds (when bullet patterns change)
    static let powerThresholds: [Int] = [8, 16, 32, 48, 64, 80, 96, 128]
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        // Check for full power mode (128) - auto-attract items when player is in top area
        if let player = entityManager.getEntities(with: PlayerComponent.self).first,
           let playerComp = player.component(ofType: PlayerComponent.self),
           let playerTransform = player.component(ofType: TransformComponent.self),
           playerComp.power >= 128,
           playerTransform.position.y < 128.0 {
            // TH06: At full power and player in top area, auto-attract all items
            eventBus.fire(AttractItemsEvent(itemTypes: [.power, .point, .pointBullet, .bomb, .life]))
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        if let powerEvent = event as? PowerLevelChangedEvent {
            handlePowerChanged(newPower: powerEvent.newTotal)
        }
        // Power loss on death is handled in CommandQueue.adjustLives
    }
    
    // MARK: - Private Methods
    
    private func handlePowerChanged(newPower: Int) {
        // TH06: When power reaches 128 (full power), convert all bullets to points
        if newPower >= 128 {
            BulletUtility.convertBulletsToPoints(entityManager: entityManager)
            eventBus.fire(AttractItemsEvent(itemTypes: [.point, .pointBullet]))
            // Fire full power event (for UI/visual effects)
            // Could add FullPowerActivatedEvent here if needed
        }
    }
    
    // MARK: - Static Helpers
    
    /// Get the current power rank (0-8) based on power level
    static func getPowerRank(power: Int) -> Int {
        for (index, threshold) in powerThresholds.enumerated() {
            if power < threshold {
                return index
            }
        }
        return powerThresholds.count // Max rank (128+)
    }
    
    /// Get the power threshold for a given rank
    static func getThresholdForRank(_ rank: Int) -> Int {
        guard rank >= 0 && rank < powerThresholds.count else {
            return powerThresholds.last ?? 128
        }
        return powerThresholds[rank]
    }
}

