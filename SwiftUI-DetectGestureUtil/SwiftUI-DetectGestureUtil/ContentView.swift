import SwiftUI
import MyModuleFeatureDetectGesture

struct ContentView: View {
    @State private var detectedGestureText: String? = nil

    @State private var detectGestureState1 = DetectGestureState<MyGestureDetection1>()
    @State private var detectGestureState2 = DetectGestureState<MyGestureDetection2>()
    @State private var detectGestureState3 = DetectGestureState<MyGestureDetection3>()
    
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
                    }
                }
            )
            
            ZStack {
                // 3個目のジェスチャ検知用View
                VStack {
                    Text("CustomGesture:\n" + "Circle")
                        .font(.title2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.orange)
                .detectGesture(
                    state: $detectGestureState3,
                    detectGesture: { state in
                        for values in state.tapSplittedGestureValues {
                            let points = values
                                .filter { $0.timing != .heartbeat } // 動いた時だけの座標を取りたい。
                                .map { $0.dragGestureValue.location }
                            
                            if detectCircle(points: points) {
                                return .circle
                            }
                        }
                        
                        return nil
                    },
                    handleGesture: { detection, state in
                        switch detection {
                        case .circle:
                            if state.gestureValues.last?.timing == .ended {
                                detectedGestureText = "Circle Detected End"
                                return true
                            } else {
                                detectedGestureText = "Circle Detected location: \(state.gestureValues.last?.dragGestureValue.location)"
                                return false
                            }
                        }
                    }
                )
                
                // 描画の軌跡
                Path { path in
                    detectGestureState3.tapSplittedGestureValues.forEach { gestureValues in
                        let points = gestureValues.map { $0.dragGestureValue.location }
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for p in points { path.addLine(to: p) }
                    }
                }
                .stroke(.black.opacity(0.5), lineWidth: 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
        }
        .padding()
    }
    
    /// 簡易的な円判定
    private func detectCircle(points: [CGPoint]) -> Bool {
        guard points.count > 100 else { return false }
        let first = points.first!
        let last = points.last!

        // 始点と終点の距離
        let dist = hypot(first.x - last.x, first.y - last.y)

        // 半径（中心点から各点までの距離）の分散（バラつき）を計算。
        // 分散の値が小さいほど、描いた軌跡がきれいな円に近いことを示す。
        // 分散の値が大きいほど、軌跡がいびつで円から外れていることを表す。
        let center = CGPoint(
            x: points.map{$0.x}.reduce(0,+)/CGFloat(points.count),
            y: points.map{$0.y}.reduce(0,+)/CGFloat(points.count)
        )
        let radii = points.map { hypot($0.x - center.x, $0.y - center.y) }
        let mean = radii.reduce(0,+)/CGFloat(radii.count)
        // これが分散
        let variance = radii.map{ pow($0 - mean, 2.0) }.reduce(0,+) / CGFloat(radii.count)
        
        // 「始点と終点が近い」かつ「座標群の距離の分散が小さい」なら円とみなす
        return dist < 40 && variance < 600 // 調整
    }
}

#Preview {
    ContentView()
}

/// Wanted Gesture Detection
enum MyGestureDetection1 {
    case tap
    case longTap
    case drag
}

/// Wanted Gesture Detection
enum MyGestureDetection2 {
    case rightSlide
    case topSwipe
    case tripleTap
}

/// Wanted Gesture Detection
enum MyGestureDetection3 {
    case circle
}

