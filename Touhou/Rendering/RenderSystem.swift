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
class RenderSystem {
    private var entityToNode: [GKEntity: SKNode] = [:]
    private var factories: [String: SpriteFactory] = [:]
    
    // Play area dimensions (logical coordinates)
    private let logicalWidth: CGFloat = 384
    private let logicalHeight: CGFloat = 448
    
    init() {
        setupFactories()
    }
    
    private func setupFactories() {
        factories["player"] = PlayerSpriteFactory()
        factories["bullet"] = BulletSpriteFactory()
        factories["enemy"] = EnemySpriteFactory()
        factories["item"] = ItemSpriteFactory()
    }
    
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
            // Prefer HealthComponent if present, fallback to BossComponent
            let pct: CGFloat = {
                if let hc = boss.component(ofType: HealthComponent.self) {
                    return max(0, min(1, CGFloat(hc.health) / CGFloat(hc.maxHealth)))
                }
                if let bc = boss.component(ofType: BossComponent.self) {
                    return max(0, min(1, CGFloat(bc.health) / CGFloat(bc.maxHealth)))
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
    
    private func createNode(for entity: GKEntity) -> SKNode? {
        // Determine entity type based on components
        if entity.component(ofType: PlayerComponent.self) != nil {
            return factories["player"]?.createNode(for: entity)
        } else if entity.component(ofType: BulletComponent.self) != nil {
            return factories["bullet"]?.createNode(for: entity)
        } else if entity.component(ofType: EnemyComponent.self) != nil {
            return factories["enemy"]?.createNode(for: entity)
        } else if entity.component(ofType: ItemComponent.self) != nil {
            return factories["item"]?.createNode(for: entity)
        }
        
        return nil
    }
}
