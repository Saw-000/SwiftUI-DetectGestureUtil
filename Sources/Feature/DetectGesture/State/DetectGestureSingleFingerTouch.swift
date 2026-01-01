import Foundation
import MyModuleCore
import SwiftUI

/// Collection of events for a single finger
public struct DetectGestureSingleFingerTouch {
    /// Unique identifier for the finger event
    public let eventID: SpatialEventCollection.Event.ID
    /// Array of values for this finger's touch
    public let values: [DetectGestureSingleFingerValue]

    public init(eventID: SpatialEventCollection.Event.ID, values: [DetectGestureSingleFingerValue]) {
        self.eventID = eventID
        self.values = values.sortedByTimestamp
    }
}

// MARK: - Utility

public extension DetectGestureSingleFingerTouch {
    /// Tap occurrence period
    var period: TouchPeriod? {
        guard
            let first = values.first,
            let last = values.last
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
    func isOverlapped(with another: DetectGestureSingleFingerTouch) -> Bool {
        guard
            let period,
            let anotherPeriod = another.period
        else {
            return false
        }
        return max(period.start, anotherPeriod.start) < min(period.end, anotherPeriod.end)
    }

    /// Check if tap periods overlap with any of the given taps
    func isOverlapped(with anothers: [DetectGestureSingleFingerTouch], removeSelf: Bool = true) -> Bool {
        let anothers = removeSelf ? anothers.filter { $0.eventID != eventID } : anothers
        return anothers.contains(where: { $0.isOverlapped(with: self) })
    }

    /// Distance moved from the initial tap location
    var diff: CGPoint {
        guard
            let firstLocation = values.first?.fingerEvent.location,
            let lastLocation = values.last?.fingerEvent.location
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
            let firstLocation = values.first?.fingerEvent.location,
            let lastLocation = values.last?.fingerEvent.location
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
            values.count >= 2,
            let lastValue = values.last
        else {
            return .zero
        }

        let secondLastValue = values[values.count - 2]

        let timeInterval = lastValue.time.timeIntervalSince(secondLastValue.time)
        guard timeInterval > 0 else {
            return .zero
        }

        let distance = CGSize(
            width: lastValue.fingerEvent.location.x - secondLastValue.fingerEvent.location.x,
            height: lastValue.fingerEvent.location.y - secondLastValue.fingerEvent.location.y
        )

        let velocity = CGSize(
            width: distance.width / timeInterval,
            height: distance.height / timeInterval
        )

        return velocity
    }
}
