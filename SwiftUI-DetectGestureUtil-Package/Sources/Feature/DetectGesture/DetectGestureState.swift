import SwiftUI
import MyModuleCore

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
            return gestureValues.contains(where: {
                $0.timing == .ended && $0.isInView()
            })

        case let .longTap(minimumMilliSecond):
            var now = Date()
            for value in gestureValues.reversed() {
                if now.timeIntervalSince(value.time) * 1000 >= minimumMilliSecond {
                    return true
                }

                if value.timing == .ended {
                    now = value.time
                }
            }

            return false

        case let .drag(minimumDistance):
            return gestureValues.contains(where: {
                $0.dragGestureValue.translation.distance >= minimumDistance
            })

        case let .slide(direction, minimumDistance):
            return gestureValues.contains(where: {
                let diff = $0.dragGestureValue.diff

                return switch direction {
                case .top:
                    -diff.y >= minimumDistance
                case .bottom:
                    diff.y >= minimumDistance
                case .left:
                    -diff.x >= minimumDistance
                case .right:
                    diff.x >= minimumDistance
                }
            })

        case .swipe(direction: let direction):
            return gestureValues
                .filter { value in
                    value.timing == .ended
                }
                .contains(where: {
                    let velocity = $0.dragGestureValue.velocity

                    return switch direction {
                    case .top:
                        -velocity.height >= Const.swipeMinimumVelocity
                    case .bottom:
                        velocity.height >= Const.swipeMinimumVelocity
                    case .left:
                        -velocity.width >= Const.swipeMinimumVelocity
                    case .right:
                        velocity.width >= Const.swipeMinimumVelocity
                    }
                })

        case let .sequentialTap(count, maximumTapIntervalMilliseconds):
            guard count > 0 else {
                return false
            }
            
            let tapEndValueList = gestureValues.filter { $0.timing == .ended && $0.isInView() }
            
            guard tapEndValueList.count >= count else {
                return false
            }
            
            var sequentialTapCount = 1
            var previousTapEndValue: DetectGestureStateValue? = nil
            
            // 連続タップ回数を数える
            for tapEndValue in tapEndValueList {
                if let pTapEndValue = previousTapEndValue {
                    let isSequentialTap = tapEndValue.time.timeIntervalSince(pTapEndValue.time) * 1000 <= maximumTapIntervalMilliseconds
                    
                    if isSequentialTap {
                        sequentialTapCount += 1
                    } else {
                        // タップ間隔が既定秒数を超えたらリセット
                        sequentialTapCount = 1
                    }
                    
                    // 連続タップ回数が既定回数を超えたら検知
                    if sequentialTapCount >= count {
                        return true
                    }
                    
                    previousTapEndValue = tapEndValue
                } else {
                    previousTapEndValue = tapEndValue
                    continue
                }
            }
            
            // 連続タップ回数が既定回数を超えることがなかった
            return false
        }
    }
}

public struct DetectGestureStateValue {
    public enum Timing {
        case changed, ended, heartbeat
    }

    public let dragGestureValue: DragGesture.Value
    public let geometryProxy: GeometryProxy
    public var timing: Timing
    public var time: Date // DragGesture.Value.timeはバグがあって使えないので、自前のDateを付与

    public func isInView() -> Bool {
        return 0 <= dragGestureValue.location.x && dragGestureValue.location.x <= geometryProxy.size.width
            && 0 <= dragGestureValue.location.y && dragGestureValue.location.y <= geometryProxy.size.height
    }
}

private struct Const {
    static let swipeMinimumVelocity: CGFloat = 300
}
