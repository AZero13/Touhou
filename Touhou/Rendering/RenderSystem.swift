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
    // Play area dimensions (logical coordinates)
    private var logicalWidth: CGFloat { GameFacade.playArea.width }
    private var logicalHeight: CGFloat { GameFacade.playArea.height }
    
    private enum VisualConstants {
        static let fairyRadius: CGFloat = 9
        static let bossRadius: CGFloat = 16
    }
    
    /// Sync entities with their visual representations
    /// - Parameters:
    ///   - entities: Entity facade to get all entities from
    ///   - scene: The SpriteKit scene to render to
    ///   - worldLayer: Direct reference to world layer (optimized, avoids string lookup)
    ///   - bossLayer: Direct reference to boss layer
    ///   - effectLayer: Direct reference to effect layer
    func sync(entities: EntityFacade, scene: SKScene, worldLayer: SKNode, bossLayer: SKNode, effectLayer: SKNode) {
        let allEntities = entities.getAllEntities()
        
        // Calculate scale factors
        let scaleX = scene.size.width / logicalWidth
        let scaleY = scene.size.height / logicalHeight
        
        // Update all entities with RenderComponent
        for entity in allEntities {
            if let render = entity.component(ofType: RenderComponent.self) {
                let node = render.node
                
                // Ensure node is in scene (SpriteKit tree management)
                if node.parent == nil {
                    worldLayer.addChild(node)
                }

                // Update position from TransformComponent
                if let transform = entity.component(ofType: TransformComponent.self) {
                    node.position = CGPoint(
                        x: transform.position.x * scaleX,
                        y: transform.position.y * scaleY
                    )
                    node.zRotation = transform.rotation
                }
            } else {
                // Create RenderComponent for entities that need rendering but don't have one yet
                if let node = createNode(for: entity) {
                    entity.addComponent(RenderComponent(node: node))
                    // Node will be added to scene on next iteration (when render != nil)
                    
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
        
        // No manual cleanup needed - nodes are removed when RenderComponent is removed
        // EntityManager handles component removal when entities are destroyed
        
        // Boss health bar overlay (top of screen)
        if let boss = allEntities.first(where: { $0.component(ofType: BossComponent.self) != nil }) {
            // Show boss layer when boss exists
            bossLayer.isHidden = false
            let barWidth = scene.size.width * 0.8
            let barHeight: CGFloat = 12
            let origin = CGPoint(x: (scene.size.width - barWidth) / 2, y: scene.size.height - 30)
            let bgName = "bossHealthBarBG"
            let fillName = "bossHealthBarFill"
            var bg = bossLayer.childNode(withName: bgName) as? SKShapeNode
            if bg == nil {
                let rect = CGRect(x: origin.x, y: origin.y, width: barWidth, height: barHeight)
                bg = SKShapeNode(rect: rect, cornerRadius: 4)
                bg?.name = bgName
                bg?.strokeColor = .white
                bg?.fillColor = .clear
                bg?.zPosition = 301
                if let bgToAdd = bg {
                    bossLayer.addChild(bgToAdd)
                }
            }
            var fill = bossLayer.childNode(withName: fillName) as? SKShapeNode
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
                fill?.zPosition = 300
                if let fillToAdd = fill {
                    bossLayer.addChild(fillToAdd)
                }
            } else {
                let rect = CGRect(x: origin.x, y: origin.y, width: barWidth * pct, height: barHeight)
                fill?.path = CGPath(roundedRect: rect, cornerWidth: 4, cornerHeight: 4, transform: nil)
            }
        } else {
            // Hide boss layer when no boss
            bossLayer.isHidden = true
            // Clean up health bar nodes
            bossLayer.childNode(withName: "bossHealthBarBG")?.removeFromParent()
            bossLayer.childNode(withName: "bossHealthBarFill")?.removeFromParent()
        }
    }
    
    // MARK: - Node Creation (consolidated from SpriteFactory)
    
    private func createNode(for entity: GKEntity) -> SKNode? {
        // Determine entity type and create appropriate node
        if entity.component(ofType: PlayerComponent.self) != nil {
            return createPlayerNode(for: entity)
        } else if entity.component(ofType: BossComponent.self) != nil {
            return createBossNode()
        } else if let bullet = entity.component(ofType: BulletComponent.self) {
            return createBulletNode(for: bullet)
        } else if entity.component(ofType: EnemyComponent.self) != nil {
            return createEnemyNode()
        } else if let item = entity.component(ofType: ItemComponent.self) {
            return createItemNode(for: item)
        }
        
        return nil
    }
    
    private func createPlayerNode(for entity: GKEntity) -> SKNode {
        // Get visual radius from PlayerComponent (component owns visual size)
        let radius = entity.component(ofType: PlayerComponent.self)?.visualRadius ?? 8.0
        let circle = SKShapeNode(circleOfRadius: radius)
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
        let circle = SKShapeNode(circleOfRadius: VisualConstants.fairyRadius)
        circle.fillColor = .yellow
        circle.strokeColor = .clear
        circle.zPosition = 75
        return circle
    }
    
    private func createBossNode() -> SKNode {
        let circle = SKShapeNode(circleOfRadius: VisualConstants.bossRadius)
        circle.fillColor = .systemPink
        circle.strokeColor = .clear
        circle.zPosition = 80
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
        case .pointBullet:
            circle.fillColor = .yellow
        }
        
        circle.strokeColor = .clear
        circle.zPosition = 25
        return circle
    }
}
