import SwiftUI
import SwiftUI_DetectGestureUtil

struct ContentView: View {
    @State private var detectedGestureText: String? = nil

    @State private var detectGestureState3: DetectGestureState<MyGestureDetection3>? = nil

    var body: some View {
        VStack {
            // Display detected gesture
            Text("Detected: " + (detectedGestureText ?? ""))

            // First gesture detection view
            VStack {
                Text("tap\n" + "long tap\n" + "drag")
                    .font(.title2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.blue)
            .detectGesture(
                MyGestureDetection1.self,
                detectGesture: { state in
                    if state.detected(.tap()) {
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
                        detectedGestureText = "Tap"
                        return .finished

                    case .longTap:
                        detectedGestureText = "Long Tap"
                        return .finished

                    case .drag:
                        if state.lastGestureValue?.timing == .ended {
                            detectedGestureText = "Drag End"
                            return .finished
                        } else {
                            detectedGestureText = "Drag location: \(state.lastGestureValue?.locations)"
                            return .yet
                        }
                    }
                }
            )

            // Second gesture detection view
            VStack {
                Text("right slide\n" + "top swipe\n" + "triple Tap")
                    .font(.title2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.red)
            .detectGesture(
                MyGestureDetection2.self,
                detectGesture: { state in
                    if state.detected(.slide(direction: .right, minimumDistance: 50)) {
                        return .rightSlide
                    } else if state.detected(.swipe(direction: .up)) {
                        return .topSwipe
                    } else if state.detected(.sequentialTap(count: 3, maximumTapIntervalMilliseconds: 250)) {
                        return .tripleTap
                    }

                    return nil
                },
                handleGesture: { detection, state in
                    switch detection {
                    case .rightSlide:
                        if state.lastGestureValue?.timing == .ended {
                            detectedGestureText = "Right Slide End"
                            return .finished
                        } else {
                            detectedGestureText = "Right Slide location: \(state.lastGestureValue?.locations)"
                            return .yet
                        }

                    case .topSwipe:
                        detectedGestureText = "Top Swipe"
                        return .finished

                    case .tripleTap:
                        detectedGestureText = "Triple Tap"
                        return .finished
                    }
                }
            )

            ZStack {
                // Third gesture detection view
                VStack {
                    Text("Circle\n" + "Star & Swipe\n")
                        .font(.title2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.orange)
                .detectGesture(
                    MyGestureDetection3.self,
                    detectGesture: { state in
                        detectGestureState3 = state

                        for tapSequence in state.gestureValuesAsTapSequences {
                            for singleFingerTouch in tapSequence.touches {
                                guard !singleFingerTouch.isOverlapped(with: tapSequence.touches) else {
                                    continue
                                }

                                let points = singleFingerTouch.values
                                    .withRawNotifiedGesture() // Get coordinates only when moved.
                                    .map { $0.fingerEvent.location }

                                if detectStar(points: points) {
                                    return .star_swipe
                                } else if detectCircle(points: points) {
                                    return .circle
                                }
                            }
                        }

                        return nil
                    },
                    handleGesture: { detection, state in
                        detectGestureState3 = state

                        switch detection {
                        case .circle:
                            if state.lastGestureValue?.timing == .ended {
                                detectedGestureText = "Circle End"
                                return .finished
                            } else {
                                detectedGestureText = "Circle location: \(state.lastGestureValue?.locations)"
                                return .yet
                            }

                        case .star_swipe:
                            detectedGestureText = "Star"

                            // End when swiped
                            guard
                                let lastTapSequence = state.lastTapSequence,
                                lastTapSequence.touches.count > 0
                            else {
                                return .yet
                            }

                            let isSwiped = lastTapSequence.anySingleFingerTouchContains { singleFingerTouch, _ in
                                let lastTapValues = singleFingerTouch.values.map { $0.attachmentInfo }

                                return state.detected(.swipe(direction: .up), gestureValues: lastTapValues)
                                    || state.detected(.swipe(direction: .left), gestureValues: lastTapValues)
                                    || state.detected(.swipe(direction: .right), gestureValues: lastTapValues)
                                    || state.detected(.swipe(direction: .down), gestureValues: lastTapValues)
                            }

                            if isSwiped {
                                detectedGestureText = "Star Swiped!"
                                return .finished
                            }

                            return .yet
                        }
                    },
                    gestureEnded: { _, _ in
                        detectGestureState3 = nil
                    }
                )

                // Drawing trajectory
                Path { path in
                    detectGestureState3?.processPerSingleFingerTouch { singleFingerTouch, _ in
                        let points = singleFingerTouch.values.map { $0.fingerEvent.location }
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for p in points {
                            path.addLine(to: p)
                        }
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
    /// Single tap gesture
    case tap
    /// Long tap gesture
    case longTap
    /// Drag gesture
    case drag
}

/// Wanted Gesture Detection
enum MyGestureDetection2 {
    /// Slide to the right
    case rightSlide
    /// Swipe upward
    case topSwipe
    /// Triple tap gesture
    case tripleTap
}

/// Wanted Gesture Detection
enum MyGestureDetection3 {
    /// Circle drawing gesture
    case circle
    /// Star drawing followed by swipe gesture
    case star_swipe
}

// MARK: - Shape detection algorithms

/// Simple circle detection
private func detectCircle(points: [CGPoint]) -> Bool {
    guard points.count > 100 else { return false }
    let first = points.first!
    let last = points.last!

    // Distance between start and end points
    let dist = hypot(first.x - last.x, first.y - last.y)

    // Calculate variance (variation) of radius (distance from center to each point).
    let center = CGPoint(
        x: points.map { $0.x }.reduce(0,+) / CGFloat(points.count),
        y: points.map { $0.y }.reduce(0,+) / CGFloat(points.count)
    )
    let radii = points.map { hypot($0.x - center.x, $0.y - center.y) }
    let mean = radii.reduce(0,+) / CGFloat(radii.count)
    let variance = radii.map { pow($0 - mean, 2.0) }.reduce(0,+) / CGFloat(radii.count)

    // Calculate number of corners: consider as circle only if there are few sharp angle changes
    let angles = calculateTurningAngles(points: points)
    let peakCount = angles.filter { abs($0) > 50 }.count // Angle threshold is adjustable
    if peakCount > 4 { return false } // Not a circle if there are many corners (peaks)

    // Consider as circle if "start and end points are close" and "variance of coordinate distances is small" and "almost no vertices"
    return dist < 40 && variance < 600 && peakCount < 3
}

/// Simple star shape detection
func detectStar(points: [CGPoint], angleThreshold: CGFloat = 60, closedDistanceRatio: CGFloat = 0.25, minPoints: Int = 42) -> Bool {
    guard points.count > minPoints else { return false }
    let angles = calculateTurningAngles(points: points)
    let anglePeaks = angles.enumerated()
        .filter { abs($0.element) > angleThreshold }
        // Only adopt if peak position is more than a certain distance from previous or last
        .reduce(into: [Int]()) { result, next in
            if let last = result.last, next.offset - last < 5 { return }
            result.append(next.offset)
        }

    let first = points.first!
    let last = points.last!
    let dist = hypot(first.x - last.x, first.y - last.y)
    let perim = totalLength(points)
    // Start and end points are sufficiently close relative to drawing range
    if dist > perim * closedDistanceRatio { return false }

    // Number of peaks (strictly follow range to prevent false detection)
    if anglePeaks.count < 8 || anglePeaks.count > 12 { return false }

    return true
}

/// Accumulated distance between two points
private func totalLength(_ points: [CGPoint]) -> CGFloat {
    guard points.count > 1 else { return 0 }
    return zip(points, points.dropFirst()).map { hypot($0.0.x - $0.1.x, $0.0.y - $0.1.y) }.reduce(0, +)
}

/// Returns list of trajectory direction angle changes
private func calculateTurningAngles(points: [CGPoint]) -> [CGFloat] {
    guard points.count > 2 else { return [] }
    var angles: [CGFloat] = []
    for i in 1 ..< points.count - 1 {
        let a = points[i - 1]
        let b = points[i]
        let c = points[i + 1]
        let v1 = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let v2 = CGPoint(x: c.x - b.x, y: c.y - b.y)
        let angle = atan2(v2.y, v2.x) - atan2(v1.y, v1.x)
        angles.append(angle * 180 / .pi) // Return in degrees
    }
    return angles
}
