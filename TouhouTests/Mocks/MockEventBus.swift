//
//  MockEventBus.swift
//  TouhouTests
//
//  Created by Antigravity on 11/27/25.
//

import Foundation
@testable import Touhou

/// Mock implementation of EventDispatching for testing
@MainActor
final class MockEventBus: EventDispatching {
    private(set) var firedEvents: [GameEvent] = []
    private(set) var registeredListeners: [ObjectIdentifier] = []
    
    // Tracking for verification
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0
    private(set) var fireCallCount = 0
    private(set) var processEventsCallCount = 0
    
    func register(listener: EventListener) {
        registerCallCount += 1
        registeredListeners.append(ObjectIdentifier(listener))
    }
    
    func unregister(_ listener: EventListener) {
        unregisterCallCount += 1
        registeredListeners.removeAll { $0 == ObjectIdentifier(listener) }
    }
    
    func fire(_ event: GameEvent) {
        fireCallCount += 1
        firedEvents.append(event)
    }
    
    func processEvents(context: GameRuntimeContext?) {
        processEventsCallCount += 1
        // Mock does not actually process events - just tracks the call
    }
    
    // Helper methods for testing
    func reset() {
        firedEvents.removeAll()
        registeredListeners.removeAll()
        registerCallCount = 0
        unregisterCallCount = 0
        fireCallCount = 0
        processEventsCallCount = 0
    }
    
    func didFire<T: GameEvent>(_ eventType: T.Type) -> Bool {
        firedEvents.contains { $0 is T }
    }
    
    func getEvents<T: GameEvent>(ofType eventType: T.Type) -> [T] {
        firedEvents.compactMap { $0 as? T }
    }
    
    func lastEvent<T: GameEvent>(ofType eventType: T.Type) -> T? {
        firedEvents.last(where: { $0 is T }) as? T
    }
}
