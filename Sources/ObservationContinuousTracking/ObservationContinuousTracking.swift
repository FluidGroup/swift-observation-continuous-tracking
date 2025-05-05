import Combine
@_spi(SwiftUI) import Observation
import SwiftUI
@_spi(SwiftUI) import Foundation
@_spi(SwiftUI) import Swift
import os.lock

public struct ObservationTrackingSubscription: Sendable, Cancellable {

  private let onCancel: @Sendable () -> Void

  init(onCancel: @escaping @Sendable () -> Void) {
    self.onCancel = onCancel
  }

  public func cancel() {
    onCancel()
  }

}

public func withContinuousTracking(
  applying block: @escaping () -> Void,
  onChange: @autoclosure () -> @Sendable () -> Void,
  didChange: @autoclosure () -> @Sendable () -> Void,
  isolation: isolated (any Actor)? = #isolation
) -> ObservationTrackingSubscription {

  let isCancelled = OSAllocatedUnfairLock<Bool>.init(initialState: false)

  let _onChange = onChange()
  let _didChange = didChange()

  _withObservationContinuousTracking(
    applying: block,
    isCancelled: isCancelled,
    onChange: _onChange,
    didChange: _didChange
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
  didChange: @escaping @Sendable () -> Void,
  isolation: isolated (any Actor)? = #isolation
) {

  let box = UnsafeSendable(block)

  do {

    withObservationTracking {
      block()
    } onChange: {

      onChange()
      
      if Thread.isMainThread {
        Task { @MainActor in
          perform(
            block: didChange
          )
        }
      } else {
        Task {
          perform(
            block: didChange
          )
        }
      }                

      guard isCancelled.withLock({ !$0 }) else {
        return
      }

      Task {
        await _withObservationContinuousTracking(
          applying: box._value,
          isCancelled: isCancelled,
          onChange: onChange,
          didChange: didChange,
          isolation: isolation
        )
      }

    }
  }

}

private func perform(block: () -> Void, isolation: isolated (any Actor)? = #isolation) {
  block()
}

private struct UnsafeSendable<V>: ~Copyable, @unchecked Sendable {

  let _value: V

  init(_ value: V) {
    _value = value
  }

}
