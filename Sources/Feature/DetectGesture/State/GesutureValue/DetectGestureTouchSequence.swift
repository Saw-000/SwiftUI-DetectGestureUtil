import MyModuleCore
import SwiftUI

public struct DetectGestureTouchSequence: Identifiable {
    /// Value containing gesture state information (like DragGesture.Value)
    public struct Value: Identifiable {
        /// Timing of gesture state update
        public enum Timing {
            /// Gesture changed
            case changed
            /// Gesture ended
            case ended
            /// Periodic update while gesture is active
            case heartbeat
        }

        /// id
        public var id: UUID = .init()

        /// Spatial event collection from SwiftUI
        public let spatialEventCollection: SpatialEventCollection
        /// Geometry proxy for view bounds
        public let geometryProxy: GeometryProxy
        /// Timing of this state update
        public var timing: Timing
        /// Timestamp of this state
        public var time: Date
    }

    /// id
    public let id: UUID = .init()

    public let values: [Value]
}

// MARK: - DetectGestureTouchSequence.Value Utility

public extension DetectGestureTouchSequence.Value {
    /// Number of fingers currently touching
    var fingerCount: Int {
        spatialEventCollection.count
    }

    /// Locations of all fingers
    var locations: [CGPoint] {
        spatialEventCollection.map(\.location)
    }

    /// Check if all fingers is within view bounds
    func isAllFingersInView() -> Bool {
        !asFingerEvents().contains(where: {
            !$0.isInView()
        })
    }
}

// MARK: - [DetectGestureTouchSequence.Value] Utility

public extension [DetectGestureTouchSequence.Value] {
    /// Filter values to only include original gesture events (changed and ended)
    var filterdWithRawTimings: [DetectGestureTouchSequence.Value] {
        let rawGestureTimings: [DetectGestureTouchSequence.Value.Timing] = [.changed, .ended]
        return self.filter { value in
            rawGestureTimings.contains(value.timing)
        }
    }
}
