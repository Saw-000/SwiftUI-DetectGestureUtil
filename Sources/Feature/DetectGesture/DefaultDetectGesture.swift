/// Default Gestures

import Foundation

public enum DefaultDetectGesture {
    /// Single tap gesture
    case tap(allowMultiTap: Bool = false)
    /// Long press gesture with minimum duration
    case longTap(minimumMilliSeconds: TimeInterval, allowMultiTap: Bool = false)
    /// Drag gesture with minimum distance
    case drag(minimumDistance: CGFloat, allowMultiTap: Bool = false)
    /// Slide gesture in a specific direction with minimum distance
    case slide(direction: DefaultDetectGestureDirection, minimumDistance: CGFloat, allowMultiTap: Bool = false)
    // TODO: Configure velocity
    /// Swipe gesture in a specific direction
    case swipe(direction: DefaultDetectGestureDirection, allowMultiTap: Bool = false)
    /// Sequential tap gesture with count and maximum interval between taps
    case sequentialTap(count: Int, maximumTapIntervalMilliseconds: TimeInterval)
    /// Pinch gesture on a specific axis with minimum distance change
    case pinch(minimumDistance: CGFloat)
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
