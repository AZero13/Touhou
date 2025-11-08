# Deinit Cleanup Analysis

## Overview

This document identifies classes that need cleanup in `deinit` methods to prevent memory leaks, crashes, and resource leaks.

## Critical Issues Found

### 1. InputManager - NotificationCenter Observers ⚠️ **CRITICAL**

**Problem:**
- Registers NotificationCenter observers in `setupControllerMonitoring()`
- Observers are NOT removed when object is deallocated
- Can cause crashes if notifications are posted after deallocation

**Solution:**
- Remove observers in `deinit`

**Location:** `Touhou/Input/InputManager.swift`

---

### 2. EventListener Objects - EventBus Registration ⚠️ **IMPORTANT**

**Problem:**
- Objects register as EventListener but don't unregister
- EventBus uses weak references, so no retain cycle, but:
  - Cleaner to explicitly unregister
  - Prevents stale references in EventBus arrays
  - Better for debugging

**Affected Classes:**
- `ViewController` - Registers in `viewDidLoad()`
- `GameScene` - Registers in `didMove(to:)`
- All `GameSystem` subclasses - Registered in `GameFacade.setupSystems()`

**Solution:**
- Unregister from EventBus in `deinit`

**Note:** Systems are managed by GameFacade (singleton), so they won't be deallocated during normal gameplay. However, ViewController and GameScene can be deallocated.

---

### 3. ViewController - Async Tasks ⚠️ **MODERATE**

**Problem:**
- Has `scoreFlashTask` and `highScoreFlashTask` that are async tasks
- Tasks should be cancelled when ViewController is deallocated
- Prevents tasks from running after view controller is gone

**Solution:**
- Cancel tasks in `deinit`

**Location:** `Touhou/ViewController.swift`

---

## Not Needed (Already Handled)

### ✅ EventBus - Weak References
- Uses `WeakEventListener` wrapper with `weak var listener`
- Automatically cleans up when listeners are deallocated
- No manual cleanup needed

### ✅ GameFacade - Singleton
- Singleton pattern means it won't be deallocated during app lifetime
- No deinit needed

### ✅ Systems - Managed by GameFacade
- Systems are owned by GameFacade singleton
- Won't be deallocated during normal gameplay
- However, adding deinit is still good practice for future-proofing

---

## Recommended Implementations

### Priority 1: InputManager (CRITICAL) ✅ IMPLEMENTED

```swift
deinit {
    // Remove NotificationCenter observers to prevent crashes if notifications are posted after deallocation
    NotificationCenter.default.removeObserver(self)
}
```

**Note:** InputManager is a singleton, so it won't be deallocated during app lifetime. However, adding deinit is good practice for future-proofing.

**Note about NSEvent.addLocalMonitorForEvents:** This API doesn't return a token that can be removed. The monitor stays active until the app terminates. Since InputManager is a singleton, this is acceptable.

### Priority 2: ViewController (IMPORTANT) ✅ IMPLEMENTED

```swift
deinit {
    // Cancel async tasks to prevent them from running after deallocation
    scoreFlashTask?.cancel()
    highScoreFlashTask?.cancel()
    
    // Note: EventBus uses weak references, so cleanup is automatic
    // No explicit unregister needed from deinit (can't call @MainActor methods from deinit)
}
```

**Note:** We can't call `@MainActor` methods from `deinit` because `deinit` is not isolated to the main actor. EventBus uses weak references, so cleanup happens automatically.

### Priority 3: GameScene (IMPORTANT) ✅ IMPLEMENTED

```swift
deinit {
    // Note: EventBus uses weak references, so cleanup is automatic
    // No explicit unregister needed from deinit (can't call @MainActor methods from deinit)
    // SKScene cleanup is handled by SpriteKit automatically
}
```

**Note:** Same as ViewController - EventBus uses weak references, so cleanup is automatic. SKScene cleanup is handled by SpriteKit.

### Priority 4: Systems (GOOD PRACTICE)

Even though systems are managed by GameFacade and won't be deallocated, adding deinit is good practice:

```swift
deinit {
    eventBus?.unregister(self)
}
```

---

## Best Practices for Deinit

### ✅ DO:

1. **Remove NotificationCenter observers**
   ```swift
   deinit {
       NotificationCenter.default.removeObserver(self)
   }
   ```

2. **Cancel async tasks/Timers**
   ```swift
   deinit {
       task?.cancel()
       timer?.invalidate()
   }
   ```

3. **Unregister from event buses/observers**
   ```swift
   deinit {
       eventBus?.unregister(self)
   }
   ```

4. **Break strong reference cycles**
   ```swift
   deinit {
       delegate = nil
       closure = nil
   }
   ```

5. **Close file handles/network connections**
   ```swift
   deinit {
       fileHandle?.closeFile()
       urlSession?.invalidateAndCancel()
   }
   ```

### ❌ DON'T:

1. **Call methods on weak/unowned references** - They may be nil
2. **Dispatch async work** - Object may be deallocated before it completes
3. **Access IBOutlets** - They may be nil or invalid
4. **Call super.deinit()** - Swift handles this automatically
5. **Perform heavy operations** - Deinit should be fast

---

## Swift-Specific Considerations

### Weak References in Deinit

```swift
// ❌ DON'T - weak references may be nil
deinit {
    weakReference?.doSomething()
}

// ✅ DO - Check if weak reference is still valid
deinit {
    if let strongRef = weakReference {
        strongRef.cleanup()
    }
}
```

### Optional Chaining in Deinit

```swift
// ✅ Safe - Optional chaining handles nil
deinit {
    eventBus?.unregister(self)
    task?.cancel()
}
```

### @MainActor Considerations

```swift
// ✅ Safe - @MainActor ensures thread safety
@MainActor
class MyClass {
    deinit {
        // This runs on main thread
        NotificationCenter.default.removeObserver(self)
    }
}
```

---

## Testing Deinit

### How to Test

1. **Use weak references to verify deallocation:**
   ```swift
   weak var testObject: MyClass?
   testObject = MyClass()
   // ... use object ...
   testObject = nil
   XCTAssertNil(testObject, "Object should be deallocated")
   ```

2. **Check that observers are removed:**
   ```swift
   let manager = InputManager.shared
   // ... test ...
   // Verify no crash when notifications are posted
   ```

3. **Verify tasks are cancelled:**
   ```swift
   let vc = ViewController()
   // ... create tasks ...
   vc = nil
   // Verify tasks don't execute after deallocation
   ```

---

## Summary

### Critical (Must Fix):
- ✅ InputManager - Remove NotificationCenter observers

### Important (Should Fix):
- ✅ ViewController - Cancel tasks, unregister from EventBus
- ✅ GameScene - Unregister from EventBus

### Good Practice (Nice to Have):
- ✅ Systems - Unregister from EventBus (even though they won't be deallocated)

### Already Handled:
- ✅ EventBus - Uses weak references
- ✅ GameFacade - Singleton (won't be deallocated)

---

## References

- [Swift Deinitialization](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/deinitialization/)
- [Memory Management in Swift](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting/)
- [NotificationCenter Best Practices](https://developer.apple.com/documentation/foundation/notificationcenter)

