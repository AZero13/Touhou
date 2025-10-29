//
//  BossComponent.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

final class BossComponent: GKComponent {
    let name: String
    var maxHealth: Int
    var health: Int
    
    init(name: String, health: Int) {
        self.name = name
        self.maxHealth = health
        self.health = health
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


