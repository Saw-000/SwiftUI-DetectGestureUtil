import SwiftUI
import MyModuleFeatureDetectGesture

struct ContentView: View {
    @State private var detectGestureState = DetectGestureState<MyGestureDetection>()
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.blue)
                .detectGesture(
                    state: $detectGestureState,
                    detectGesture: { state in
                        if state.detected(.tap) {
                            return .tap
                        } else {
                            return nil
                        }
                    },
                    handleGesture: { detection, state in
                        switch detection {
                        case .tap:
                            print("Tap Detected")
                        case .longTap:
                            print("Long Tap Detected")
                        case .rightSwipe:
                            print("Right Swipe Detected")
                        case .drag:
                            print("Drag Detected")
                        case .tripleTap:
                            print("Drag Detected")
                        case .slide:
                            print("Drag Detected")
                        }
                        return true
                    }
                )
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

/// Wanted Detection
enum MyGestureDetection {
    case tap
    case longTap
    case rightSwipe
    case drag
    case tripleTap
    case slide
}
