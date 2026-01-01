import Foundation
import MyModuleCore
import SwiftUI

/// DetectGestureValue formatted to focus on a single finger event
public struct DetectGestureSingleFingerValue {
    /// event of one finger.
    public let fingerEvent: SpatialEventCollection.Event
    /// attachment information (DetectGestureValue)
    public let attachmentInfo: DetectGestureValue
}

// MARK: - Utility

public extension DetectGestureSingleFingerValue {
    /// Check if a location of a finger is within view bounds
    func isInView() -> Bool {
        let location = fingerEvent.location
        return location.x >= 0 && location.x <= attachmentInfo.geometryProxy.size.width
            && location.y >= 0 && location.y <= attachmentInfo.geometryProxy.size.height
    }

    /// Timestamp of this finger event
    var time: Date {
        attachmentInfo.time
    }
}

public extension [DetectGestureSingleFingerValue] {
    /// Filter values to only include original gesture events (changed and ended)
    func withRawNotifiedGesture() -> [DetectGestureSingleFingerValue] {
        let rawDragTimings: [DetectGestureValue.Timing] = [.changed, .ended]
        return self.filter { value in
            rawDragTimings.contains(value.attachmentInfo.timing)
        }
    }

    /// Values sorted by timestamp in ascending order
    var sortedByTimestamp: [DetectGestureSingleFingerValue] {
        sorted(by: {
            $0.time < $1.time
        })
    }
}
