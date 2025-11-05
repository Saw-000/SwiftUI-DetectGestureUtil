import SwiftUI

/// View modifier for detecting custom gestures
struct DetectGestureViewModifier<GestureDetection: Equatable>: ViewModifier {
    /// Gesture state binding
    @State private var state = DetectGestureState<GestureDetection>()
    
    @State private var geometry: GeometryProxy? = nil

    /// Coordinate space for gesture tracking
    private let coordinateSpace: CoordinateSpace

    /// Closure to detect gesture from state
    private let detectGesture: (DetectGestureState<GestureDetection>) -> GestureDetection?

    /// Closure to handle detected gesture, returns handle completion (completed: true)
    private let handleGesture: (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Bool

    /// Optional closure called when gesture handling completes (right after handleGesture returns true)
    private let gestureEnded: ((_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Void)?

    /// Timer for periodic gesture state updates
    private let heartbeatTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(
        coordinateSpace: CoordinateSpace = .local,
        detectGesture: @escaping (DetectGestureState<GestureDetection>) -> GestureDetection?,
        handleGesture: @escaping (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Bool,
        gestureEnded: ((_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Void)? = nil
    ) {
        self.coordinateSpace = coordinateSpace
        self.detectGesture = detectGesture
        self.handleGesture = handleGesture
        self.gestureEnded = gestureEnded
    }

    func body(content: Content) -> some View {
        content
            .background(
                // GeometryReaderを背景に配置
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            geometry = geo
                        }
                        .onChange(of: geo.size) { _ in
                            geometry = geo
                        }
                }
            )
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: coordinateSpace)
                    .onChanged { value in
                        handleGestureIfNeeded(dragGestureValue: value, geo: geometry, timing: .changed)
                    }
                    .onEnded { value in
                        handleGestureIfNeeded(dragGestureValue: value, geo: geometry, timing: .ended)

                        // If gesture detection and subsequent handling are complete, reset the state.
                        // In other words, gesture detection and handling can span multiple taps.
                        if state.handleFinished {
                            state = DetectGestureState<GestureDetection>()
                        }
                    }
            )
            .onReceive(heartbeatTimer) { _ in
                handleGestureIfNeededWithHeartBeat()
            }
    }

    /// Update state and perform gesture detection and handling.
    private func handleGestureIfNeeded(
        dragGestureValue: DragGesture.Value,
        geo: GeometryProxy?,
        timing: DetectGestureStateValue.Timing
    ) {
        guard let geo else {
            return
        }
        
        guard !state.handleFinished else {
            return
        }

        // Record new value
        let value = DetectGestureStateValue(
            dragGestureValue: dragGestureValue,
            geometryProxy: geo,
            timing: timing,
            time: Date()
        )
        state.gestureValues.append(value)

        // Detect and handle gesture
        handleGestureIfNeeded()
    }

    /// Perform gesture detection and handling with heartbeat.
    private func handleGestureIfNeededWithHeartBeat() {
        // Exit if processing after gesture detection is finished.
        guard !state.handleFinished else {
            return
        }

        // Exit if tap has not started
        guard !state.gestureValues.isEmpty else {
            return
        }

        // Exit if finger is released (this may change if we want to do something when finger is released)
        guard state.gestureValues.last?.timing != .ended else {
            return
        }

        // Add the previous gesture information as is.
        guard var lastValue = state.gestureValues.last else {
            return
        }

        lastValue.time = Date()
        lastValue.timing = .heartbeat
        let value = lastValue

        state.gestureValues.append(value)

        // Detect and handle gesture
        handleGestureIfNeeded()
    }

    /// Gesture detection and handling
    private func handleGestureIfNeeded() {
        guard !state.handleFinished else {
            return
        }
        
        // Was the specified gesture detected?
        let detection: GestureDetection?
        if let existingDetection = state.detection {
            detection = existingDetection
        } else {
            detection = detectGesture(state)
            // Record
            if let detection {
                state.detection = detection
            }
        }

        // If gesture was detected, perform the assigned processing.
        if state.gestureDetected, !state.handleFinished, let detection {
            state.handleFinished = handleGesture(detection, state)

            // Call gestureEnded callback when handling is complete
            if state.handleFinished {
                gestureEnded?(detection, state)
            }
        }
    }
}

extension View {
    /// Set multiple custom gestures simultaneously and detect only one of them.
    ///
    /// - Note: GestureDetection is the gesture you want to detect. It's better to use an enum.
    ///
    /// - Parameters:
    ///   - gestureType: The type of gesture to detect
    ///   - coordinateSpace: The coordinate space for gesture tracking
    ///   - detectGesture: Closure that returns the detected gesture (generic GestureDetection type). Like Gesture.changed(), it is called when the gesture state is updated and is passed a DetectGestureState containing gesture information. If it returns a GestureDetection type, it indicates the gesture was detected and will not be called again; from then on, handleGesture will be called. It continues to be called as long as it returns nil. It can also handle across multiple taps.
    ///   - handleGesture: Closure that processes the detected gesture. This is called after the detectGesture phase completes. It receives the GestureDetection type returned by detectGesture. It returns a Bool upon completion to indicate whether handling is finished. If it returns true, it will not be called again, and all gesture processing is completely finished and reset. As long as it returns false, it continues to be called when the gesture state is updated (timing is the same as Gesture.changed()). It can also handle across multiple taps.
    ///   - gestureEnded: Optional closure called immediately after handleGesture returns true, indicating gesture handling has completed. Useful for cleanup or state reset operations.
    public func detectGesture<GestureDetection: Equatable>(
        _ gestureType: GestureDetection.Type,
        coordinateSpace: CoordinateSpace = .local,
        detectGesture: @escaping (DetectGestureState<GestureDetection>) -> GestureDetection?,
        handleGesture: @escaping (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Bool,
        gestureEnded: ((_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Void)? = nil
    ) -> some View {
        self.modifier(DetectGestureViewModifier<GestureDetection>(coordinateSpace: coordinateSpace, detectGesture: detectGesture, handleGesture: handleGesture, gestureEnded: gestureEnded))
    }
}
