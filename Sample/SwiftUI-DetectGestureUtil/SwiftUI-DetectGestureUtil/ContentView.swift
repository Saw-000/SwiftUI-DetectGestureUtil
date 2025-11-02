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
                    } else if state.detected(.swipe(direction: .up)) {
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
                    Text("CustomGesture:\n" + "Circle\n" + "Star & Swipe\n")
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
                            
                            if detectStar(points: points) {
                                return .star_swipe
                            } else if detectCircle(points: points) {
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

                        case .star_swipe:
                            detectedGestureText = "Star Detected"
                            
                            // スワイプされたら終了
                            guard
                                var lastTapPoints = state.tapSplittedGestureValues.last,
                                lastTapPoints.count >= 2
                            else {
                                return false
                            }
                            
                            lastTapPoints = lastTapPoints.filter { $0.timing != .heartbeat }
                            
                            if
                                state.detected(.swipe(direction: .up), gestureValues: lastTapPoints)
                                    || state.detected(.swipe(direction: .left), gestureValues: lastTapPoints)
                                    || state.detected(.swipe(direction: .right), gestureValues: lastTapPoints)
                                    || state.detected(.swipe(direction: .down), gestureValues: lastTapPoints)
                            {
                                detectedGestureText = "Star Swiped!"
                                return true
                            }
                            
                            return false
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
    case star_swipe
}

// MARK: - 図形検知のアルゴリズム
/// 簡易的な円判定
private func detectCircle(points: [CGPoint]) -> Bool {
    guard points.count > 100 else { return false }
    let first = points.first!
    let last = points.last!

    // 始点と終点の距離
    let dist = hypot(first.x - last.x, first.y - last.y)

    // 半径（中心点から各点までの距離）の分散（バラつき）を計算。
    let center = CGPoint(
        x: points.map{$0.x}.reduce(0,+)/CGFloat(points.count),
        y: points.map{$0.y}.reduce(0,+)/CGFloat(points.count)
    )
    let radii = points.map { hypot($0.x - center.x, $0.y - center.y) }
    let mean = radii.reduce(0,+)/CGFloat(radii.count)
    let variance = radii.map{ pow($0 - mean, 2.0) }.reduce(0,+) / CGFloat(radii.count)

    // 角数の計算: 急角度変化が少ない場合のみ円とみなす
    let angles = calculateTurningAngles(points: points)
    let peakCount = angles.filter { abs($0) > 50 }.count // 角度しきい値は調整可
    if peakCount > 4 { return false } // 角数（ピーク数）が多い場合は円ではない

    // 「始点と終点が近い」かつ「座標群の距離の分散が小さい」かつ「頂点がほぼない」なら円にする
    return dist < 40 && variance < 600 && peakCount < 3
}

/// 簡易的な星型検知
func detectStar(points: [CGPoint], angleThreshold: CGFloat = 60, closedDistanceRatio: CGFloat = 0.25, minPoints: Int = 42) -> Bool {
    guard points.count > minPoints else { return false }
    let angles = calculateTurningAngles(points: points)
    let anglePeaks = angles.enumerated()
        .filter { abs($0.element) > angleThreshold }
        // 前回や直前とのピーク位置が一定以上離れている場合だけ採用
        .reduce(into: [Int]()) { result, next in
            if let last = result.last, next.offset - last < 5 { return }
            result.append(next.offset)
        }

    let first = points.first!
    let last = points.last!
    let dist = hypot(first.x - last.x, first.y - last.y)
    let perim = totalLength(points)
    // 始点終点が描画範囲に対して十分近い
    if dist > perim * closedDistanceRatio { return false }
    
    // ピーク回数（誤検知防止のため範囲を厳守）
    if anglePeaks.count < 8 || anglePeaks.count > 12 { return false }

    return true
}

/// 2点間距離の累積
private func totalLength(_ points: [CGPoint]) -> CGFloat {
    guard points.count > 1 else { return 0 }
    return zip(points, points.dropFirst()).map { hypot($0.0.x - $0.1.x, $0.0.y - $0.1.y) }.reduce(0, +)
}

/// 軌跡の進行方向角度の変化リストを返す
private func calculateTurningAngles(points: [CGPoint]) -> [CGFloat] {
    guard points.count > 2 else { return [] }
    var angles: [CGFloat] = []
    for i in 1..<points.count-1 {
        let a = points[i-1]
        let b = points[i]
        let c = points[i+1]
        let v1 = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let v2 = CGPoint(x: c.x - b.x, y: c.y - b.y)
        let angle = atan2(v2.y, v2.x) - atan2(v1.y, v1.x)
        angles.append(angle * 180 / .pi) // 度数で返す
    }
    return angles
}
