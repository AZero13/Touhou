//
//  SpriteFactory.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import SpriteKit
import GameplayKit

/// Protocol for creating SKNodes from entities
protocol SpriteFactory {
    func createNode(for entity: GKEntity) -> SKNode
}

/// PlayerSpriteFactory - creates white circle for player
class PlayerSpriteFactory: SpriteFactory {
    func createNode(for entity: GKEntity) -> SKNode {
        let circle = SKShapeNode(circleOfRadius: 8)
        circle.fillColor = .white
        circle.strokeColor = .clear
        circle.zPosition = 100
        return circle
    }
}

/// BulletSpriteFactory - creates colored circles for bullets
class BulletSpriteFactory: SpriteFactory {
    func createNode(for entity: GKEntity) -> SKNode {
        guard let bulletComponent = entity.component(ofType: BulletComponent.self) else {
            return SKNode()
        }
        
        let circle = SKShapeNode(circleOfRadius: 3)
        circle.fillColor = bulletComponent.ownedByPlayer ? .cyan : .red
        circle.strokeColor = .clear
        circle.zPosition = 50
        return circle
    }
}

/// EnemySpriteFactory - creates yellow circles for enemies
class EnemySpriteFactory: SpriteFactory {
    func createNode(for entity: GKEntity) -> SKNode {
        let circle = SKShapeNode(circleOfRadius: 12)
        circle.fillColor = .yellow
        circle.strokeColor = .clear
        circle.zPosition = 75
        return circle
    }
}

/// ItemSpriteFactory - creates colored circles for items
class ItemSpriteFactory: SpriteFactory {
    func createNode(for entity: GKEntity) -> SKNode {
        guard let itemComponent = entity.component(ofType: ItemComponent.self) else {
            return SKNode()
        }
        
        let circle = SKShapeNode(circleOfRadius: 6)
        
        switch itemComponent.itemType {
        case .power:
            circle.fillColor = .red
        case .point:
            circle.fillColor = .blue
        case .bomb:
            circle.fillColor = .purple
        case .life:
            circle.fillColor = .green
        }
        
        circle.strokeColor = .clear
        circle.zPosition = 25
        return circle
    }
}
