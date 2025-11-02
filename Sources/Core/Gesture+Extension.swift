import Foundation
import SwiftUI

public extension DragGesture.Value {
    /// Distance moved from the initial tap location
    var diff: CGPoint {
        CGPoint(x: location.x - startLocation.x, y: location.y - startLocation.y)
    }
}
