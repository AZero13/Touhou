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
    func sync(engine: GameEngine, scene: SKScene, worldLayer: SKNode, bossLayer: SKNode, effectLayer: SKNode) {
        let allEntities = engine.entityManager.getAllEntities()
        
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
                
                // Update laser visuals (size/alpha) each frame
                if let laser = entity.component(ofType: LaserComponent.self),
                   let sprite = node as? SKSpriteNode {
                    sprite.size = CGSize(width: laser.currentWidth * scaleX,
                                         height: laser.currentLength * scaleY)
                    sprite.alpha = laser.currentAlpha
                    // SpriteKit's "up" is along +Y; our angles use 0=right. Offset by -π/2 once here.
                    if let transform = entity.component(ofType: TransformComponent.self) {
                        sprite.zRotation = transform.rotation - .pi / 2
                    }
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
        // Hide health bar when boss is defeated (it will flee or vanish)
        if let boss = allEntities.first(where: { entity in
            let bossComp = entity.component(ofType: BossComponent.self)
            return bossComp != nil && !(bossComp?.isDefeated ?? false)
        }),
           let bossComp = boss.component(ofType: BossComponent.self) {
            // Show boss layer when boss exists and is not defeated
            bossLayer.isHidden = false
            let barWidth = scene.size.width * 0.8
            let barHeight: CGFloat = 12
            // Move bar down slightly to make room for spell card name above it
            let startY = scene.size.height - 60
            let origin = CGPoint(x: (scene.size.width - barWidth) / 2, y: startY)
            
            // Calculate remaining phases (only show if > 0)
            let remainingPhases = bossComp.totalPhases - bossComp.currentPhase
            
            // Phase counter label (shows remaining phases) - reuse existing node
            let phaseCounterName = "bossPhaseCounter"
            var phaseCounter = bossLayer.childNode(withName: phaseCounterName) as? SKLabelNode
            if remainingPhases > 0 {
                if phaseCounter == nil {
                    phaseCounter = SKLabelNode(text: "\(remainingPhases)")
                    phaseCounter?.name = phaseCounterName
                    phaseCounter?.fontName = "Menlo-Bold"
                    phaseCounter?.fontSize = 16
                    phaseCounter?.fontColor = .white
                    phaseCounter?.zPosition = 402
                    phaseCounter?.verticalAlignmentMode = .center
                    phaseCounter?.horizontalAlignmentMode = .left
                    if let counterToAdd = phaseCounter {
                        bossLayer.addChild(counterToAdd)
                    }
                } else {
                    phaseCounter?.text = "\(remainingPhases)"
                }
                // Position to the right of the health bar
                phaseCounter?.position = CGPoint(x: (scene.size.width + barWidth) / 2 + 10, y: startY)
                phaseCounter?.isHidden = false
            } else {
                // No phases remaining - hide the counter
                phaseCounter?.isHidden = true
            }
            
            // Background bar - reuse existing node
            let bgName = "bossHealthBarBG"
            var bg = bossLayer.childNode(withName: bgName) as? SKShapeNode
            if bg == nil {
                let rect = CGRect(x: origin.x, y: origin.y, width: barWidth, height: barHeight)
                bg = SKShapeNode(rect: rect, cornerRadius: 4)
                bg?.name = bgName
                bg?.strokeColor = .white
                bg?.fillColor = .clear
                bg?.zPosition = 401
                if let bgToAdd = bg {
                    bossLayer.addChild(bgToAdd)
                }
            }
            bg?.isHidden = false
            
            // Fill bar - reuse existing node and update size
            let fillName = "bossHealthBarFill"
            var fill = bossLayer.childNode(withName: fillName) as? SKShapeNode
            
            // Calculate health percentage for current phase
            let phaseIndex = bossComp.currentPhase - 1
            let phaseMaxHealth = bossComp.phaseHealths[phaseIndex]
            let currentHealth = bossComp.currentPhaseHealth
            let pct = max(0, min(1, CGFloat(currentHealth) / CGFloat(phaseMaxHealth)))
            
            if fill == nil {
                let w = max(0, barWidth * pct)
                let rect = CGRect(x: origin.x, y: origin.y, width: w, height: barHeight)
                let safeCorner = min(4, min(w / 2, barHeight / 2))
                fill = SKShapeNode(rect: rect, cornerRadius: safeCorner)
                fill?.name = fillName
                fill?.strokeColor = .clear
                fill?.fillColor = .systemPink
                fill?.zPosition = 400
                if let fillToAdd = fill {
                    bossLayer.addChild(fillToAdd)
                }
            } else {
                // Update existing fill bar size based on current health safely
                let w = max(0, barWidth * pct)
                let rect = CGRect(x: origin.x, y: origin.y, width: w, height: barHeight)
                let safeCorner = min(4, min(w / 2, barHeight / 2))
                if w > 0 {
                    fill?.path = unsafe CGPath(roundedRect: rect, cornerWidth: safeCorner, cornerHeight: safeCorner, transform: nil)
                    fill?.isHidden = false
                } else {
                    fill?.isHidden = true
                }
            }
            if pct > 0 {
                fill?.isHidden = false
            }
        } else {
            // Hide boss layer when no boss
            bossLayer.isHidden = true
            // Clean up health bar nodes and phase counter
            bossLayer.children.forEach { node in
                if node.name?.hasPrefix("bossHealthBar") == true || node.name == "bossPhaseCounter" {
                    node.removeFromParent()
                }
            }
        }
    }
    
    // MARK: - Node Creation (consolidated from SpriteFactory)
    
    private func createNode(for entity: GKEntity) -> SKNode? {
        // Determine entity type and create appropriate node
        if entity.component(ofType: LaserComponent.self) != nil {
            return createLaserNode(for: entity)
        } else if entity.component(ofType: PlayerComponent.self) != nil {
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
        // Add white outline for enemy bullets (TH06 style)
        shape.strokeColor = bullet.ownedByPlayer ? .clear : .white
        shape.lineWidth = bullet.ownedByPlayer ? 0 : 1.0
        shape.zPosition = 50 + CGFloat(bullet.size.radius)
        
        return shape
    }
    
    private func createLaserNode(for entity: GKEntity) -> SKNode {
        let defaultSize = CGSize(width: 8, height: 120)
        let color: NSColor
        if let bullet = entity.component(ofType: BulletComponent.self) {
            color = bullet.color.nsColor
        } else {
            color = .red
        }
        let sprite = SKSpriteNode(color: color, size: defaultSize)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.0) // grow from base upward
        sprite.zPosition = 60
        
        if let laser = entity.component(ofType: LaserComponent.self) {
            // Initialize with current interpolated values so the first frame matches warmup/telegraph
            sprite.size = CGSize(width: laser.currentWidth, height: laser.currentLength)
            sprite.alpha = laser.currentAlpha
        }
        return sprite
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
