import MyModuleCore
import SwiftUI

/// Constants for gesture detection
private enum Const {
    /// Default duration threshold for long tap detection in milliseconds
    static let longTapDefaultMilliSecondsForDetection: TimeInterval = 1000
}

/// State of DetectGesture
public struct DetectGestureState<GestureDetection: Equatable> {
    /// History of gesture information
    public var gestureValues: [DetectGestureTouchSequence.Value] = []

    /// Detected gesture
    public var detection: GestureDetection?

    /// Whether handling after gesture detection is finished
    public var handleFinished: Bool = false

    /// Initialize gesture state
    public init() {}
}

// MARK: - Common Utility

public extension DetectGestureState {
    /// Whether gesture has already been detected
    var gestureDetected: Bool {
        detection != nil
    }

    /// Gesture values converted to tap sequences
    var asFingerSequences: [DetectGestureFingerSequence] {
        gestureValues.asFingerSequences()
    }

    /// Last tap sequence
    var lastFingerSequence: DetectGestureFingerSequence? {
        asFingerSequences.last
    }

    /// Last Detected Gesture Value
    var lastGestureValue: DetectGestureTouchSequence.Value? {
        gestureValues.last
    }

    /// Currently tapping fingers
    var tappingFingers: [DetectGestureFingerSequence.Finger] {
        guard
            let tapSequence = lastFingerSequence,
            let lastGestureValue = lastGestureValue
        else {
            return [] // Should always exist, but returning empty array as fallback
        }

        let lastFingerTaps = tapSequence.fingers.filter {
            $0.events.last?.relatedGestureValue.id == lastGestureValue.id
        }

        return lastFingerTaps
    }

    /// Process taps for each individual finger
    func processPerFinger(_ completion: (DetectGestureFingerSequence.Finger, DetectGestureFingerSequence) -> Void) {
        gestureValues.processPerFinger(completion)
    }
}

// MARK: - Default Gesture Detection

public extension DetectGestureState {
    /// Whether the specified default gesture has already been detected
    func detected(
        _ wantToDetectGesture: DefaultDetectGesture,
        gestureValues: [DetectGestureTouchSequence.Value]? = nil
    ) -> Bool {
        let gestureValues = gestureValues ?? self.gestureValues
        let fingerSequences = gestureValues.asFingerSequences()

        return detected(
            wantToDetectGesture,
            fingerSequences: fingerSequences
        )
    }

    /// Whether the specified default gesture has already been detected
    func detected(
        _ wantToDetectGesture: DefaultDetectGesture,
        fingerSequences: [DetectGestureFingerSequence]
    ) -> Bool {
        switch wantToDetectGesture {
        case let .tap(allowMultiTap, checkOnlyLastTap):
            return detectTap(
                fingerSequences: fingerSequences,
                allowMultiTap: allowMultiTap,
                checkOnlyLastTap: checkOnlyLastTap
            )

        case let .longTap(milliSecondsForDetection, allowMultiTap, checkOnlyLastTap):
            return detectLongTap(
                fingerSequences: fingerSequences,
                milliSecondsForDetection: milliSecondsForDetection ?? Const.longTapDefaultMilliSecondsForDetection,
                allowMultiTap: allowMultiTap,
                checkOnlyLastTap: checkOnlyLastTap
            )

        case let .drag(minimumDistance, allowMultiTap, checkOnlyLastTap):
            return detectDrag(
                fingerSequences: fingerSequences,
                minimumDistance: minimumDistance,
                allowMultiTap: allowMultiTap,
                checkOnlyLastTap: checkOnlyLastTap
            )

        case let .slide(direction, minimumDistance, allowMultiTap, checkOnlyLastTap):
            return detectSlide(
                fingerSequences: fingerSequences,
                direction: direction,
                minimumDistance: minimumDistance,
                allowMultiTap: allowMultiTap,
                checkOnlyLastTap: checkOnlyLastTap
            )

        case let .swipe(direction: direction, minimumVelocity, allowMultiTap, checkOnlyLastTap):
            return detectSwipe(
                fingerSequences: fingerSequences,
                minimumVelocity: minimumVelocity,
                direction: direction,
                allowMultiTap: allowMultiTap,
                checkOnlyLastTap: checkOnlyLastTap
            )

        case let .sequentialTap(count, maximumTapIntervalMilliseconds, checkOnlyLastTap):
            return detectSequentialTap(
                fingerSequences: fingerSequences,
                count: count,
                maximumTapIntervalMilliseconds: maximumTapIntervalMilliseconds,
                checkOnlyLastTap: checkOnlyLastTap
            )

        case let .pinch(minimumDistance, checkOnlyLastTap):
            return detectPinch(
                fingerSequences: fingerSequences,
                minimumDistance: minimumDistance,
                checkOnlyLastTap: checkOnlyLastTap
            )
        }
    }

