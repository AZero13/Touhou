//
//  UserDefaultsHighScoreStore.swift
//  Touhou
//
//  Created by Rose on 10/31/25.
//

import Foundation

final class UserDefaultsHighScoreStore: HighScoreStore {
    private let key = "HighScore"
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func loadHighScore() -> Int {
        return defaults.integer(forKey: key)
    }
    
    func saveHighScore(_ value: Int) {
        defaults.set(value, forKey: key)
    }
}
