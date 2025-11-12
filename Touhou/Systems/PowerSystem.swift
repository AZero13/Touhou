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
    
    func initialize(context: GameRuntimeContext) {
        self.entityManager = context.entityManager
        self.eventBus = context.eventBus
    }
    
    func update(deltaTime: TimeInterval, context: GameRuntimeContext) {
        guard let playerEntity = entityManager.getPlayerEntity(),
              let playerComp = playerEntity.component(ofType: PlayerComponent.self),
              let playerTransform = playerEntity.component(ofType: TransformComponent.self),
              playerComp.power >= 128,
              playerTransform.position.y < 128.0 else { return }
        eventBus.fire(AttractItemsEvent(itemTypes: [.power, .point, .pointBullet, .bomb, .life]))
    }
    
    func handleEvent(_ event: GameEvent, context: GameRuntimeContext) {
        if let powerEvent = event as? PowerLevelChangedEvent {
            handlePowerChanged(newPower: powerEvent.newTotal, context: context)
        }
    }
    
    func handleEvent(_ event: GameEvent) {
        // Fallback for non-GameSystem listeners (shouldn't be called)
        fatalError("PowerSystem.handleEvent without context should not be called")
    }
    
    private func handlePowerChanged(newPower: Int, context: GameRuntimeContext) {
        if newPower >= 128 {
            BulletUtility.convertBulletsToPoints(entityManager: entityManager, context: context)
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


