//
//  BulletComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// Protocol for entities that can deal damage
protocol Damaging {
    var damage: Int { get }
}

class BulletComponent: GKComponent, Damaging {
    var ownedByPlayer: Bool
    var bulletType: String // "needle", "rice", "orb"
    var damage: Int
    var homingStrength: CGFloat? // 0.0 to 1.0 for homing bullets (Reimu's shots)
    var maxTurnRate: CGFloat? // radians per frame for smooth homing
    
    init(ownedByPlayer: Bool, bulletType: String = "needle", damage: Int = 1, 
         homingStrength: CGFloat? = nil, maxTurnRate: CGFloat? = nil) {
        self.ownedByPlayer = ownedByPlayer
        self.bulletType = bulletType
        self.damage = damage
        self.homingStrength = homingStrength
        self.maxTurnRate = maxTurnRate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
