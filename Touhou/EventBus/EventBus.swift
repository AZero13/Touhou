//
//  EventBus.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

/// Protocol for objects that can listen to game events
protocol EventListener: AnyObject {
    func handleEvent(_ event: GameEvent)
}

/// EventBus - manages event dispatching using GameplayKit's notification system
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
        
        for event in eventsToProcess {
            // Notify all listeners (since we register for all events)
            if let listeners = subscribers["all_events"] {
                // Clean up weak references and notify active listeners
                var activeListeners: [EventListener] = []
                
                for weakListener in listeners {
                    if let listener = weakListener.listener {
                        activeListeners.append(listener)
                    }
                }
                
                // Update subscribers array with only active listeners
                subscribers["all_events"] = activeListeners.map { WeakEventListener($0) }
                
                // Notify all active listeners
                for listener in activeListeners {
                    listener.handleEvent(event)
                }
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
