//
//  BulletMotionModifiersComponent.swift
//  Touhou
//
//  Created by Assistant on 11/01/25.
//

import Foundation
import GameplayKit

/// Generic per-bullet motion overrides controlled by spellcards/scripts
final class BulletMotionModifiersComponent: GKComponent {
    /// 1.0 = normal time, 0.0 = frozen
    var timeScale: CGFloat = 1.0
    /// Multiplies effective speed (applied by systems)
    var speedScale: CGFloat = 1.0
    /// Optional angle lock; when set, BulletSystem should preserve this facing
    var angleLock: CGFloat?
    /// Optional acceleration applied in movement system (units per second^2)
    var acceleration: CGVector = .zero
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


