//
//  ItemComponent.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

enum ItemType: String, CaseIterable {
    case power = "power"
    case point = "point"
    case bomb = "bomb"
    case life = "life"
}

class ItemComponent: GKComponent {
    var itemType: ItemType
    var value: Int
    var isAttractedToPlayer: Bool
    
    init(itemType: ItemType, value: Int, isAttractedToPlayer: Bool = false) {
        self.itemType = itemType
        self.value = value
        self.isAttractedToPlayer = isAttractedToPlayer
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
