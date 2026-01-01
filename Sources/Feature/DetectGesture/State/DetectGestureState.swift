import SwiftUI
import MyModuleCore

/// State of DetectGesture
public struct DetectGestureState<GestureDetection: Equatable> {
    /// History of gesture information
    public var gestureValues: [DetectGestureValue] = []

    /// Detected gesture
    public var detection: GestureDetection? = nil

    /// Whether handling after gesture detection is finished
    public var handleFinished: Bool = false

    public init() {}

    /// Whether the specified default gesture has already been detected
    public func detected(_ wantToDetectGesture: DefaultDetectGesture, gestureValues: [DetectGestureValue]? = nil) -> Bool {
        let gestureValues = gestureValues ?? self.gestureValues
        
        switch wantToDetectGesture {
        case let .tap(allowMultiTap):
            return gestureValues.anySingleFingerTouchContains { singleFingerTouch, touchSequence in
                guard
                    let lastValue = singleFingerTouch.values.last,
                    lastValue.fingerEvent.phase == .ended, // Tap ended
                    lastValue.isInView(), // Tap is within view
                    allowMultiTap || !singleFingerTouch.isOverlapped(with: touchSequence.touches) // Not overlapped with other finger taps (optional)
                else {
                    return false
                }
                return true
            }

        case let .longTap(minimumMilliSeconds, allowMultiTap):
            return gestureValues.anySingleFingerTouchContains { singleFingerTouch, touchSequence in
                guard
                    let duration = singleFingerTouch.duration,
                    allowMultiTap || !singleFingerTouch.isOverlapped(with: touchSequence.touches) // Not overlapped with other finger taps (optional)
                else {
                    return false
                }
                
                if duration * 1000 >= minimumMilliSeconds {
                    return true
                }

                return false
            }

        case let .drag(minimumDistance, allowMultiTap):
            return gestureValues.anySingleFingerTouchContains { singleFingerTouch, touchSequence in
                guard
                    allowMultiTap || !singleFingerTouch.isOverlapped(with: touchSequence.touches)
                else {
                    return false
                }
                
                return singleFingerTouch.translation.distance >= minimumDistance
            }

        case let .slide(direction, minimumDistance, allowMultiTap):
            return gestureValues.anySingleFingerTouchContains { singleFingerTouch, touchSequence in
                guard
                    allowMultiTap || !singleFingerTouch.isOverlapped(with: touchSequence.touches)
                else {
                    return false
                }
                
                let diff = singleFingerTouch.diff

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
            }

        case let .swipe(direction: direction, allowMultiTap):
            return gestureValues.anySingleFingerTouchContains { singleFingerTouch, touchSequence in
                // Finger is released
                guard singleFingerTouch.values.last?.fingerEvent.phase == .ended else {
                    return false
                }
                
                guard
                    allowMultiTap || !singleFingerTouch.isOverlapped(with: touchSequence.touches)
                else {
                    return false
                }
                
                let velocity = singleFingerTouch.velocity

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
            }

        case let .sequentialTap(count, maximumTapIntervalMilliseconds):
            guard count > 0 else {
                return false
            }
            
            let tapEndValues = gestureValues.asTapSequences()
                .flatMap { touchSequence in
                    touchSequence.touches.filter { singleFingerTouch in
                        guard
                            singleFingerTouch.values.last?.fingerEvent.phase == .ended,
                            singleFingerTouch.values.last?.isInView() == true,
                            !singleFingerTouch.isOverlapped(with: touchSequence.touches)
                        else {
                            return false
                        }
                        
                        return true
                    }
                }
                .map {
                    $0.values.last!
                }

            guard tapEndValues.count >= count else {
                return false
            }

            var sequentialTapCount = 1
            var previousTapEndValue: DetectGestureSingleFingerValue? = nil

            // Count sequential tap count
            for tapEndValue in tapEndValues {
                if let pTapEndValue = previousTapEndValue {
                    let isSequentialTap = tapEndValue.attachmentInfo.time.timeIntervalSince(pTapEndValue.attachmentInfo.time) <= maximumTapIntervalMilliseconds

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

/// Constants for gesture detection
private struct Const {
    /// Minimum velocity for swipe gesture detection
    static let swipeMinimumVelocity: CGFloat = 300
}

// MARK: - Utility

public extension DetectGestureState {
    /// Gesture values converted to tap sequences
    var gestureValuesAsTapSequences: [DetectGestureTapSequence] {
        gestureValues.asTapSequences()
    }

    /// Last tap sequence
    var lastTapSequence: DetectGestureTapSequence? {
        gestureValuesAsTapSequences.last
    }

    /// Whether gesture has already been detected
    var gestureDetected: Bool {
        detection != nil
    }

    /// Last Detected Gestrue Value
    var lastGestureValue: DetectGestureValue? {
        gestureValues.last
    }
    
    /// Process taps for each individual finger
    func processPerSingleFingerTouch(_ completion: (DetectGestureSingleFingerTouch, DetectGestureTapSequence) -> Void) {
        gestureValues.processPerSingleFingerTouch(completion)
    }
}
