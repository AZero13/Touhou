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
}

class ItemComponent: GKComponent {
    var itemType: ItemType
    var value: Int
    var isAttractedToPlayer: Bool
    
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
        
        // Basic downward drift
        transform.position.y += transform.velocity.dy * deltaTime
        
        // Despawn off-screen
        if transform.position.y < -50 {
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
                powerItemCount: playerComp.powerItemCountForScore
            )
            
            // Emit power-up collected with calculated value
            GameFacade.shared.getEventBus().fire(PowerUpCollectedEvent(itemType: itemType, value: calculatedValue))
            GameFacade.shared.entities.destroy(entity)
        }
    }
    
    // MARK: - Static Helpers
    
    static func calculateItemValue(itemType: ItemType, itemPosition: CGPoint, playerPower: Int, powerItemCount: Int) -> Int {
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
        case .bomb:
            return 0
        case .life:
            return 0
        }
    }
}
