import MyModuleCore
import SwiftUI

/// State of DetectGesture
public struct DetectGestureState<GestureDetection: Equatable> {
    /// History of gesture information
    public var gestureValues: [DetectGestureValue] = []

    /// Detected gesture
    public var detection: GestureDetection?

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

        case let .pinch(minimumDistance):
            // Detect pinch gesture using pinchState
            return pinchState.contains { pinch in
                guard let first = pinch.values.first else {
                    return false
                }
                let initialDistance = first.distance

                // Check if any point in the pinch exceeds the minimum distance change
                return pinch.values.contains { value in
                    let distanceChange = abs(value.distance - initialDistance)
                    return distanceChange >= minimumDistance
                }
            }
        }
    }
}

/// Constants for gesture detection
private enum Const {
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

    /// ピンチに関する情報
    var pinchState: [DetectGesturePinch] {
        var pinches: [DetectGesturePinch] = []
        var currentPinchValues: [DetectGesturePinchValue] = []
        var currentEventIDs: Set<SpatialEventCollection.Event.ID>? = nil

        for gestureValue in gestureValues {
            // Check if there are exactly 2 fingers
            if gestureValue.fingerCount == 2 {
                let events = Array(gestureValue.spatialEventCollection)
                var eventIDs: Set<SpatialEventCollection.Event.ID> {
                    Set(events.map { $0.id })
                }

                // Check if this is the same pinch event (same Event.ID pair)
                if let current = currentEventIDs, current == eventIDs {
                    // Same pinch event, add to current
                    let pinchValue = DetectGesturePinchValue(events: events)
                    currentPinchValues.append(pinchValue)
                } else {
                    // Different pinch event or new pinch started
                    // Save previous pinch if exists (mark as ended)
                    if !currentPinchValues.isEmpty {
                        pinches.append(DetectGesturePinch(values: currentPinchValues, isEnded: true))
                    }

                    // Start new pinch
                    currentPinchValues = [DetectGesturePinchValue(events: events)]
                    currentEventIDs = eventIDs
                }
            } else {
                // Not 2 fingers, end current pinch if exists
                if !currentPinchValues.isEmpty {
                    pinches.append(DetectGesturePinch(values: currentPinchValues, isEnded: true))
                    currentPinchValues = []
                    currentEventIDs = nil
                }
            }
        }

        // Don't forget to add the last pinch if exists
        // Determine if the last pinch is ended
        if !currentPinchValues.isEmpty {
            let isEnded = isPinchEnded(
                eventIDs: currentEventIDs,
                lastGestureValue: gestureValues.last
            )
            pinches.append(DetectGesturePinch(values: currentPinchValues, isEnded: isEnded))
        }

        return pinches
    }

    /// ピンチが終了しているかを判定
    private func isPinchEnded(
        eventIDs: Set<SpatialEventCollection.Event.ID>?,
        lastGestureValue: DetectGestureValue?
    ) -> Bool {
        guard let lastGestureValue else {
            return true
        }

        // gestureValues.last.timing == .ended なら全部終わり
        if lastGestureValue.timing == .ended {
            return true
        }

        // gestureValues.last の指の個数が2でない
        if lastGestureValue.fingerCount != 2 {
            return true
        }

        // SpatialEventCollection.Event.ID が異なる
        guard let eventIDs else {
            return true
        }
        let lastEventIDs = Set(lastGestureValue.spatialEventCollection.map { $0.id })
        if eventIDs != lastEventIDs {
            return true
        }

        // まだ継続中
        return false
    }
}
