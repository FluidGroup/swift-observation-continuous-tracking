import SwiftUI

#if DEBUG

struct BookObservation: View, PreviewProvider {
  var body: some View {
    ContentView()
  }
  
  static var previews: some View {
    Self()
      .previewDisplayName(nil)
  }
  
  private struct ContentView: View {
    
    let controller = Controller()
    
    var body: some View {
      VStack {
        Button("Up") {
          controller.increment()
        }
        Button("Background Up") {
          controller.backgroundIncrement()
        }
      }
      .onAppear {
        
        withObservationContinuousTracking {
          _ = controller.count
        } onChange: {
          //          MainActor.assumeIsolated {
          print("Count: \(controller.count)")
          //          }
        }
        
      }
    }
  }
  
  @Observable
  final class Controller: @unchecked Sendable {
    
    var count: Int = 0
    
    init() {
      
    }
    
    nonisolated func increment() {
      count += 1
    }
    
    func backgroundIncrement() {
      Task {
        count += 1
      }
    }
    
  }
}

private func _a() {
  _ = withObservationContinuousTracking {
    //    UI()
  } onChange: {
    
  }
}

@MainActor
func UI() {
  
}

#endif