    /// Detect Tap Gesture
    private func detectTap(
        fingerSequences: [DetectGestureFingerSequence],
        allowMultiTap: Bool,
        checkOnlyLastTap: Bool
    ) -> Bool {
        fingerSequences.anyFingerContains { singleFingerTouch, tapSequence in
            guard
                let lastValue = singleFingerTouch.events.last,
                !checkOnlyLastTap || lastValue.relatedGestureValue.id == tapSequence.asDetectGestureValues.last?.id, // Last tap
                lastValue.spatialEventCollectionEvent.phase == .ended, // Tap ended
                lastValue.isInView(), // Tap is within view
                allowMultiTap || !singleFingerTouch.isOverlapped(with: tapSequence.fingers) // Not overlapped with other finger taps (optional)
            else {
                return false
            }
            return true
        }
    }

    /// Detect Long Tap Gesture
    private func detectLongTap(
        fingerSequences: [DetectGestureFingerSequence],
        milliSecondsForDetection: TimeInterval,
        allowMultiTap: Bool,
        checkOnlyLastTap: Bool
    ) -> Bool {
        return fingerSequences.anyFingerContains { singleFingerTouch, tapSequence in
            guard
                let lastValue = singleFingerTouch.events.last, !checkOnlyLastTap || lastValue.relatedGestureValue.id == tapSequence.asDetectGestureValues.last?.id, // last tap
                let duration = singleFingerTouch.duration,
                allowMultiTap || !singleFingerTouch.isOverlapped(with: tapSequence.fingers) // Not overlapped with other finger taps (optional)
            else {
                return false
            }

            if duration * 1000 >= milliSecondsForDetection {
                return true
            }

            return false
        }
    }

    /// Detect Drag Gesture
    private func detectDrag(
        fingerSequences: [DetectGestureFingerSequence],
        minimumDistance: CGFloat,
        allowMultiTap: Bool,
        checkOnlyLastTap: Bool
    ) -> Bool {
        fingerSequences.anyFingerContains { singleFingerTouch, tapSequence in
            guard
                allowMultiTap || !singleFingerTouch.isOverlapped(with: tapSequence.fingers),
                let lastValue = singleFingerTouch.events.last, !checkOnlyLastTap || lastValue.relatedGestureValue.id == tapSequence.asDetectGestureValues.last?.id // last tap
            else {
                return false
            }

            return singleFingerTouch.translation.distance >= minimumDistance
        }
    }

