//
//  ItemComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit
import CoreGraphics

enum ItemType: String, CaseIterable {
    case power = "power"
    case point = "point"
    case bomb = "bomb"
    case life = "life"
    case pointBullet = "pointBullet"
}

final class ItemComponent: GKComponent {
    var itemType: ItemType
    var value: Int
    var isAttractedToPlayer: Bool
    
    private let maxDownwardVelocity: CGFloat = -100
    private let accelerationRate: CGFloat = -30
    
    init(itemType: ItemType, value: Int, isAttractedToPlayer: Bool = false) {
        self.itemType = itemType
        self.value = value
        self.isAttractedToPlayer = isAttractedToPlayer
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime: TimeInterval) {
        guard let entity = entity,
              let transform = entity.component(ofType: TransformComponent.self) else { return }
        
        if isAttractedToPlayer,
           let player = GameFacade.shared.entities.player,
           let playerTransform = player.component(ofType: TransformComponent.self) {
            let target = playerTransform.position
            let speed: CGFloat = 480
            let desired = MathUtility.velocity(from: transform.position, to: target, speed: speed)
            transform.velocity = desired
            transform.position.x += transform.velocity.dx * deltaTime
            transform.position.y += transform.velocity.dy * deltaTime
        } else {
            // TH06-style: accelerate velocity.y toward maxDownwardVelocity
            // Velocity starts positive (40) and decreases toward maxDownwardVelocity (-100)
            // Items rise up, then fall down as velocity crosses zero and becomes negative
            if transform.velocity.dy > maxDownwardVelocity {
                transform.velocity.dy = max(maxDownwardVelocity, transform.velocity.dy + accelerationRate * deltaTime)
            }
            
            // Move based on velocity
            transform.position.y += transform.velocity.dy * deltaTime
        }
        
        // Despawn off-screen (TH06 style: bottom or top out of bounds)
        let playArea = GameFacade.playArea
        let despawnBuffer: CGFloat = -50  // Buffer beyond bottom edge
        if transform.position.y < despawnBuffer || transform.position.y > playArea.maxY {
            GameFacade.shared.entities.destroy(entity)
            return
        }
        
        // Check collection with player
        guard let player = GameFacade.shared.entities.player,
              let playerTransform = player.component(ofType: TransformComponent.self),
              let playerComp = player.component(ofType: PlayerComponent.self) else { return }
        
        let dx = transform.position.x - playerTransform.position.x
        let dy = transform.position.y - playerTransform.position.y
        let distance = CGFloat(hypot(Double(dx), Double(dy)))
        let collectionRadius: CGFloat = player.component(ofType: HitboxComponent.self)?.itemCollectionZone ?? 20
        
        if distance < collectionRadius {
            // Calculate value based on item type and position
            let calculatedValue = ItemComponent.calculateItemValue(
                itemType: itemType,
                itemPosition: transform.position,
                playerPower: playerComp.power,
                powerItemCount: playerComp.powerItemCountForScore,
                grazeInStage: playerComp.grazeInStage
            )
            
            // Fire collection event and destroy item
            GameFacade.shared.combat.fireItemCollectionEvent(itemType: itemType, value: calculatedValue, position: transform.position)
            GameFacade.shared.entities.destroy(entity)
        }
    }
    
    // MARK: - Static Helpers
    
    static func calculateItemValue(itemType: ItemType, itemPosition: CGPoint, playerPower: Int, powerItemCount: Int, grazeInStage: Int = 0) -> Int {
        switch itemType {
        case .power:
            // TH06: Power items give 10 base score when not at full power
            if playerPower >= 128 {
                // At full power: use TH06 power item score table
                // TH06 table: [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 51200]
                let powerItemScores = [
                    10, 20, 30, 40, 50, 60, 70, 80, 90, 100,
                    200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000,
                    3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 51200
                ]
                // Use safe subscript to prevent out-of-bounds access
                return powerItemScores[safe: powerItemCount] ?? 51200
            }
            return 10
        case .point:
            // Point items: value based on vertical position (higher = more score)
            let playAreaHeight = GameFacade.playArea.height
            let normalizedY = itemPosition.y / playAreaHeight // 0.0 (bottom) to 1.0 (top)
            return max(100, Int(normalizedY * 1000)) // 100 to 1000
        case .pointBullet:
            // TH06 formula: (grazeInStage / 3) * 10 + 500
            return (grazeInStage / 3) * 10 + 500
        case .bomb:
            return 0
        case .life:
            return 0
        }
    }
}
