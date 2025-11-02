//
//  RenderSystem.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import SpriteKit
import GameplayKit

/// RenderSystem - handles visual representation of entities
/// NOT a GameSystem (doesn't participate in ECS update loop)
final class RenderSystem {
    private var entityToNode: [GKEntity: SKNode] = [:]
    
    // Play area dimensions (logical coordinates)
    private var logicalWidth: CGFloat { GameFacade.playArea.width }
    private var logicalHeight: CGFloat { GameFacade.playArea.height }
    
    /// Sync entities with their visual representations
    func sync(entityManager: EntityManager, scene: SKScene) {
        let entities = entityManager.getAllEntities()
        
        // Calculate scale factors
        let scaleX = scene.size.width / logicalWidth
        let scaleY = scene.size.height / logicalHeight
        
        // Update existing entities
        for entity in entities {
            if let node = entityToNode[entity] {
                // Update position
                if let transform = entity.component(ofType: TransformComponent.self) {
                    node.position = CGPoint(
                        x: transform.position.x * scaleX,
                        y: transform.position.y * scaleY
                    )
                    node.zRotation = transform.rotation
                }
            } else {
                // Create new node
                if let node = createNode(for: entity) {
                    entityToNode[entity] = node
                    scene.addChild(node)
                    
                    // Set initial position
                    if let transform = entity.component(ofType: TransformComponent.self) {
                        node.position = CGPoint(
                            x: transform.position.x * scaleX,
                            y: transform.position.y * scaleY
                        )
                    }
                }
            }
        }
        
        // Remove nodes for destroyed entities
        let activeEntities = Set(entities)
        let nodesToRemove = entityToNode.keys.filter { !activeEntities.contains($0) }
        
        for entity in nodesToRemove {
            if let node = entityToNode[entity] {
                node.removeFromParent()
                entityToNode.removeValue(forKey: entity)
            }
        }
        
        // Boss health bar overlay (top of screen)
        if let boss = entities.first(where: { $0.component(ofType: BossComponent.self) != nil }) {
            let barWidth = scene.size.width * 0.8
            let barHeight: CGFloat = 12
            let origin = CGPoint(x: (scene.size.width - barWidth) / 2, y: scene.size.height - 30)
            let bgName = "bossHealthBarBG"
            let fillName = "bossHealthBarFill"
            var bg = scene.childNode(withName: bgName) as? SKShapeNode
            if bg == nil {
                let rect = CGRect(x: origin.x, y: origin.y, width: barWidth, height: barHeight)
                bg = SKShapeNode(rect: rect, cornerRadius: 4)
                bg?.name = bgName
                bg?.strokeColor = .white
                bg?.fillColor = .clear
                bg?.zPosition = 2000
                scene.addChild(bg!)
            }
            var fill = scene.childNode(withName: fillName) as? SKShapeNode
            // Get health percentage from HealthComponent
            let pct: CGFloat = {
                if let hc = boss.component(ofType: HealthComponent.self) {
                    return max(0, min(1, CGFloat(hc.health) / CGFloat(hc.maxHealth)))
                }
                return 0
            }()
            if fill == nil {
                let rect = CGRect(x: origin.x, y: origin.y, width: barWidth * pct, height: barHeight)
                fill = SKShapeNode(rect: rect, cornerRadius: 4)
                fill?.name = fillName
                fill?.strokeColor = .clear
                fill?.fillColor = .systemPink
                fill?.zPosition = 2001
                scene.addChild(fill!)
            } else {
                let rect = CGRect(x: origin.x, y: origin.y, width: barWidth * pct, height: barHeight)
                fill?.path = CGPath(roundedRect: rect, cornerWidth: 4, cornerHeight: 4, transform: nil)
            }
        } else {
            // Remove bar if no boss
            scene.childNode(withName: "bossHealthBarBG")?.removeFromParent()
            scene.childNode(withName: "bossHealthBarFill")?.removeFromParent()
        }
    }
    
    // MARK: - Node Creation (consolidated from SpriteFactory)
    
    private func createNode(for entity: GKEntity) -> SKNode? {
        // Determine entity type and create appropriate node
        if entity.component(ofType: PlayerComponent.self) != nil {
            return createPlayerNode()
        } else if let bullet = entity.component(ofType: BulletComponent.self) {
            return createBulletNode(for: bullet)
        } else if entity.component(ofType: EnemyComponent.self) != nil {
            return createEnemyNode()
        } else if let item = entity.component(ofType: ItemComponent.self) {
            return createItemNode(for: item)
        }
        
        return nil
    }
    
    private func createPlayerNode() -> SKNode {
        let circle = SKShapeNode(circleOfRadius: 8)
        circle.fillColor = .white
        circle.strokeColor = .clear
        circle.zPosition = 100
        return circle
    }
    
    private func createBulletNode(for bullet: BulletComponent) -> SKNode {
        let radius = bullet.size.radius
        let shape: SKShapeNode
        
        switch bullet.shape {
        case .circle:
            shape = SKShapeNode(circleOfRadius: radius)
        case .diamond:
            shape = createDiamondShape(radius: radius)
        case .star:
            shape = createStarShape(radius: radius)
        case .square:
            shape = SKShapeNode(rectOf: CGSize(width: radius * 2, height: radius * 2))
        }
        
        shape.fillColor = bullet.color.nsColor
        shape.strokeColor = .clear
        shape.zPosition = 50 + CGFloat(bullet.size.radius)
        
        return shape
    }
    
    private func createDiamondShape(radius: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: radius))
        path.addLine(to: CGPoint(x: radius, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -radius))
        path.addLine(to: CGPoint(x: -radius, y: 0))
        path.closeSubpath()
        return SKShapeNode(path: path)
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
    
    private func createEnemyNode() -> SKNode {
        let circle = SKShapeNode(circleOfRadius: 12)
        circle.fillColor = .yellow
        circle.strokeColor = .clear
        circle.zPosition = 75
        return circle
    }
    
    private func createItemNode(for item: ItemComponent) -> SKNode {
        let circle = SKShapeNode(circleOfRadius: 6)
        
        switch item.itemType {
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
