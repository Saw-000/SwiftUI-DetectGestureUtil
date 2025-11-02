import SwiftUI

/// State of DetectGesture
public struct DetectGestureState<GestureDetection: Equatable> {
    /// ジェスチャ情報の履歴
    public var gestureValues: [DetectGestureStateValue] = []
    
    /// 検知されたジェスチャ
    public var detection: GestureDetection? = nil
    
    /// ジェスチャがすでに検知されたか
    public var gestureDetected: Bool {
        detection != nil
    }
    
    /// ジェスチャ検知後の処理は終わったか
    public var handleFinished: Bool = false

    public init() {}
    
    /// 指定したデフォルトジェスチャがすでに検知されたか
    public func detected(_ defaultGesture: DefaultDetectGesture) -> Bool {
        switch defaultGesture {
        case .tap:
            return gestureValues.contains(where: { $0.timing == .ended && $0.isInView() })
        }
    }
}

public struct DetectGestureStateValue {
    public enum Timing {
        case changed, ended
    }
    
    public let dragGestureValue: DragGesture.Value
    public let geometryProxy: GeometryProxy
    public let timing: Timing
    
    public func isInView() -> Bool {
        return 0 <= dragGestureValue.location.x && dragGestureValue.location.x <= geometryProxy.size.width
            && 0 <= dragGestureValue.location.y && dragGestureValue.location.y <= geometryProxy.size.height
    }
}
