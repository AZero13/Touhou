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

enum BulletSize: String, CaseIterable {
    case tiny = "tiny"
    case small = "small"
    case medium = "medium"
    case large = "large"
    case huge = "huge"
    
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

final class BulletComponent: GKComponent {
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
    var homingStrength: CGFloat?
    var maxTurnRate: CGFloat?
    var retargetInterval: TimeInterval?
    var maxRetargets: Int?
    var rotationOffset: CGFloat
    var retargetTimer: TimeInterval = 0
    var retargetedCount: Int = 0
    
    var size: BulletSize
    var shape: BulletShape
    var color: BulletColor
    var hasTrail: Bool
    var trailLength: Int
    var groupId: Int?
    var patternId: Int?
    var tags: Set<String>
    
    init(ownedByPlayer: Bool, bulletType: BulletType = .needle, damage: Int = 1,
         size: BulletSize = .small, shape: BulletShape = .circle,
         color: BulletColor = .red, hasTrail: Bool = false, trailLength: Int = 3) {
        self.ownedByPlayer = ownedByPlayer
        self.bulletType = bulletType
        self.damage = damage
        self.homingStrength = nil
        self.maxTurnRate = nil
        self.retargetInterval = nil
        self.maxRetargets = nil
        self.rotationOffset = 0
        self.size = size
        self.shape = shape
        self.color = color
        self.hasTrail = hasTrail
        self.trailLength = trailLength
        self.groupId = nil
        self.patternId = nil
        self.tags = []
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime: TimeInterval) {
        guard let entity = entity,
              let transform = entity.component(ofType: TransformComponent.self) else { return }
        
        let mods = entity.component(ofType: BulletMotionModifiersComponent.self)
        let timeScale: CGFloat = mods?.timeScale ?? 1.0
        let speedScale: CGFloat = mods?.speedScale ?? 1.0
        if timeScale <= 0 { return }
        
        if let a = mods?.acceleration, (a.dx != 0 || a.dy != 0) {
            transform.velocity.dx += a.dx * deltaTime
            transform.velocity.dy += a.dy * deltaTime
        }
        
        if let angle = mods?.angleLock {
            let speed = MathUtility.magnitude(transform.velocity)
            transform.velocity = MathUtility.velocity(angle: angle, speed: speed)
        }
        
        transform.position.x += transform.velocity.dx * deltaTime * timeScale * speedScale
        transform.position.y += transform.velocity.dy * deltaTime * timeScale * speedScale
        
        let playArea = GameFacade.playArea
        if transform.position.x < playArea.minX || transform.position.x > playArea.maxX ||
           transform.position.y < playArea.minY || transform.position.y > playArea.maxY {
            GameFacade.shared.entities.destroy(entity)
        }
    }
}
