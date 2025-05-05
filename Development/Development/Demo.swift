import SwiftUI
import ObservationContinuousTracking

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
        Text("Count: \(controller.count)")          
        Button("Up") {
          controller.increment()
        }
        Button("Background Up") {        
          controller.backgroundIncrement()
        }
      }
      .onAppear {
        
//        withContinuousTracking {
//          _ = controller.count
//        } onChange: {
//          print("onChange", Thread.current)          
//        } didChange: {
//          print("didChange", Thread.current)
//          print("\(controller.count)")
//        }
        
//        Task.detached {
          withContinuousTracking {
            _ = controller.count
          } onChange: {
            print("onChange", Thread.current)          
          } didChange: {
            print("didChange", Thread.current)

            print("Did Change Count: \(controller.count)")
          }
//        }
        
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


@MainActor
func UI() {
  
}

#endif
