/// Default Gestures

import Foundation
public enum DefaultDetectGesture {
    case tap
    case longTap(minimumMilliSeconds: TimeInterval)
    case drag(minimumDistance: CGFloat)
    case slide(direction: DefaultDetectGestureDirection, minimumDistance: CGFloat)
    case swipe(direction: DefaultDetectGestureDirection)
    case sequentialTap(count: Int, maximumTapIntervalMilliseconds: TimeInterval)
}

public enum DefaultDetectGestureDirection {
    case top, bottom, left, right
}
