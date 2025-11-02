# SwiftUI-DetectGestureUtil

SwiftUIの一つのViewに複数のカスタムジェスチャの中の一つだけを検知させられるSwift Packageです。

## Install

Swift Package Manager

## Usage

`View.detectGesture()`を使用できます。

一つのViewに複数のジェスチャを設定でき、そのうちの一つだけを検知させることができます。

ジェスチャを検知するフェーズと検知後に処理するフェーズに分かれます。

```swift
import SwiftUI
import SwiftUI-DetectGestureUtil

struct ContentView: View {
    // DetectGestureState<任意の検知したいジェスチャ型>をStateで持つ必要がある。
    @State private var detectGestureState = DetectGestureState<MyGestureDetection>()

    var body: some View {
        VStack {
            Text("ジェスチャ: タップ、ダブルタップ + ドラッグ、円形")
        }
        .detectGesture(
            state: $detectGestureState,
            detectGesture: { state in
                // ジェスチャを検知するフェーズ

                // 返り値:
                // - nil以外: ジェスチャ検知されたこと意味し、検知されたジェスチャを返す。その後ジェスチャ検知フェーズは完了し、このクロージャは呼ばれなくなる。以降はhandleGestureが呼ばれる。
                // - nil: ジェスチャ検知できなかったことを意味する。nilを返す限り、Gesture.onChanged()やGesture.onEnded()と同様ジェスチャ状態が更新されたときに呼ばれる。DragGestureと違い、同じ座標にとどまっていても新たな座標が追加され、コールされる。

                if state.detected(.tap) { // デフォルトジェスチャ検知はいくつか用意されている。
                    // タップジェスチャを検知
                    return .tap
                } else if state.detected(.sequentialTap(count: 2, maximumTapIntervalMilliseconds: 250)) && state.detected(.drag) {
                    // ダブルタップ+ドラッグのジェスチャを検知
                    return .doubleTapDrag
                } else {
                    // カスタム: デフォルトジェスチャを使わず、円のジェスチャを検知
                    let points = state.gestureValues
                        .filter { $0.timing != .heartbeat }
                        .map { $0.dragGestureValue.location }

                    if detectCircle(points: points) {
                        return .circle
                    }
                }

                // ジェスチャ検知されなかった
                return nil
            },
            handleGesture: { detection, state in
                // ジェスチャ検知後に処理するフェーズ

                // 返り値:
                // - true: 処理完了を示す。ジェスチャ処理は完全に終了する。以降、クロージャは呼ばれない。
                // - false: 処理未完了を示す。falseを返す限り、Gesture.onChanged()やGesture.onEnded()と同様ジェスチャ状態が更新されたときに呼ばれる。DragGestureと違い、同じ座標にとどまっていても新たな座標が追加され、コールされる。

                switch detection {
                case .tap:
                    print("タップ検知した")
                    return true // trueは処理完了。完全にジェスチャ処理が終了する。

                case .doubleTapDrag:
                    if state.detected(.drag(minimumDistance: 30)) {
                        if state.gestureValues.last?.timing == .ended {
                            // タップ終了した
                            detectedGestureText = "ダブルタップ + ドラッグ終了"
                            return true // trueは処理完了。
                        } else {
                            // タップ中
                            print("ダブルタップ + ドラッグ中...")
                            return false // falseは処理未完。タップが続く限り処理を続ける。
                        }
                    }

                case .circle:
                    if state.gestureValues.last?.timing == .ended {
                        detectedGestureText = "円形検知"
                        return true // trueは処理完了。
                    } else {
                        detectedGestureText = "円形描画中..."
                        return false // falseは処理未完。タップが続く限り処理を続ける。
                    }
                }
            }
        )
    }
}

/// 検知したいジェスチャ
enum MyGestureDetection {
    case tap
    case doubleTapDrag
    case circle
}


func detectCircle(points: [CGPoint]) -> Bool {
    ...
}
```

## Sample
Run the project in Sample folder.

## Reference
特になし
