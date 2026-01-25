import Foundation
import MyModuleCore
import SwiftUI

/// Collection of values from tap start until all fingers are released
public struct DetectGestureFingerSequence {
    /// Collection of events for a single finger
    public struct Finger {
        /// DetectGestureTouchSequence.Value formatted to focus on a single finger event
        public struct Event {
            /// event of one finger.
            public let spatialEventCollectionEvent: SpatialEventCollection.Event
            /// attachment information (DetectGestureTouchSequence.Value)
            public let relatedGestureValue: DetectGestureTouchSequence.Value
        }

        /// Unique identifier for the finger event
        public let spatialEventCollectionEventID: SpatialEventCollection.Event.ID
        /// Array of values for this finger's touch
        public let events: [Event]

        public init(eventID: SpatialEventCollection.Event.ID, values: [Event]) {
            self.spatialEventCollectionEventID = eventID
            self.events = values.sortedByTimestamp
        }
    }

    /// Events per finger
    public let fingers: [Finger]
}

// MARK: - DetectGestureFingerSequence.Finger.Event Utility

public extension DetectGestureFingerSequence.Finger.Event {
    /// Check if a location of a finger is within view bounds
    func isInView() -> Bool {
        let location = spatialEventCollectionEvent.location
        return location.x >= 0 && location.x <= relatedGestureValue.geometryProxy.size.width
            && location.y >= 0 && location.y <= relatedGestureValue.geometryProxy.size.height
    }

    /// Timestamp of this finger event
    var time: Date {
        relatedGestureValue.time
    }
}

public extension [DetectGestureFingerSequence.Finger.Event] {
    /// Filter values to only include original gesture events (changed and ended)
    func withRawNotifiedGesture() -> [DetectGestureFingerSequence.Finger.Event] {
        let rawGestureTimings: [DetectGestureTouchSequence.Value.Timing] = [.changed, .ended]
        return self.filter { value in
            rawGestureTimings.contains(value.relatedGestureValue.timing)
        }
    }

    /// Values sorted by timestamp in ascending order
    var sortedByTimestamp: [DetectGestureFingerSequence.Finger.Event] {
        sorted(by: {
            $0.time < $1.time
        })
    }
}

// MARK: - DetectGestureFingerSequence.Finger Utility

public extension DetectGestureFingerSequence.Finger {
    /// Tap occurrence period
    var period: TouchPeriod? {
        guard
            let first = events.first,
            let last = events.last
        else {
            return nil
        }

        return TouchPeriod(start: first.time, end: last.time)
    }

    /// Tap duration (in seconds)
    var duration: TimeInterval? {
        guard let period else {
            return nil
        }

        return period.end.timeIntervalSince(period.start)
    }

    /// Check if tap periods overlap
    func isOverlapped(with another: DetectGestureFingerSequence.Finger) -> Bool {
        guard
            let period,
            let anotherPeriod = another.period
        else {
            return false
        }
        return max(period.start, anotherPeriod.start) < min(period.end, anotherPeriod.end)
    }

    /// Check if tap periods overlap with any of the given taps
    func isOverlapped(with anothers: [DetectGestureFingerSequence.Finger], removeSelf: Bool = true) -> Bool {
        let anothers = removeSelf ? anothers.filter { $0.spatialEventCollectionEventID != spatialEventCollectionEventID } : anothers
        return anothers.contains(where: { $0.isOverlapped(with: self) })
    }

    /// Distance moved from the initial tap location
    var diff: CGPoint {
        guard
            let firstLocation = events.first?.spatialEventCollectionEvent.location,
            let lastLocation = events.last?.spatialEventCollectionEvent.location
        else {
            return .zero
        }

        return CGPoint(
            x: lastLocation.x - firstLocation.x,
            y: lastLocation.y - firstLocation.y
        )
    }

    /// Translation from start location
    var translation: CGSize {
        guard
            let firstLocation = events.first?.spatialEventCollectionEvent.location,
            let lastLocation = events.last?.spatialEventCollectionEvent.location
        else {
            return .zero
        }

        return CGSize(
            width: lastLocation.x - firstLocation.x,
            height: lastLocation.y - firstLocation.y
        )
    }

    /// Velocity of the gesture movement
    var velocity: CGSize {
        guard
            events.count >= 2,
            let lastValue = events.last
        else {
            return .zero
        }

        let secondLastValue = events[events.count - 2]

        let timeInterval = lastValue.time.timeIntervalSince(secondLastValue.time)
        guard timeInterval > 0 else {
            return .zero
        }

        let distance = CGSize(
            width: lastValue.spatialEventCollectionEvent.location.x - secondLastValue.spatialEventCollectionEvent.location.x,
            height: lastValue.spatialEventCollectionEvent.location.y - secondLastValue.spatialEventCollectionEvent.location.y
        )

        let velocity = CGSize(
            width: distance.width / timeInterval,
            height: distance.height / timeInterval
        )

        return velocity
    }
}

// MARK: - DetectGestureFingerSequence Utility

public extension DetectGestureFingerSequence {
    /// Check if any single finger tap satisfies the condition
    func anyFingerContains(_ completion: @escaping (Finger, DetectGestureFingerSequence) -> Bool) -> Bool {
        fingers.contains(where: { singleFingerValues in
            completion(singleFingerValues, self)
        })
    }
}

public extension [DetectGestureFingerSequence] {
    /// Check if any single finger tap satisfies the condition
    func anyFingerContains(_ completion: @escaping (DetectGestureFingerSequence.Finger, DetectGestureFingerSequence) -> Bool) -> Bool {
        self.contains(where: {
            $0.anyFingerContains(completion)
        })
    }
}
