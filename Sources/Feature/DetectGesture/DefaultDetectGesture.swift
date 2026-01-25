/// Default Gestures

import Foundation

public enum DefaultDetectGesture {
    /// Single tap gesture
    case tap(allowMultiTap: Bool = false, checkOnlyLastTap: Bool = true)
    /// Long press gesture with minimum duration
    case longTap(milliSecondsForDetection: TimeInterval? = nil, allowMultiTap: Bool = false, checkOnlyLastTap: Bool = true)
    /// Drag gesture with minimum distance
    case drag(minimumDistance: CGFloat, allowMultiTap: Bool = false, checkOnlyLastTap: Bool = true)
    /// Slide gesture in a specific direction with minimum distance
    case slide(direction: DefaultDetectGestureDirection, minimumDistance: CGFloat, allowMultiTap: Bool = false, checkOnlyLastTap: Bool = true)
    // TODO: Configure velocity
    /// Swipe gesture in a specific direction
    case swipe(direction: DefaultDetectGestureDirection, minimumVelocity: CGFloat = 300, allowMultiTap: Bool = false, checkOnlyLastTapSequence: Bool = true)
    /// Sequential tap gesture with count and maximum interval between taps
    case sequentialTap(count: Int, maximumTapIntervalMilliseconds: TimeInterval, checkOnlyLastTap: Bool = true)
    /// Pinch gesture on a specific axis with minimum distance change
    case pinch(minimumDistance: CGFloat, checkOnlyLastTap: Bool = true)
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