    /// Detect Slide Gesture
    private func detectSlide(
        fingerSequences: [DetectGestureFingerSequence],
        direction: DefaultDetectGestureDirection,
        minimumDistance: CGFloat,
        allowMultiTap: Bool,
        checkOnlyLastTap: Bool
    ) -> Bool {
        fingerSequences.anyFingerContains { singleFingerTouch, tapSequence in
            guard
                allowMultiTap || !singleFingerTouch.isOverlapped(with: tapSequence.fingers),
                let lastValue = singleFingerTouch.events.last, !checkOnlyLastTap || lastValue.relatedGestureValue.id == tapSequence.asDetectGestureValues.last?.id // last tap
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
    }

    /// Detect Swipe Gesture
    private func detectSwipe(
        fingerSequences: [DetectGestureFingerSequence],
        minimumVelocity: CGFloat,
        direction: DefaultDetectGestureDirection,
        allowMultiTap: Bool,
        checkOnlyLastTap: Bool
    ) -> Bool {
        fingerSequences.anyFingerContains { singleFingerTouch, tapSequence in
            // Finger is released
            guard
                singleFingerTouch.events.last?.spatialEventCollectionEvent.phase == .ended,
                let lastValue = singleFingerTouch.events.last, !checkOnlyLastTap || lastValue.relatedGestureValue.id == tapSequence.asDetectGestureValues.last?.id // last tap
            else {
                return false
            }

            guard
                allowMultiTap || !singleFingerTouch.isOverlapped(with: tapSequence.fingers)
            else {
                return false
            }

            let velocity = singleFingerTouch.velocity

            return switch direction {
            case .up:
                -velocity.height >= minimumVelocity
            case .down:
                velocity.height >= minimumVelocity
            case .left:
                -velocity.width >= minimumVelocity
            case .right:
                velocity.width >= minimumVelocity
            }
        }
    }

    /// Detect Sequential Tap Gesture
    private func detectSequentialTap(
        fingerSequences: [DetectGestureFingerSequence],
        count: Int,
        maximumTapIntervalMilliseconds: TimeInterval,
        checkOnlyLastTap: Bool
    ) -> Bool {
        guard count > 0 else {
            return false
        }

        let tapEndValues = fingerSequences
            .flatMap { touchSequence in
                touchSequence.fingers.filter { singleFingerTouch in
                    guard
                        singleFingerTouch.events.last?.spatialEventCollectionEvent.phase == .ended,
                        singleFingerTouch.events.last?.isInView() == true,
                        !singleFingerTouch.isOverlapped(with: touchSequence.fingers)
                    else {
                        return false
                    }

                    return true
                }
            }
            .map {
                $0.events.last!
            }

        guard tapEndValues.count >= count else {
            return false
        }

        var sequentialTapCount = 1
        var previousTapEndValue: DetectGestureFingerSequence.Finger.Event? = nil

        // Count sequential tap count
        for tapEndValue in tapEndValues {
            if let pTapEndValue = previousTapEndValue {
                let isSequentialTap = tapEndValue.relatedGestureValue.time.timeIntervalSince(pTapEndValue.relatedGestureValue.time) <= maximumTapIntervalMilliseconds

                if isSequentialTap {
                    sequentialTapCount += 1
                } else {
                    // Reset if tap interval exceeds specified seconds
                    sequentialTapCount = 1
                }

                previousTapEndValue = tapEndValue

                if checkOnlyLastTap {
                    let thisTapEndGestureValue = tapEndValue.relatedGestureValue
                    let lastGestureValue = fingerSequences.last?.asDetectGestureValues.last
                    let isLastTap = thisTapEndGestureValue.id == lastGestureValue?.id

                    guard isLastTap else { continue }
                }

                // Detect if sequential tap count exceeds specified count
                if sequentialTapCount >= count {
                    return true
                }
            } else {
                previousTapEndValue = tapEndValue
                continue
            }
        }

        // Sequential tap count never exceeded specified count
        return false
    }

    /// Detect Pinch Gesture
    private func detectPinch(
        fingerSequences: [DetectGestureFingerSequence],
        minimumDistance: CGFloat,
        checkOnlyLastTap: Bool
    ) -> Bool {
        detectPinch(gestureValues: fingerSequences.asDetectGestureValues, minimumDistance: minimumDistance, checkOnlyLastTap: checkOnlyLastTap)
    }

    /// Detect Pinch Gesture
    private func detectPinch(
        gestureValues: [DetectGestureTouchSequence.Value],
        minimumDistance: CGFloat,
        checkOnlyLastTap: Bool
    ) -> Bool {
        // Calculate pinch state from gesture values
        let pinches = pinchValues(from: gestureValues)

        // Detect pinch gesture using pinchValues
        return pinches.contains { pinch in
            if checkOnlyLastTap {
                guard let lastPinchFingerValue = pinch.values.last?.values.first else {
                    return false
                }
                let isLastTap = lastPinchFingerValue.relatedGestureValue.id == gestureValues.last?.id

                guard isLastTap else {
                    return false
                }
            }

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

    /// Extract pinch gesture information from gesture values
    var pinchValues: [DetectGesturePinch] {
        pinchValues(from: asFingerSequences.asDetectGestureValues)
    }

    /// Extract pinch gesture information from tap sequences
    func pinchValues(from fingerSequences: [DetectGestureFingerSequence]) -> [DetectGesturePinch] {
        pinchValues(from: fingerSequences.asDetectGestureValues)
    }

    /// Calculate pinch state from gesture values
    private func pinchValues(from gestureValues: [DetectGestureTouchSequence.Value]) -> [DetectGesturePinch] {
        var pinches: [DetectGesturePinch] = []
        var currentPinchValues: [DetectGesturePinchValue] = []
        var currentEventIDs: Set<SpatialEventCollection.Event.ID>? = nil

        for gestureValue in gestureValues {
            // Check if there are exactly 2 fingers
            if gestureValue.fingerCount == 2 {
                let fingerValues = gestureValue.asFingerEvents()
                var eventIDs: Set<SpatialEventCollection.Event.ID> {
                    Set(fingerValues.map { $0.spatialEventCollectionEvent.id })
                }

                // Check if this is the same pinch event (same Event.ID pair)
                if let current = currentEventIDs, current == eventIDs {
                    // Same pinch event, add to current
                    let pinchValue = DetectGesturePinchValue(values: fingerValues)
                    currentPinchValues.append(pinchValue)
                } else {
                    // Different pinch event or new pinch started
                    // Save previous pinch if exists (mark as ended)
                    if !currentPinchValues.isEmpty {
                        pinches.append(DetectGesturePinch(values: currentPinchValues, isEnded: true))
                    }

                    // Start new pinch
                    currentPinchValues = [DetectGesturePinchValue(values: fingerValues)]
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

    /// Determine if the pinch gesture has ended
    private func isPinchEnded(
        eventIDs: Set<SpatialEventCollection.Event.ID>?,
        lastGestureValue: DetectGestureTouchSequence.Value?
    ) -> Bool {
        guard let lastGestureValue else {
            return true
        }

        // If gestureValues.last.timing == .ended, all gestures are finished
        if lastGestureValue.timing == .ended {
            return true
        }

        // If the number of fingers in gestureValues.last is not 2
        if lastGestureValue.fingerCount != 2 {
            return true
        }

        // If SpatialEventCollection.Event.ID is different
        guard let eventIDs else {
            return true
        }
        let lastEventIDs = Set(lastGestureValue.spatialEventCollection.map { $0.id })
        if eventIDs != lastEventIDs {
            return true
        }

        // Still continuing
        return false
    }
}
