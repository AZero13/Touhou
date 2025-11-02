//
//  RenderComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import SpriteKit
import GameplayKit

/// RenderComponent - owns and manages the visual representation of an entity
/// Stores the SKNode and visual properties in the component
final class RenderComponent: GKComponent {
    /// The SpriteKit node for this entity
    let node: SKNode
    
    /// Visual z-position for layering (higher = rendered on top)
    var zPosition: CGFloat {
        get { node.zPosition }
        set { node.zPosition = newValue }
    }
    
    /// Visual alpha/opacity
    var alpha: CGFloat {
        get { node.alpha }
        set { node.alpha = newValue }
    }
    
    /// Visual scale
    var scale: CGFloat {
        get { node.xScale }
        set { 
            node.xScale = newValue
            node.yScale = newValue
        }
    }
    
    init(node: SKNode) {
        self.node = node
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - GameplayKit Lifecycle
    
    /// Called when component is removed from entity - cleanup happens automatically
    override func willRemoveFromEntity() {
        // Remove node from scene tree when component is removed
        node.removeFromParent()
    }
}

