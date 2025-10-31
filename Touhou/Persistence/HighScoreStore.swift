//
//  HighScoreStore.swift
//  Touhou
//
//  Created by Rose on 10/31/25.
//

import Foundation

protocol HighScoreStore {
    func loadHighScore() -> Int
    func saveHighScore(_ value: Int)
}
