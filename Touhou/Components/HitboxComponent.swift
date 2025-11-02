//
//  HitboxComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import CoreGraphics
import GameplayKit

/// HitboxComponent - handles collision detection zones for different interaction types
final class HitboxComponent: GKComponent {
    var playerHitbox: CGFloat?      // tiny 2x2 pixel zone
    var grazeZone: CGFloat?         // 32 pixel radius
    var enemyHitbox: CGFloat?       // for receiving damage
    var bulletHitbox: CGFloat?       // for dealing damage
    var itemCollectionZone: CGFloat? // item pickup radius
    
    init(playerHitbox: CGFloat? = nil, 
         grazeZone: CGFloat? = nil, 
         enemyHitbox: CGFloat? = nil, 
         bulletHitbox: CGFloat? = nil, 
         itemCollectionZone: CGFloat? = nil) {
        self.playerHitbox = playerHitbox
        self.grazeZone = grazeZone
        self.enemyHitbox = enemyHitbox
        self.bulletHitbox = bulletHitbox
        self.itemCollectionZone = itemCollectionZone
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
