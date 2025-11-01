import SwiftUI

/// State of DetectGesture
public struct DetectGestureState<GestureDetection: Equatable> {
    public var detection: GestureDetection? = nil
    public var handleFinished: Bool = false

    public var dragGestures: [DragGesture.Value] = []

    public var isTapped: Bool = false
    
    public init() {}
    
    public func detected(_ defaultGesture: DefaultDetectGesture) -> Bool {
        switch defaultGesture {
        case .tap:
            return isTapped
        }
    }
    
    /// Long tap ?
    public func isLongTap(
        miliseconds: Int = 500
    ) -> Bool {
        return false // TODO: 実装
    }
    
    /// Swipe？
    public func isSwipe(
        // TODO: 方向
    ) -> Bool {
        return false // TODO: 実装
    }
    
    /// Drag?
    public func isDrag(
        // TODO: 最小動かし、方向も？
    ) -> Bool {
        return false // TODO: 実装
    }
}
