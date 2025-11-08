//
//  EventBus.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// Protocol for objects that can listen to game events
@MainActor
protocol EventListener: AnyObject {
    func handleEvent(_ event: GameEvent)
}

/// EventBus - manages event dispatching using GameplayKit's notification system
@MainActor
class EventBus {
    private var eventQueue: [GameEvent] = []
    private var subscribers: [String: [WeakEventListener]] = [:]
    
    /// Register a listener for all game events
    func register(listener: EventListener) {
        // Register for all event types by using a generic key
        let key = "all_events"
        
        if subscribers[key] == nil {
            subscribers[key] = []
        }
        
        subscribers[key]?.append(WeakEventListener(listener))
    }
    
    /// Fire an event (queues it for processing at end of frame)
    func fire(_ event: GameEvent) {
        eventQueue.append(event)
    }
    
    /// Process all queued events (called once per frame by GameFacade)
    func processEvents() {
        let eventsToProcess = eventQueue
        eventQueue.removeAll()
        
        // Clean up nil weak references lazily (only if needed, before processing events)
        // Swift convention: clean up when accessing, not proactively
        cleanupWeakReferencesIfNeeded()
        
        for event in eventsToProcess {
            // Notify all listeners (since we register for all events)
            if let listeners = subscribers["all_events"] {
                // Iterate and notify active listeners
                // Weak references are already cleaned up, so we can safely iterate
                for weakListener in listeners {
                    // This check is safe even after cleanup (defensive programming)
                    if let listener = weakListener.listener {
                        listener.handleEvent(event)
                    }
                }
            }
        }
    }
    
    /// Clean up nil weak references lazily (only when needed, Swift-idiomatic)
    /// This is called once per frame before processing events to keep arrays compact
    private func cleanupWeakReferencesIfNeeded() {
        for (key, listeners) in subscribers {
            // Only clean up if we detect nils (lazy cleanup - Swift convention)
            // Use compactMap to filter nils, only update if array actually changed
            let activeListeners = listeners.compactMap { $0.listener }
            if activeListeners.count != listeners.count {
                // Some references became nil, update the array
                subscribers[key] = activeListeners.map { WeakEventListener($0) }
            }
        }
    }
    
    /// Remove a listener from all event types
    func unregister(_ listener: EventListener) {
        for (key, listeners) in subscribers {
            subscribers[key] = listeners.filter { $0.listener !== listener }
        }
    }
}

/// Weak wrapper to prevent retain cycles
private struct WeakEventListener {
    weak var listener: EventListener?
    
    init(_ listener: EventListener) {
        self.listener = listener
    }
}
