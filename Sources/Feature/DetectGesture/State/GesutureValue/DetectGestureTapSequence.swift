import Foundation

/// Collection of values from tap start until all fingers are released
public struct DetectGestureTapSequence {
    /// Events per finger
    public let touches: [DetectGestureSingleFingerTouch]
}

// MARK: - Utility

public extension DetectGestureTapSequence {
    /// Check if any single finger tap satisfies the condition
    func anySingleFingerTouchContains(_ completion: @escaping (DetectGestureSingleFingerTouch, DetectGestureTapSequence) -> Bool) -> Bool {
        touches.contains(where: { singleFingerValues in
            completion(singleFingerValues, self)
        })
    }

    /// convert to [DetectGestureValue]
    var asDetectGestureValues: [DetectGestureValue] {
        touches.flatMap(\.values)
            .map(\.relatedGestureValue)
            .distinctBy { $0.id }
            .sorted { $0.time < $1.time }
    }
}

public extension [DetectGestureTapSequence] {
    /// Check if any single finger tap satisfies the condition
    func anySingleFingerTouchContains(_ completion: @escaping (DetectGestureSingleFingerTouch, DetectGestureTapSequence) -> Bool) -> Bool {
        self.contains(where: {
            $0.anySingleFingerTouchContains(completion)
        })
    }

    /// convert to [DetectGestureValue]
    var asDetectGestureValues: [DetectGestureValue] {
        self.flatMap { $0.asDetectGestureValues }
    }
}
