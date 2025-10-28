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
    
    init(enemyType: String, scoreValue: Int, dropTable: [ItemType: Float] = [:]) {
        self.enemyType = enemyType
        self.scoreValue = scoreValue
        self.dropTable = dropTable
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
