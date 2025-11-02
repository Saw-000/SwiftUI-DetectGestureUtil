import SwiftUI

struct DetectGestureViewModifier<GestureDetection: Equatable>: ViewModifier {
    @Binding private var state: DetectGestureState<GestureDetection>

    private let coordinateSpace: CoordinateSpace

    private let detectGesture: (DetectGestureState<GestureDetection>) -> GestureDetection?

    /// return handle completion (completed: true)
    private let handleGesture: (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Bool
    
    private let heartbeatTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

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

                            // ジェスチャ検知とその後のハンドルまで終わっていたら、状態を初期化する。
                            // つまり逆を言えば、複数回のタップを跨いでジェスチャ検知やハンドルを行える。
                            if state.gestureDetected && state.handleFinished {
                                state = DetectGestureState<GestureDetection>()
                            }
                        }
                )
                .onReceive(heartbeatTimer) { _ in
                    handleGestureIfNeededWithHeartBeat()
                }
        }
    }

    /// 状態を更新し、ジェスチャの検知とハンドルを行う。
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

        // ジェスチャの検知とハンドル
        handleGestureIfNeeded()
    }
    
    /// ハートビートでジェスチャの検知とハンドルを行う。
    private func handleGestureIfNeededWithHeartBeat() {
        // ジェスチャ検知後の処理まで終わっていたら抜ける。
        guard !state.handleFinished else {
            return
        }
        
        // タップ開始してないなら抜ける
        guard !state.gestureValues.isEmpty else {
            return
        }
        
        // 指が離れていたら抜ける(ここは指離れ時に何かしたくなったら変えるかも)
        guard state.gestureValues.last?.timing != .ended else {
            return
        }
        
        // 前のジェスチャ情報をそのまま追加する。
        guard var lastValue = state.gestureValues.last else {
            return
        }
        
        lastValue.time = Date()
        lastValue.timing = .heartbeat
        let value = lastValue
        
        state.gestureValues.append(value)

        // ジェスチャの検知とハンドル
        handleGestureIfNeeded()
    }
    
    /// ジェスチャの検知とハンドル
    private func handleGestureIfNeeded() {
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
    /// 複数のカスタムジェスチャを同時に設定し、そのうちの一つだけを検知するジェスチャ。
    ///
    /// - Note: GestureDetectionは検知したいジェスチャ。enumにするのがベター。
    ///
    /// - Parameters:
    ///   - state: ジェスチャの状態を管理するBinding
    ///   - detectGesture: 検知されたジェスチャ(ジェネリックなGestureDetection型)を返すクロージャ。Gesture.changed()と同じように、ジェスチャ状態が更新された時に呼ばれ、ジェスチャ情報が格納されたDetectGestureState型が渡される。GestureDetection型を返した場合、ジェスチャが検知されたことを示し二度と呼ばれなくなり、以降はhandleGestureが呼ばれる。nilを返し続ける限り呼ばれ続ける。また、複数回タップを跨いでハンドルできる。
    ///   - handleGesture: 検知されたジェスチャを処理するクロージャ。detectGestureのフェーズの完了以降はこちらが呼ばれる。detectGestureで返したGestureDetection型が取れる。ハンドルが終了したかどうかという意味で完了時にBool型を返す。trueを返した場合二度と呼ばれなくなり、全てのジェスチャ処理が完全に終わり初期化される。falseを返し続ける限り、ジェスチャ状態が更新された時に呼ばれ続ける(タイミングとしてはGesture.changed()と同じ)。また、複数回タップを跨いでハンドルできる。
    public func detectGesture<GestureDetection: Equatable>(
        state: Binding<DetectGestureState<GestureDetection>>,
        coordinateSpace: CoordinateSpace = .local,
        detectGesture: @escaping (DetectGestureState<GestureDetection>) -> GestureDetection?,
        handleGesture: @escaping (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Bool
    ) -> some View {
        self.modifier(DetectGestureViewModifier(state: state, coordinateSpace: coordinateSpace, detectGesture: detectGesture, handleGesture: handleGesture))
    }
}
