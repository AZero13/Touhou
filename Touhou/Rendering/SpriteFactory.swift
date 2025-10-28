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

/// BulletSpriteFactory - creates varied visual bullets
class BulletSpriteFactory: SpriteFactory {
    func createNode(for entity: GKEntity) -> SKNode {
        guard let bulletComponent = entity.component(ofType: BulletComponent.self) else {
            return SKNode()
        }
        
        let node = createBulletShape(for: bulletComponent)
        
        // Set color
        node.fillColor = bulletComponent.color.nsColor
        node.strokeColor = .clear
        
        // Set z-position based on size (larger bullets on top)
        node.zPosition = 50 + CGFloat(bulletComponent.size.radius)
        
        return node
    }
    
    private func createBulletShape(for bullet: BulletComponent) -> SKShapeNode {
        let radius = bullet.size.radius
        
        switch bullet.shape {
        case .circle:
            return SKShapeNode(circleOfRadius: radius)
            
        case .diamond:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: radius))
            path.addLine(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -radius))
            path.addLine(to: CGPoint(x: -radius, y: 0))
            path.closeSubpath()
            return SKShapeNode(path: path)
            
        case .star:
            return createStarShape(radius: radius)
            
        case .square:
            return SKShapeNode(rectOf: CGSize(width: radius * 2, height: radius * 2))
        }
    }
    
    private func createStarShape(radius: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let outerRadius = radius
        let innerRadius = radius * 0.4
        let points = 5
        
        for i in 0..<points * 2 {
            let angle = CGFloat.pi * CGFloat(i) / CGFloat(points)
            let currentRadius = i % 2 == 0 ? outerRadius : innerRadius
            let x = cos(angle) * currentRadius
            let y = sin(angle) * currentRadius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        return SKShapeNode(path: path)
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
