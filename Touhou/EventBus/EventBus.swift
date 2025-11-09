//
//  EventBus.swift
//  Touhou
//
//  Created by Rose on 10/28/25.
//

import Foundation
import GameplayKit

@MainActor
protocol EventListener: AnyObject {
    func handleEvent(_ event: GameEvent)
}

@MainActor
class EventBus {
    private var eventQueue: [GameEvent] = []
    private var subscribers: [String: [WeakEventListener]] = [:]
    
    func register(listener: EventListener) {
        let key = "all_events"
        if subscribers[key] == nil {
            subscribers[key] = []
        }
        subscribers[key]?.append(WeakEventListener(listener))
    }
    
    func fire(_ event: GameEvent) {
        eventQueue.append(event)
    }
    
    func processEvents() {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToProcess = eventQueue
        eventQueue.removeAll()
        cleanupWeakReferencesIfNeeded()
        
        for event in eventsToProcess {
            if let listeners = subscribers["all_events"] {
                for weakListener in listeners {
                    if let listener = weakListener.listener {
                        listener.handleEvent(event)
                    }
                }
            }
        }
    }
    
    private func cleanupWeakReferencesIfNeeded() {
        for (key, listeners) in subscribers {
            let activeListeners = listeners.compactMap { $0.listener }
            if activeListeners.count != listeners.count {
                subscribers[key] = activeListeners.map { WeakEventListener($0) }
            }
        }
    }
    
    func unregister(_ listener: EventListener) {
        for (key, listeners) in subscribers {
            subscribers[key] = listeners.filter { $0.listener !== listener }
        }
    }
}

private struct WeakEventListener {
    weak var listener: EventListener?
    
    init(_ listener: EventListener) {
        self.listener = listener
    }
}
