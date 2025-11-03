//
//  ItemComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit
import CoreGraphics

// MARK: - Enums

/// Types of collectible items
enum ItemType: String, CaseIterable {
    case power = "power"
    case point = "point"
    case bomb = "bomb"
    case life = "life"
    case pointBullet = "pointBullet"  // Special item from bullet-to-point conversion
}

// MARK: - Component

/// ItemComponent - handles item state, movement, and collection
/// TH06-style physics: items accelerate upward until reaching max speed, then fall at that speed
final class ItemComponent: GKComponent {
    var itemType: ItemType
    var value: Int
    var isAttractedToPlayer: Bool
    
    // TH06-style physics: items accelerate upward, then fall
    // Scaled up from TH06 values (-2.2 → 3.0, 0.03/frame) for visibility
    private let maxDownwardVelocity: CGFloat = -100   // Cap velocity (negative = down in SpriteKit)
    private let accelerationRate: CGFloat = -30      // Acceleration per second (negative = toward down)
    
    init(itemType: ItemType, value: Int, isAttractedToPlayer: Bool = false) {
        self.itemType = itemType
        self.value = value
        self.isAttractedToPlayer = isAttractedToPlayer
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - GameplayKit Update
    
    override func update(deltaTime: TimeInterval) {
        guard let entity = entity,
              let transform = entity.component(ofType: TransformComponent.self) else { return }
        
        // TH06-style: accelerate velocity.y toward maxDownwardVelocity
        // Velocity starts positive (40) and decreases toward maxDownwardVelocity (-100)
        // Items rise up, then fall down as velocity crosses zero and becomes negative
        if transform.velocity.dy > maxDownwardVelocity {
            transform.velocity.dy = max(maxDownwardVelocity, transform.velocity.dy + accelerationRate * deltaTime)
        }
        
        // Move based on velocity
        transform.position.y += transform.velocity.dy * deltaTime
        
        // Despawn off-screen (TH06 style: bottom or top out of bounds)
        let playArea = GameFacade.playArea
        let despawnBuffer: CGFloat = -50  // Buffer beyond bottom edge
        if transform.position.y < despawnBuffer || transform.position.y > playArea.maxY {
            GameFacade.shared.entities.destroy(entity)
            return
        }
        
        // Check collection with player
        guard let player = GameFacade.shared.entities.getPlayer(),
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
            // Power items: base value 10, bonus when at full power based on count
            if playerPower >= 128 {
                // Score = 10 x (powerItemCount + 1)
                return 10 * (powerItemCount + 1)
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
