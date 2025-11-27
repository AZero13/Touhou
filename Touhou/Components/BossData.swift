//
//  BossData.swift
//  Touhou
//
//  Created by Rose on 11/12/25.
//

import Foundation
import CoreGraphics

/// Pure data structure for boss configuration (C-like bag of data)
/// This avoids massive constructors and makes boss spawning cleaner
struct BossData {
    let name: String
    let health: Int
    let position: CGPoint
    let phaseNumber: Int
    let attackPattern: EnemyPattern
    let patternConfig: PatternConfig
    let shotInterval: TimeInterval
    let hasTimeBonus: Bool
    let timeLimit: TimeInterval
    let bonusPointsBase: Int
    let totalPhases: Int
    let phaseHealths: [Int]
    
    // Default values for convenience
    static let defaultHealth = 300
    static let defaultPhaseNumber = 1
    static let defaultAttackPattern = EnemyPattern.tripleShot
    static let defaultPatternConfig = PatternConfig()
    static let defaultShotInterval: TimeInterval = 1.2
    static let defaultHasTimeBonus = false
    static let defaultTimeLimit: TimeInterval = 20.0
    static let defaultBonusPointsBase = 10000
    static let defaultTotalPhases = 1
    
    init(
        name: String,
        health: Int = Self.defaultHealth,
        position: CGPoint,
        phaseNumber: Int = Self.defaultPhaseNumber,
        attackPattern: EnemyPattern = Self.defaultAttackPattern,
        patternConfig: PatternConfig = Self.defaultPatternConfig,
        shotInterval: TimeInterval = Self.defaultShotInterval,
        hasTimeBonus: Bool = Self.defaultHasTimeBonus,
        timeLimit: TimeInterval = Self.defaultTimeLimit,
        bonusPointsBase: Int = Self.defaultBonusPointsBase,
        totalPhases: Int = Self.defaultTotalPhases,
        phaseHealths: [Int] = []
    ) {
        self.name = name
        self.health = health
        self.position = position
        self.phaseNumber = phaseNumber
        self.attackPattern = attackPattern
        self.patternConfig = patternConfig
        self.shotInterval = shotInterval
        self.hasTimeBonus = hasTimeBonus
        self.timeLimit = timeLimit
        self.bonusPointsBase = bonusPointsBase
        self.totalPhases = totalPhases
        self.phaseHealths = phaseHealths.isEmpty ? [health] : phaseHealths
    }
}

