//
//  PowerSystem.swift
//  Touhou
//
//  Created by Rose on 11/07/25.
//

import Foundation
import GameplayKit

final class PowerSystem: GameSystem {
    private var entityManager: EntityManager!
    private var eventBus: EventBus!
    
    static let powerThresholds: [Int] = [8, 16, 32, 48, 64, 80, 96, 128]
    
    func initialize(entityManager: EntityManager, eventBus: EventBus) {
        self.entityManager = entityManager
        self.eventBus = eventBus
    }
    
    func update(deltaTime: TimeInterval) {
        guard let playerEntity = entityManager.getPlayerEntity(),
              let playerComp = playerEntity.component(ofType: PlayerComponent.self),
              let playerTransform = playerEntity.component(ofType: TransformComponent.self),
              playerComp.power >= 128,
              playerTransform.position.y < 128.0 else { return }
        eventBus.fire(AttractItemsEvent(itemTypes: [.power, .point, .pointBullet, .bomb, .life]))
    }
    
    func handleEvent(_ event: GameEvent) {
        if let powerEvent = event as? PowerLevelChangedEvent {
            handlePowerChanged(newPower: powerEvent.newTotal)
        }
    }
    
    private func handlePowerChanged(newPower: Int) {
        if newPower >= 128 {
            BulletUtility.convertBulletsToPoints(entityManager: entityManager)
            eventBus.fire(AttractItemsEvent(itemTypes: [.point, .pointBullet]))
        }
    }
    
    @inlinable
    static func getPowerRank(power: Int) -> Int {
        for (index, threshold) in powerThresholds.enumerated() {
            if power < threshold {
                return index
            }
        }
        return powerThresholds.count
    }
    
    @inlinable
    static func getThresholdForRank(_ rank: Int) -> Int {
        powerThresholds[safe: rank] ?? (powerThresholds.last ?? 128)
    }
}

