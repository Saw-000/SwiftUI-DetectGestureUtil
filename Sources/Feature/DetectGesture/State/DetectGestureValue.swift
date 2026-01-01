//
//  DetectGestureValue.swift
//  SwiftUI-DetectGestureUtil
//
//  Created by IeSo on 2026/01/01.
//


import SwiftUI
import MyModuleCore

/// Value containing gesture state information (like DragGesture.Value)
public struct DetectGestureValue {
    /// Timing of gesture state update
    public enum Timing {
        /// Gesture changed
        case changed
        /// Gesture ended
        case ended
        /// Periodic update while gesture is active
        case heartbeat
    }

    /// Spatial event collection from SwiftUI
    public let spatialEventCollection: SpatialEventCollection
    /// Geometry proxy for view bounds
    public let geometryProxy: GeometryProxy
    /// Timing of this state update
    public var timing: Timing
    /// Timestamp of this state
    public var time: Date
}

// MARK: - Utility

public extension DetectGestureValue {
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
        !asSingleFingerValues().contains(where: {
            !$0.isInView()
        })
    }

    /// Convert to DetectGestureSingleFingerValue format
    func asSingleFingerValues() -> [DetectGestureSingleFingerValue] {
        self.spatialEventCollection.map { event in
            DetectGestureSingleFingerValue(
                fingerEvent: event,
                attachmentInfo: self
            )
        }
    }
}

public extension [DetectGestureValue] {
    /// Split into sequences from tap start until all fingers are released
    private func splittedInTouchSequences() -> [[DetectGestureValue]] {
        var buffer = [[DetectGestureValue]]()
        
        var nextStartIndex = 0
        for i in 0...self.count-1 {
            let value = self[i]
            if value.timing == .ended {
                buffer.append(Array(self[nextStartIndex...i]))
                nextStartIndex = i + 1
            } else if i == self.count-1 {
                buffer.append(Array(self[nextStartIndex...self.count-1]))
            }
        }
        
        return buffer
    }

    /// Split into sequences from tap start until all fingers are released
    func asTapSequences() -> [DetectGestureTapSequence] {
        let formed = self.splittedInTouchSequences().map {
            let singleFingers = $0.flatMap {
                $0.asSingleFingerValues()
            }
            .sorted(by: {
                $0.time < $1.time
            })
            
            return Dictionary(
                grouping: singleFingers,
                by: { $0.fingerEvent.id }
            )
            .map {
                DetectGestureSingleFingerTouch(
                    eventID: $0.key,
                    values: $0.value
                )
            }
            .sorted(by: {
                $0.values.first!.time < $1.values.first!.time
            })
        }.map {
            DetectGestureTapSequence(touches: $0)
        }

        return formed
    }

    /// Filter values to only include original gesture events (changed and ended)
    var filterdWithRawDragGesture: [DetectGestureValue] {
        let rawDragTimings: [DetectGestureValue.Timing] = [.changed, .ended]
        return self.filter { value in
            rawDragTimings.contains(value.timing)
        }
    }

    /// Process taps for each individual finger
    func processPerSingleFingerTouch(_ completion: (DetectGestureSingleFingerTouch, DetectGestureTapSequence) -> Void) {
        for tapSequence in self.asTapSequences() {
            for singleFingerValues in tapSequence.touches {
                completion(singleFingerValues, tapSequence)
            }
        }
    }

    /// Check if any single finger tap satisfies the condition
    func anySingleFingerTouchContains(_ completion: @escaping (DetectGestureSingleFingerTouch, DetectGestureTapSequence) -> Bool) -> Bool {
        self.asTapSequences().anySingleFingerTouchContains(completion)
    }
}
