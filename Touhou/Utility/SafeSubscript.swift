//
//  SafeSubscript.swift
//  Touhou
//
//  Created by Rose on 11/08/25.
//

import Foundation

extension Collection {
    /// Safe subscript that returns nil if index is out of bounds
    /// 
    /// This prevents crashes from out-of-bounds array access by returning an optional.
    /// Use nil-coalescing operator to provide a default value when the index is invalid.
    ///
    /// - Parameter index: The index to access
    /// - Returns: The element at the index, or `nil` if the index is out of bounds
    ///
    /// - Example:
    ///   ```swift
    ///   let scores = [10, 20, 30]
    ///   let score = scores[safe: 5] ?? 0  // Returns 0 if index 5 is out of bounds
    ///   ```
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

