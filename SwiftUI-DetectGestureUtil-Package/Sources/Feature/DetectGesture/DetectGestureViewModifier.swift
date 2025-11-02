import SwiftUI

struct DetectGestureViewModifier<GestureDetection: Equatable>: ViewModifier {
    @Binding private var state: DetectGestureState<GestureDetection>

    private let coordinateSpace: CoordinateSpace

    private let detectGesture: (DetectGestureState<GestureDetection>) -> GestureDetection?

    /// return handle completion (completed: true)
    private let handleGesture: (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Bool

    init(
        state: Binding<DetectGestureState<GestureDetection>>,
        coordinateSpace: CoordinateSpace = .local,
        detectGesture: @escaping (DetectGestureState<GestureDetection>) -> GestureDetection?,
        handleGesture: @escaping (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Bool
    ) {
        self._state = state
        self.coordinateSpace = coordinateSpace
        self.detectGesture = detectGesture
        self.handleGesture = handleGesture
    }

    func body(content: Content) -> some View {
        GeometryReader { geometryProxy in
            content
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: coordinateSpace)
                        .onChanged { value in
                            handleGestureIfNeeded(dragGestureValue: value, geo: geometryProxy, timing: .changed)
                        }
                        .onEnded { value in
                            handleGestureIfNeeded(dragGestureValue: value, geo: geometryProxy, timing: .ended)

                            // 指定ジェスチャの検知とその後のハンドルが終わっていたら、タップの記録を初期化する。
                            if state.gestureDetected && state.handleFinished {
                                state = DetectGestureState<GestureDetection>()
                            }
                        }
                )
        }
    }

    /// ジェスチャ状態が更新された時に呼ぶ。情報を更新し、必要ならジェスチャの検知と検知後のハンドリングを行う。
    private func handleGestureIfNeeded(
        dragGestureValue: DragGesture.Value,
        geo: GeometryProxy,
        timing: DetectGestureStateValue.Timing
    ) {
        // 新しい値を記録
        let value = DetectGestureStateValue(
            dragGestureValue: dragGestureValue,
            geometryProxy: geo,
            timing: timing,
            time: Date()
        )
        state.gestureValues.append(value)

        // 指定されたジェスチャが検知されたか？
        let detection: GestureDetection?
        if let existingDetection = state.detection {
            detection = existingDetection
        } else {
            detection = detectGesture(state)
            // 記録
            if let detection {
                state.detection = detection
            }
        }


        // ジェスチャが検知された場合、割り当てられた処理をする。
        if state.gestureDetected, !state.handleFinished, let detection {
            state.handleFinished = handleGesture(detection, state)
        }
    }
}

extension View {
    public func detectGesture<GestureDetection: Equatable>(
        state: Binding<DetectGestureState<GestureDetection>>,
        coordinateSpace: CoordinateSpace = .local,
        detectGesture: @escaping (DetectGestureState<GestureDetection>) -> GestureDetection?,
        handleGesture: @escaping (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Bool
    ) -> some View {
        self.modifier(DetectGestureViewModifier(state: state, coordinateSpace: coordinateSpace, detectGesture: detectGesture, handleGesture: handleGesture))
    }
}
