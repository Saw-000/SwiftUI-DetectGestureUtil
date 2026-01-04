import Foundation
import MyModuleCore
import SwiftUI

/// DetectGestureValue formatted to focus on a single finger event
public struct DetectGestureSingleFingerValue {
    /// event of one finger.
    public let fingerEvent: SpatialEventCollection.Event
    /// attachment information (DetectGestureValue)
    public let relatedGestureValue: DetectGestureValue
}

// MARK: - Utility

public extension DetectGestureSingleFingerValue {
    /// Check if a location of a finger is within view bounds
    func isInView() -> Bool {
        let location = fingerEvent.location
        return location.x >= 0 && location.x <= relatedGestureValue.geometryProxy.size.width
            && location.y >= 0 && location.y <= relatedGestureValue.geometryProxy.size.height
    }

    /// Timestamp of this finger event
    var time: Date {
        relatedGestureValue.time
    }
}

public extension [DetectGestureSingleFingerValue] {
    /// Filter values to only include original gesture events (changed and ended)
    func withRawNotifiedGesture() -> [DetectGestureSingleFingerValue] {
        let rawGestureTimings: [DetectGestureValue.Timing] = [.changed, .ended]
        return self.filter { value in
            rawGestureTimings.contains(value.relatedGestureValue.timing)
        }
    }

    /// Values sorted by timestamp in ascending order
    var sortedByTimestamp: [DetectGestureSingleFingerValue] {
        sorted(by: {
            $0.time < $1.time
        })
    }
}
