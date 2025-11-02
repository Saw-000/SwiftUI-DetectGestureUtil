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
                        } else if state.detected(.drag(minimumDistance: 100)) {
                            return .drag
                        } else if state.detected(.slide(direction: .right, minimumDistance: 50)) {
                            return .rightSlide
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
                        case .drag:
                            if state.gestureValues.last?.timing == .ended {
                                print("Drag Detected End")
                                return true
                            } else {
                                print("Drag Detected location: \(state.gestureValues.last?.dragGestureValue.location)")
                                return false
                            }

                        case .rightSlide:
                            if state.gestureValues.last?.timing == .ended {
                                print("Right Slide Detected End")
                                return true
                            } else {
                                print("Right Slide Detected location: \(state.gestureValues.last?.dragGestureValue.location)")
                                return false
                            }
                            
                        case .leftSwipe:
                            print("Left Swipe Detected")

                        case .tripleTap:
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
    case drag
    case rightSlide
    case leftSwipe
    case tripleTap
}
