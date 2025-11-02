//
//  BulletSpawnerComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// BulletSpawnerComponent - handles automatic bullet pattern spawning
final class BulletSpawnerComponent: GKComponent {
    var patternToFire: String
    var fireRate: TimeInterval
    var lastFireTime: TimeInterval
    var bulletSpeed: CGFloat
    var bulletDamage: Int
    
    init(patternToFire: String = "aimed", 
         fireRate: TimeInterval = 0.1, 
         lastFireTime: TimeInterval = 0,
         bulletSpeed: CGFloat = 200,
         bulletDamage: Int = 1) {
        self.patternToFire = patternToFire
        self.fireRate = fireRate
        self.lastFireTime = lastFireTime
        self.bulletSpeed = bulletSpeed
        self.bulletDamage = bulletDamage
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
