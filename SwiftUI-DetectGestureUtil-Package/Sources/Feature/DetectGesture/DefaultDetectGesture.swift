/// Default Gestures

import Foundation
public enum DefaultDetectGesture {
    case tap
//    case sequentialTap(count: Int)
    case longTap(minimumMilliSeconds: TimeInterval)
    case drag(minimumDistance: CGFloat)
    case slide(direction: DefaultDetectGestureDirection, minimumDistance: CGFloat)
}

public enum DefaultDetectGestureDirection {
    case top, bottom, left, right
}
