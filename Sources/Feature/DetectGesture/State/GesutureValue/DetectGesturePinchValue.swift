import Foundation
import SwiftUI

/// ピンチジェスチャのある時点での値
public struct DetectGesturePinchValue {
    /// 必ず2つのみイベントを持つ
    public let values: [DetectGestureSingleFingerValue]
}

/// ピンチジェスチャの状態
public struct DetectGesturePinch {
    public let values: [DetectGesturePinchValue]
    /// ピンチが終了しているかどうか
    public let isEnded: Bool

    public init(values: [DetectGesturePinchValue], isEnded: Bool = false) {
        self.values = values
        self.isEnded = isEnded
    }
}

public extension DetectGesturePinchValue {
    var center: CGPoint {
        let firstEvent = values[0].fingerEvent
        let secondEvent = values[1].fingerEvent

        return CGPoint(
            x: (firstEvent.location.x + secondEvent.location.x) / 2,
            y: (firstEvent.location.y + secondEvent.location.y) / 2
        )
    }

    /// 距離
    var distance: CGFloat {
        let firstEvent = values[0].fingerEvent
        let secondEvent = values[1].fingerEvent

        let distance = CGSize(
            width: firstEvent.location.x - secondEvent.location.x,
            height: firstEvent.location.y - secondEvent.location.y
        ).distance
        return distance
    }
}

public extension DetectGesturePinch {
    var centerTransition: CGPoint {
        guard values.count >= 2 else {
            return .zero
        }

        let firstCenter = values[0].center
        let lastCenter = values[values.count - 1].center

        return CGPoint(x: lastCenter.x - firstCenter.x, y: lastCenter.y - firstCenter.y)
    }
}
