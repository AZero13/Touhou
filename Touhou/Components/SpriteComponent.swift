//
//  SpriteComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import AppKit
import GameplayKit

/// SpriteComponent - handles visual representation metadata
final class SpriteComponent: GKComponent {
    var textureName: String
    var zIndex: Int
    var color: NSColor?
    var scale: CGFloat = 1.0
    
    init(textureName: String, zIndex: Int, color: NSColor? = nil, scale: CGFloat = 1.0) {
        self.textureName = textureName
        self.zIndex = zIndex
        self.color = color
        self.scale = scale
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
