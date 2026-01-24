# SwiftUI-DetectGestureUtil

一つのViewに複数のカスタムジェスチャを設定し、その中の一つだけを検知させられる機能を提供するSwift Packageです。

A Swift Package that allows you to detect only one of multiple custom gestures on a single SwiftUI View.

It is a wrapper of [SpatialEventGesture](https://developer.apple.com/documentation/swiftui/spatialeventgesture) (Official API).

// TODO: gifに差し替え
<img width="400" alt="Simulator Screenshot - iPad (A16) - 2025-11-03 at 05 22 09" src="https://github.com/user-attachments/assets/1ee868bc-91ad-48bd-9a0a-c507ba95c56a" />


## Usage

You can only use `View.detectGesture(detect:handle:_:)`.

It is divided into two phases: the detection phase and the handling phase.

```swift
import SwiftUI
import SwiftUI_DetectGestureUtil

/// Gestures you want to detect
enum MyGestureDetection {
    case tap
    case doubleTapDrag
    case circle
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Gestures: Tap, Double Tap + Drag, Circle")
        }
        .detectGesture(
            MyGestureDetection.self,
            detect: { state in // an instance of DetectGestureState<MyGestureDetection>. See DetectGestureState type to know gesture information you can get from this instance.

                // Gesture detection phase

                // Return value:
                // - Non-nil: Indicates that a gesture was detected and returns the detected gesture. The gesture detection phase is then complete and this closure will no longer be called. From then on, handleGesture will be called.
                // - nil: Indicates that no gesture was detected. As long as nil is returned, it will be called when the gesture state is updated, similar to Gesture.onChanged() and Gesture.onEnded(). A heartbeat mechanism ensures continuous updates even if fingers remain at the same location.

                if state.detected(.tap()) { // Several default gesture detections are provided. See DefaultDetectGesture type.
                    // Detect tap gesture
                    return .tap
                } else if state.detected(.sequentialTap(count: 2, maximumTapIntervalMilliseconds: 250, checkOnlyLastTap: false)) && state.detected(.drag(minimumDistance: 30)) {
                    // Detect double tap + drag gesture
                    return .doubleTapDrag
                } else {
                    // Custom: Detect circle gesture

                    // Get currently tapping fingers
                    let lastFingerTaps = state.tappingFingers

                    // Check if there's exactly one tapping finger
                    guard lastFingerTaps.count == 1 else {
                        return nil
                    }

                    // Get the tapping finger
                    let lastFingerTap = lastFingerTaps.last!

                    // Check if not overlapped with other finger taps
                    guard !lastFingerTap.isOverlapped(with: state.lastTapSequence.touches) else {
                        return nil
                    }

                    // Get Locations
                    let points = lastFingerTap.values
                        .withRawNotifiedGesture() // Get coordinates only when moved.
                        .map { $0.fingerEvent.location }

                    if detectCircle(points: points) {
                        return .circle
                    }
                }

                // No gesture detected
                return nil
            },
            handleGesture: { detection, state in
                // Gesture handling phase after detection

                // Return value:
                // - .finished: Indicates processing is complete. Gesture processing is completely finished. The closure will no longer be called.
                // - .yet: Indicates processing is incomplete. As long as .yet is returned, it will be called when the gesture state is updated, similar to Gesture.onChanged() and Gesture.onEnded(). A heartbeat mechanism ensures continuous updates even if fingers remain at the same location.

                switch detection {
                case .tap:
                    // Do your process.
                    return .finished // .finished means processing complete. Gesture processing is completely finished.

                case .doubleTapDrag:
                    if state.detected(.drag(minimumDistance: 30)) {
                        if state.lastGestureValue?.timing == .ended {
                            // Drag ended
                            return .finished
                        } else {
                            // Dragging
                            print("Dragging on: \(state.lastGestureValue?.locations.first)")
                            return .yet // .yet means processing incomplete. Continue processing as long as tap continues.
                        }
                    }

                case .circle:
                    // Do your process.
                    return .finished
                }
            },
            gestureEnded: { detection, state in
                // Optional: Called immediately after handleGesture returns .finished
                // Useful for cleanup.
                print("Gesture ended: \(detection)")
            }
        )
    }
}

private func detectCircle(points: [CGPoint]) -> Bool {
    ...
}
```

## Types
[See here](Support/types.md)

## Utility
### Default Gesture Detection
Tap, swipe, pinch, etc.

See this class: [DefaultDetectGesture](Sources/Feature/DetectGesture/DefaultDetectGesture.swift#L5)


### Sample
Run the project in Sample folder.

## Install

=> Swift Package Manager

```Package.swift
// Package.swift

let package = Package(
    ...
    dependencies: [
        .package(url: "https://github.com/Saw-000/SwiftUI-DetectGestureUtil", from: "<version>")
    ],
    targets: [
        .target(
            name: "HogeModule",
            dependencies: [
                .product(name: "SwiftUI-DetectGestureUtil", package: "SwiftUI-DetectGestureUtil")
            ]
        ),
    ]
)
```

or by Xcode.

### Requirements
- **v1.4.0+ (Multi-Fingered Gesture support): iOS 18.0+**
- **~v1.3.0 (Single-Fingered Gesture support): iOS 14.0+**