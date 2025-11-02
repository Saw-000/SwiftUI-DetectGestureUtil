import SwiftUI
import MyModuleFeatureDetectGesture

struct ContentView: View {
    @State private var detectedGestureText: String? = nil

    @State private var detectGestureState1 = DetectGestureState<MyGestureDetection>()
    @State private var detectGestureState2 = DetectGestureState<MyGestureDetection>()
    @State private var detectGestureState3 = DetectGestureState<MyGestureDetection>()
    
    var body: some View {
        VStack {
            // 検知したジェスチャを表示するところ
            Text(detectedGestureText ?? "")
            
            // 1個目のジェスチャ検知用View
            VStack {
                Text("DefaultGesture:\n" + "tap\n" + "long tap\n" + "drag")
                    .font(.title2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.blue)
            .detectGesture(
                state: $detectGestureState1,
                detectGesture: { state in
                    if state.detected(.tap) {
                        return .tap
                    } else if state.detected(.longTap(minimumMilliSeconds: 1000)) {
                        return .longTap
                    } else if state.detected(.drag(minimumDistance: 30)) {
                        return .drag
                    } else {
                        return nil
                    }
                },
                handleGesture: { detection, state in
                    switch detection {
                    case .tap:
                        detectedGestureText = "Tap Detected"
                        return true

                    case .longTap:
                        detectedGestureText = "Long Tap Detected"
                        return true

                    case .drag:
                        if state.gestureValues.last?.timing == .ended {
                            detectedGestureText = "Drag Detected End"
                            return true
                        } else {
                            detectedGestureText = "Drag Detected location: \(state.gestureValues.last?.dragGestureValue.location)"
                            return false
                        }

                    default:
                        return true
                    }
                }
            )
            
            // 2個目のジェスチャ検知用View
            VStack {
                Text("DefaultGesture:\n" + "right slide\n" + "top swipe\n" + "triple Tap")
                    .font(.title2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.red)
            .detectGesture(
                state: $detectGestureState2,
                detectGesture: { state in
                    if state.detected(.slide(direction: .right, minimumDistance: 50)) {
                        return .rightSlide
                    } else if state.detected(.swipe(direction: .top)) {
                        return .topSwipe
                    } else if state.detected(.sequentialTap(count: 3, maximumTapIntervalMilliseconds: 250)) {
                        return .tripleTap
                    } else {
                        return nil
                    }
                },
                handleGesture: { detection, state in
                    switch detection {
                    case .rightSlide:
                        if state.gestureValues.last?.timing == .ended {
                            detectedGestureText = "Right Slide Detected End"
                            return true
                        } else {
                            detectedGestureText = "Right Slide Detected location: \(state.gestureValues.last?.dragGestureValue.location)"
                            return false
                        }
                        
                    case .topSwipe:
                        detectedGestureText = "Top Swipe Detected"
                        return true

                    case .tripleTap:
                        detectedGestureText = "Triple Tap Detected"
                        return true
                        
                    default:
                        return true
                    }
                }
            )
            
            // 3個目のジェスチャ検知用View
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
    case topSwipe
    case tripleTap
}
