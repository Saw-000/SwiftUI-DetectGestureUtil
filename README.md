# SwiftUI-DetectGestureUtil

一つのViewに複数のカスタムジェスチャを設定し、その中の一つだけを検知させられるSwift Packageです。

内部的には、DragGestureをカスタムしたものです。

A Swift Package that allows you to detect only one of multiple custom gestures on a single SwiftUI View.

It is internally something that customs DragGesture.

<img width="400" alt="Simulator Screenshot - iPad (A16) - 2025-11-03 at 05 22 09" src="https://github.com/user-attachments/assets/1ee868bc-91ad-48bd-9a0a-c507ba95c56a" />

(Sample app screenshot)

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

## Usage

You can use `View.detectGesture()`.

You can set multiple gestures on a single View and detect only one of them.

It is divided into two phases: the gesture detection phase and the gesture handling phase after detection.

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
            detectGesture: { state in // an instance of DetectGestureState<MyGestureDetection>. See DetectGestureState type to know gesture information you can get from this instance.

                // Gesture detection phase

                // Return value:
                // - Non-nil: Indicates that a gesture was detected and returns the detected gesture. The gesture detection phase is then complete and this closure will no longer be called. From then on, handleGesture will be called.
                // - nil: Indicates that no gesture was detected. As long as nil is returned, it will be called when the gesture state is updated, similar to Gesture.onChanged() and Gesture.onEnded(). Unlike DragGesture, new coordinates are added and called even if they remain at the same location.

                if state.detected(.tap) { // Several default gesture detections are provided. See DefaultDetectGesture type.
                    // Detect tap gesture
                    return .tap
                } else if state.detected(.sequentialTap(count: 2, maximumTapIntervalMilliseconds: 250)) && state.detected(.drag) {
                    // Detect double tap + drag gesture
                    return .doubleTapDrag
                } else {
                    // Custom: Detect circle gesture without using default gestures
                    let points = state.gestureValues
                        .withRawDragGesture()
                        .map { $0.dragGestureValue.location }

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
                // - .yet: Indicates processing is incomplete. As long as .yet is returned, it will be called when the gesture state is updated, similar to Gesture.onChanged() and Gesture.onEnded(). Unlike DragGesture, new coordinates are added and called even if they remain at the same location.

                switch detection {
                case .tap:
                    print("Tap detected")
                    return .finished // .finished means processing complete. Gesture processing is completely finished.

                case .doubleTapDrag:
                    if state.detected(.drag(minimumDistance: 30)) {
                        if state.lastGestureValue?.timing == .ended {
                            // Tap ended
                            print("Double Tap + Drag End")
                            return .finished // .finished means processing complete.
                        } else {
                            // Tapping
                            print("Double Tap + Dragging...")
                            return .yet // .yet means processing incomplete. Continue processing as long as tap continues.
                        }
                    }

                case .circle:
                    if state.lastGestureValue?.timing == .ended {
                        print("Circle Detected")
                        return .finished // .finished means processing complete.
                    } else {
                        print("Drawing Circle...")
                        return .yet // .yet means processing incomplete. Continue processing as long as tap continues.
                    }
                }
            },
            gestureEnded: { detection, state in
                // Optional: Called immediately after handleGesture returns .finished
                // Useful for cleanup or state reset operations
                print("Gesture ended: \(detection)")
            }
        )
    }
}

private func detectCircle(points: [CGPoint]) -> Bool {
    ...
}
```

### Default Gesture Detection
Tap, double tap, swipe, etc.

### DetectGestureState
You can access it in each handler of `View.detectGesture()`.

- `gestureValues: [DetectGestureValue]`: History of gesture information
- `detected(_:gestureValues:) -> Bool`: Whether the specified default gesture has already been detected
- `tapSplittedGestureValues: [[DetectGestureValue]]`: History of gesture information separated by tap
- `lastTapGestureValues: [DetectGestureValue]?`: GestureValues with last (or current in tapping) tap
- `lastGestureValue: DetectGestureValue?`: Last Detected Gestrue Value
- etc...

### DetectGestureValue
Value containing gesture state information. (like DragGesture.Value)

- `dragGestureValue: DragGesture.Value`: Drag gesture value from SwiftUI
- `geometryProxy: GeometryProxy`: Geometry proxy for view bounds
- `timing: Timing`: Timing of this state update
- `time: Date`: Timestamp of this state (using custom Date because DragGesture.Value.time has bugs)
- `isInView() -> Bool`: Check if gesture location is within view bounds
- etc...

See this class: [DefaultDetectGesture](Sources/Feature/DetectGesture/DefaultDetectGesture.swift#L5)

## Caution
- ※ Multi-Fingered Gesture has not supported yet. (No plans)

## Sample
Run the project in Sample folder.

## Reference
None
