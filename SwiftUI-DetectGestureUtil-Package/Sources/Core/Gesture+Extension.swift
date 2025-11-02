import Foundation
import SwiftUI

public extension DragGesture.Value {
    /// 最初にタップしたところからの移動距離
    var diff: CGPoint {
        CGPoint(x: location.x - startLocation.x, y: location.y - startLocation.y)
    }
}
