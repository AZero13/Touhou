//
//  EnemyComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

class EnemyComponent: GKComponent {
    var enemyType: String
    var scoreValue: Int
    var dropTable: [ItemType: Float] // probability map
    var attackPattern: EnemyPattern
    var lastShotTime: TimeInterval
    var shotInterval: TimeInterval
    
    init(enemyType: String, scoreValue: Int, dropTable: [ItemType: Float] = [:], attackPattern: EnemyPattern = .singleShot, shotInterval: TimeInterval = 2.0) {
        self.enemyType = enemyType
        self.scoreValue = scoreValue
        self.dropTable = dropTable
        self.attackPattern = attackPattern
        self.lastShotTime = 0
        self.shotInterval = shotInterval
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
