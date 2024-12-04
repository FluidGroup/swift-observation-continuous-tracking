
import Observation
import SwiftUI
import os.lock

import Combine

public struct ObservationTrackingSubscription: Sendable, Cancellable {
  
  private let onCancel: @Sendable () -> Void
  
  init(onCancel: @escaping @Sendable () -> Void) {
    self.onCancel = onCancel
  }
  
  public func cancel() {
    onCancel()
  }
  
}

public func withObservationContinuousTracking(
  applying block: @escaping () -> Void,
  onChange: @autoclosure () -> @Sendable () -> Void,
  isolation: isolated (any Actor)? = #isolation
) -> ObservationTrackingSubscription {
  
  let isCancelled = OSAllocatedUnfairLock<Bool>.init(initialState: false)
  
  let _onChange = onChange()
  
  _withObservationContinuousTracking(
    applying: block,
    isCancelled: isCancelled,
    onChange: _onChange
  )
  
  return .init {
    isCancelled.withLock {
      $0 = true
    }
  }
}

private func _withObservationContinuousTracking(
  applying block: @escaping () -> Void,
  isCancelled: OSAllocatedUnfairLock<Bool>,
  onChange: @escaping @Sendable () -> Void,
  isolation: isolated (any Actor)? = #isolation
) {
  
  let box = UnsafeSendable(block)
  
  do {
    
    withObservationTracking {
      block()      
    } onChange: {
      
      onChange()
      
      guard isCancelled.withLock({ !$0 }) else {
        return
      }
      
      Task {
        await _withObservationContinuousTracking(
          applying: box._value,
          isCancelled: isCancelled,
          onChange: onChange,
          isolation: isolation
        )
      }
      
    }
  }
  
}

private struct UnsafeSendable<V>: ~Copyable, @unchecked Sendable {
  
  let _value: V
  
  init(_ value: V) {
    _value = value  
  }
  
}
