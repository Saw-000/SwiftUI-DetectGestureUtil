/// Default Gestures

import Foundation
public enum DefaultDetectGesture {
    case tap
//    case sequentialTap(count: Int)
    case longTap(minimumMilliSeconds: TimeInterval)
//    case drag(minimumDistance: CGFloat)
}
