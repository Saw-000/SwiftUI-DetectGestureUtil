import SwiftUI
import MyModuleCore

/// State of DetectGesture
public struct DetectGestureState<GestureDetection: Equatable> {
    /// History of gesture information
    public var gestureValues: [DetectGestureStateValue] = []

    /// History of gesture information separated by tap
    public var tapSplittedGestureValues: [[DetectGestureStateValue]] {
        var result: [[DetectGestureStateValue]] = []
        var buffer: [DetectGestureStateValue] = []

        // Separate at each .ended
        for value in gestureValues {
            buffer.append(value)
            if value.timing == .ended {
                result.append(buffer)
                buffer = []
            }
        }

        // Add the remaining buffer if the end is not .ended
        if !buffer.isEmpty {
            result.append(buffer)
        }

        return result
    }

    /// Detected gesture
    public var detection: GestureDetection? = nil

    /// Whether gesture has already been detected
    public var gestureDetected: Bool {
        detection != nil
    }

    /// Whether handling after gesture detection is finished
    public var handleFinished: Bool = false

    public init() {}

    /// Whether the specified default gesture has already been detected
    public func detected(_ defaultGesture: DefaultDetectGesture, gestureValues: [DetectGestureStateValue]? = nil) -> Bool {
        let gestureValues = gestureValues ?? self.gestureValues
        
        switch defaultGesture {
        case .tap:
            return gestureValues.contains(where: {
                $0.timing == .ended && $0.isInView()
            })

        case let .longTap(minimumMilliSecond):
            var now = Date()
            for value in gestureValues.reversed() {
                if now.timeIntervalSince(value.time) * 1000 >= minimumMilliSecond {
                    return true
                }

                if value.timing == .ended {
                    now = value.time
                }
            }

            return false

        case let .drag(minimumDistance):
            return gestureValues.contains(where: {
                $0.dragGestureValue.translation.distance >= minimumDistance
            })

        case let .slide(direction, minimumDistance):
            return gestureValues.contains(where: {
                let diff = $0.dragGestureValue.diff

                return switch direction {
                case .up:
                    -diff.y >= minimumDistance
                case .down:
                    diff.y >= minimumDistance
                case .left:
                    -diff.x >= minimumDistance
                case .right:
                    diff.x >= minimumDistance
                }
            })

        case .swipe(direction: let direction):
            return gestureValues
                .filter { value in
                    value.timing == .ended
                }
                .contains(where: {
                    let velocity = $0.dragGestureValue.velocity

                    return switch direction {
                    case .up:
                        -velocity.height >= Const.swipeMinimumVelocity
                    case .down:
                        velocity.height >= Const.swipeMinimumVelocity
                    case .left:
                        -velocity.width >= Const.swipeMinimumVelocity
                    case .right:
                        velocity.width >= Const.swipeMinimumVelocity
                    }
                })

        case let .sequentialTap(count, maximumTapIntervalMilliseconds):
            guard count > 0 else {
                return false
            }
            
            let tapEndValueList = gestureValues.filter { $0.timing == .ended && $0.isInView() }
            
            guard tapEndValueList.count >= count else {
                return false
            }
            
            var sequentialTapCount = 1
            var previousTapEndValue: DetectGestureStateValue? = nil

            // Count sequential tap count
            for tapEndValue in tapEndValueList {
                if let pTapEndValue = previousTapEndValue {
                    let isSequentialTap = tapEndValue.time.timeIntervalSince(pTapEndValue.time) * 1000 <= maximumTapIntervalMilliseconds

                    if isSequentialTap {
                        sequentialTapCount += 1
                    } else {
                        // Reset if tap interval exceeds specified seconds
                        sequentialTapCount = 1
                    }

                    // Detect if sequential tap count exceeds specified count
                    if sequentialTapCount >= count {
                        return true
                    }

                    previousTapEndValue = tapEndValue
                } else {
                    previousTapEndValue = tapEndValue
                    continue
                }
            }

            // Sequential tap count never exceeded specified count
            return false
        }
    }
}

/// Value containing gesture state information
public struct DetectGestureStateValue {
    /// Timing of gesture state update
    public enum Timing {
        /// Gesture changed
        case changed
        /// Gesture ended
        case ended
        /// Periodic update while gesture is active
        case heartbeat
    }

    /// Drag gesture value from SwiftUI
    public let dragGestureValue: DragGesture.Value
    /// Geometry proxy for view bounds
    public let geometryProxy: GeometryProxy
    /// Timing of this state update
    public var timing: Timing
    /// Timestamp of this state (using custom Date because DragGesture.Value.time has bugs)
    public var time: Date

    /// Check if gesture location is within view bounds
    public func isInView() -> Bool {
        return 0 <= dragGestureValue.location.x && dragGestureValue.location.x <= geometryProxy.size.width
            && 0 <= dragGestureValue.location.y && dragGestureValue.location.y <= geometryProxy.size.height
    }
}

/// Constants for gesture detection
private struct Const {
    /// Minimum velocity for swipe gesture detection
    static let swipeMinimumVelocity: CGFloat = 300
}
