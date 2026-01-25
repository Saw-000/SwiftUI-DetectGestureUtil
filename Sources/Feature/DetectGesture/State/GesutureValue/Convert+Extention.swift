//
//  Convert+Extention.swift
//  SwiftUI-DetectGestureUtil
//
//  Created by IeSo on 2026/01/26.
//

import Foundation
import MyModuleCore

// MARK: - DetectGestureTouchSequence Conversion

public extension DetectGestureTouchSequence {
    func asFingerSequence() -> DetectGestureFingerSequence {
        let fingerEvents = values.flatMap {
            $0.asFingerEvents()
        }
        .sorted(by: {
            $0.time < $1.time
        })

        let fingers = Dictionary(
            grouping: fingerEvents,
            by: { $0.spatialEventCollectionEvent.id }
        )
        .map {
            DetectGestureFingerSequence.Finger(
                eventID: $0.key,
                values: $0.value
            )
        }
        .sorted(by: {
            $0.events.first!.time < $1.events.first!.time
        })

        return DetectGestureFingerSequence(fingers: fingers)
    }
}

// MARK: - DetectGestureTouchSequence.Value Conversions

public extension DetectGestureTouchSequence.Value {
    /// Convert to DetectGestureFingerSequence.Finger.Event format
    func asFingerEvents() -> [DetectGestureFingerSequence.Finger.Event] {
        spatialEventCollection.map { event in
            DetectGestureFingerSequence.Finger.Event(
                spatialEventCollectionEvent: event,
                relatedGestureValue: self
            )
        }
    }
}

// MARK: - [DetectGestureTouchSequence.Value] Conversions

public extension [DetectGestureTouchSequence.Value] {
    /// Split into sequences from tap start until all fingers are released
    private func splittedInSequences() -> [DetectGestureTouchSequence] {
        var buffer = [DetectGestureTouchSequence]()

        var nextStartIndex = 0
        for i in 0 ... count - 1 {
            let value = self[i]
            if value.timing == .ended {
                let sequence = DetectGestureTouchSequence(values: Array(self[nextStartIndex ... i]))
                buffer.append(sequence)
                nextStartIndex = i + 1
            } else if i == count - 1 {
                let sequence = DetectGestureTouchSequence(values: Array(self[nextStartIndex ... count - 1]))
                buffer.append(sequence)
            }
        }

        return buffer
    }

    /// Split into sequences from tap start until all fingers are released
    func asFingerSequences() -> [DetectGestureFingerSequence] {
        splittedInSequences().map {
            $0.asFingerSequence()
        }
    }

    /// Process taps for each individual finger
    func processPerFinger(_ completion: (DetectGestureFingerSequence.Finger, DetectGestureFingerSequence) -> Void) {
        for tapSequence in asFingerSequences() {
            for singleFingerValues in tapSequence.fingers {
                completion(singleFingerValues, tapSequence)
            }
        }
    }

    /// Check if any single finger tap satisfies the condition
    func anyFingerContains(_ completion: @escaping (DetectGestureFingerSequence.Finger, DetectGestureFingerSequence) -> Bool) -> Bool {
        asFingerSequences().anyFingerContains(completion)
    }
}

// MARK: - DetectGestureFingerSequence Conversions

public extension DetectGestureFingerSequence {
    /// Convert to [DetectGestureTouchSequence.Value]
    var asDetectGestureValues: [DetectGestureTouchSequence.Value] {
        fingers.flatMap(\.events)
            .map(\.relatedGestureValue)
            .distinctBy { $0.id }
            .sorted { $0.time < $1.time }
    }
}

// MARK: - [DetectGestureFingerSequence] Conversions

public extension [DetectGestureFingerSequence] {
    /// Convert to [DetectGestureTouchSequence.Value]
    var asDetectGestureValues: [DetectGestureTouchSequence.Value] {
        self.flatMap { $0.asDetectGestureValues }
    }
}
