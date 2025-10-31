//
//  TaskScheduler.swift
//  Touhou
//
//  Created by Rose on 10/29/25.
//

import Foundation
import GameplayKit

/// Minimal single-threaded scheduler for authoring timed gameplay patterns
final class TaskScheduler {
    enum Step {
        case wait(TimeInterval)
        case run((_ entityManager: EntityManager, _ commandQueue: CommandQueue) -> Void)
    }
    
    final class TaskHandle {
        fileprivate var isCancelled: Bool = false
    }
    
    private struct TaskState {
        weak var owner: GKEntity?
        var steps: [Step]
        var currentIndex: Int
        var waitRemaining: TimeInterval
        let repeatEvery: TimeInterval?
        let handle: TaskHandle
    }
    
    private var tasks: [TaskState] = []
    
    func schedule(owner: GKEntity?, steps: [Step], repeatEvery: TimeInterval? = nil) -> TaskHandle {
        let handle = TaskHandle()
        let state = TaskState(owner: owner, steps: steps, currentIndex: 0, waitRemaining: 0, repeatEvery: repeatEvery, handle: handle)
        tasks.append(state)
        return handle
    }
    
    func cancel(_ handle: TaskHandle) {
        handle.isCancelled = true
    }
    
    func reset() {
        tasks.removeAll()
    }
    
    func update(deltaTime: TimeInterval, entityManager: EntityManager, commandQueue: CommandQueue) {
        guard !tasks.isEmpty else { return }
        var next: [TaskState] = []
        for var task in tasks {
            // Skip if cancelled
            if task.handle.isCancelled { continue }
            // Skip if owner is gone
            if let owner = task.owner {
                if !entityManager.getAllEntities().contains(owner) { continue }
            }
            var dt = deltaTime
            var finished = false
            while dt > 0 && !finished {
                // Honor pending wait regardless of step content
                if task.waitRemaining > 0 {
                    let consume = min(dt, task.waitRemaining)
                    task.waitRemaining -= consume
                    dt -= consume
                    if task.waitRemaining > 0 { continue }
                }
                if task.currentIndex >= task.steps.count {
                    // Completed sequence
                    if let interval = task.repeatEvery {
                        task.currentIndex = 0
                        task.waitRemaining = interval
                        continue
                    } else {
                        finished = true
                        break
                    }
                }
                let step = task.steps[task.currentIndex]
                switch step {
                case let .wait(t):
                    task.waitRemaining = t
                    // Loop will consume wait on next iteration
                    // Do not advance time here; immediately iterate to handle waitRemaining
                    continue
                case let .run(action):
                    action(entityManager, commandQueue)
                    task.currentIndex += 1
                }
            }
            if !finished { next.append(task) }
        }
        tasks = next
    }
}

private extension TaskScheduler.Step {
    var isWait: Bool {
        if case .wait = self { return true }
        return false
    }
}


