//
//  RenderComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import SpriteKit
import GameplayKit

final class RenderComponent: GKComponent {
    let node: SKNode
    
    @inlinable
    var zPosition: CGFloat {
        get { node.zPosition }
        set { node.zPosition = newValue }
    }
    
    @inlinable
    var alpha: CGFloat {
        get { node.alpha }
        set { node.alpha = newValue }
    }
    
    @inlinable
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
    
    override func willRemoveFromEntity() {
        node.removeFromParent()
    }
}

