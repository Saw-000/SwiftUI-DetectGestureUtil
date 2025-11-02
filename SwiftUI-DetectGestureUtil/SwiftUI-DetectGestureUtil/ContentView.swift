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
                        } else if state.detected(.longTap(minimumMilliSeconds: 1000)) {
                            return .longTap
                        } else if state.detected(.drag(minimumDistance: 50)) {
                            return .drag
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
                            if state.gestureValues.last?.timing == .ended {
                                print("Drag Detected End")
                                return true
                            } else {
                                print("Drag Detected location: \(state.gestureValues.last?.dragGestureValue.location)")
                                return false
                            }
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
