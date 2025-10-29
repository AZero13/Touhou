//
//  BulletComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import CoreGraphics
import GameplayKit
import AppKit

/// Bullet visual properties
enum BulletSize: String, CaseIterable {
    case tiny = "tiny"      // 2px radius
    case small = "small"    // 3px radius  
    case medium = "medium"  // 5px radius
    case large = "large"    // 8px radius
    case huge = "huge"      // 12px radius
    
    var radius: CGFloat {
        switch self {
        case .tiny: return 2
        case .small: return 3
        case .medium: return 5
        case .large: return 8
        case .huge: return 12
        }
    }
}

enum BulletShape: String, CaseIterable {
    case circle = "circle"
    case diamond = "diamond"
    case star = "star"
    case square = "square"
}

enum BulletColor: String, CaseIterable {
    case red = "red"
    case blue = "blue"
    case green = "green"
    case yellow = "yellow"
    case purple = "purple"
    case cyan = "cyan"
    case orange = "orange"
    case pink = "pink"
    
    var nsColor: NSColor {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .purple: return .purple
        case .cyan: return .cyan
        case .orange: return .orange
        case .pink: return .systemPink
        }
    }
}

/// Protocol for entities that can deal damage
protocol Damaging {
    var damage: Int { get }
}

class BulletComponent: GKComponent, Damaging {
    var ownedByPlayer: Bool
    enum BulletType: Equatable {
        case needle
        case amulet
        case homingAmulet
        case enemyBullet
        case custom(String)
    }
    var bulletType: BulletType
    var damage: Int
    var homingStrength: CGFloat? // 0.0 to 1.0 for homing bullets (Reimu's shots)
    var maxTurnRate: CGFloat? // radians per second for smooth homing
    
    // Visual properties
    var size: BulletSize
    var shape: BulletShape
    var color: BulletColor
    var hasTrail: Bool
    var trailLength: Int // Number of trail segments
    
    init(ownedByPlayer: Bool, bulletType: BulletType = .needle, damage: Int = 1, 
         homingStrength: CGFloat? = nil, maxTurnRate: CGFloat? = nil,
         size: BulletSize = .small, shape: BulletShape = .circle, 
         color: BulletColor = .red, hasTrail: Bool = false, trailLength: Int = 3) {
        self.ownedByPlayer = ownedByPlayer
        self.bulletType = bulletType
        self.damage = damage
        self.homingStrength = homingStrength
        self.maxTurnRate = maxTurnRate
        self.size = size
        self.shape = shape
        self.color = color
        self.hasTrail = hasTrail
        self.trailLength = trailLength
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
