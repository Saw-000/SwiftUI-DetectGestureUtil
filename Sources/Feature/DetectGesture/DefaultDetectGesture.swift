/// Default Gestures

import Foundation

public enum DefaultDetectGesture {
    /// Single tap gesture
    case tap
    /// Long press gesture with minimum duration
    case longTap(minimumMilliSeconds: TimeInterval)
    /// Drag gesture with minimum distance
    case drag(minimumDistance: CGFloat)
    /// Slide gesture in a specific direction with minimum distance
    case slide(direction: DefaultDetectGestureDirection, minimumDistance: CGFloat)
    /// Swipe gesture in a specific direction
    case swipe(direction: DefaultDetectGestureDirection)
    /// Sequential tap gesture with count and maximum interval between taps
    case sequentialTap(count: Int, maximumTapIntervalMilliseconds: TimeInterval)
}

/// Direction for gesture detection
public enum DefaultDetectGestureDirection {
    /// Upward direction
    case up
    /// Downward direction
    case down
    /// Leftward direction
    case left
    /// Rightward direction
    case right
}
