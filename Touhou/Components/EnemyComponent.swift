//
//  EnemyComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// Protocol for entities that can shoot
protocol Shootable {
    var attackPattern: EnemyPattern { get }
    var bulletConfig: BulletConfig { get }
    var lastShotTime: TimeInterval { get set }
    var shotInterval: TimeInterval { get }
    
    func canShoot(at currentTime: TimeInterval) -> Bool
    func getBulletCommands(from position: CGPoint, targetPosition: CGPoint?) -> [BulletSpawnCommand]
}

/// Protocol for entities that drop items
protocol Droppable {
    var dropItem: ItemType? { get }
}

/// Protocol for entities that can be scored
protocol Scoreable {
    var scoreValue: Int { get }
}

class EnemyComponent: GKComponent, Shootable, Droppable, Scoreable {
    var enemyType: String
    var scoreValue: Int
    var dropItem: ItemType? // What item this enemy drops (nil = no drop)
    var attackPattern: EnemyPattern
    var bulletConfig: BulletConfig
    var lastShotTime: TimeInterval
    var shotInterval: TimeInterval
    
    init(enemyType: String, scoreValue: Int, dropItem: ItemType? = nil, attackPattern: EnemyPattern = .singleShot, bulletConfig: BulletConfig = BulletConfig(), shotInterval: TimeInterval = 2.0) {
        self.enemyType = enemyType
        self.scoreValue = scoreValue
        self.dropItem = dropItem
        self.attackPattern = attackPattern
        self.bulletConfig = bulletConfig
        self.lastShotTime = 0
        self.shotInterval = shotInterval
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Protocol Conformance
    
    func canShoot(at currentTime: TimeInterval) -> Bool {
        return currentTime - lastShotTime >= shotInterval
    }
    
    func getBulletCommands(from position: CGPoint, targetPosition: CGPoint?) -> [BulletSpawnCommand] {
        return attackPattern.getBulletCommands(from: position, targetPosition: targetPosition, config: bulletConfig)
    }
}
