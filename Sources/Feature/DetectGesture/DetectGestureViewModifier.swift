import SwiftUI

/// View modifier for detecting custom gestures
struct DetectGestureViewModifier<GestureDetection: Equatable>: ViewModifier {
    /// Gesture state binding
    @State private var state = DetectGestureState<GestureDetection>()

    @State private var geometry: GeometryProxy? = nil

    /// Coordinate space for gesture tracking
    private let coordinateSpace: CoordinateSpaceProtocol = .local

    /// Closure to detect gesture from state
    private let detectGesture: (DetectGestureState<GestureDetection>) -> GestureDetection?

    /// Closure to handle detected gesture, returns handle completion (completed: true)
    private let handleGesture: (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> HandleGestureReturn

    /// Optional closure called when gesture handling completes (right after handleGesture returns .finished)
    private let gestureEnded: ((_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Void)?

    /// Timer for periodic gesture state updates
    private let heartbeatTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(
        detect: @escaping (DetectGestureState<GestureDetection>) -> GestureDetection?,
        handle: @escaping (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> HandleGestureReturn,
        gestureEnded: ((_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Void)? = nil
    ) {
        self.detectGesture = detect
        self.handleGesture = handle
        self.gestureEnded = gestureEnded
    }

    func body(content: Content) -> some View {
        content
            .background(
                // Place GeometryReader in background
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
                SpatialEventGesture(coordinateSpace: coordinateSpace)
                    .onChanged { events in
                        processGesture(spatialEventCollection: events, geo: geometry, timing: .changed)
                    }
                    .onEnded { events in
                        processGesture(spatialEventCollection: events, geo: geometry, timing: .ended)

                        // If gesture detection and subsequent handling are complete, reset the state.
                        // In other words, gesture detection and handling can span multiple taps.
                        if state.handleFinished {
                            state = DetectGestureState<GestureDetection>()
                        }
                    }
            )
            .onReceive(heartbeatTimer) { _ in
                processGestureWithHeartBeat()
            }
    }

    /// Update state and perform gesture detection and handling.
    private func processGesture(
        spatialEventCollection: SpatialEventCollection,
        geo: GeometryProxy?,
        timing: DetectGestureTouchSequence.Value.Timing
    ) {
        guard let geo else {
            return
        }

        guard !state.handleFinished else {
            return
        }

        // Record new value
        let value = DetectGestureTouchSequence.Value(
            spatialEventCollection: spatialEventCollection,
            geometryProxy: geo,
            timing: timing,
            time: Date()
        )
        state.gestureValues.append(value)

        // Detect and handle gesture
        processGesture()
    }

    /// Perform gesture detection and handling with heartbeat.
    private func processGestureWithHeartBeat() {
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
        guard let lastValue = state.gestureValues.last else {
            return
        }

        let value = DetectGestureTouchSequence.Value(
            spatialEventCollection: lastValue.spatialEventCollection,
            geometryProxy: lastValue.geometryProxy,
            timing: .heartbeat,
            time: Date()
        )

        state.gestureValues.append(value)

        // Detect and handle gesture
        processGesture()
    }

    /// Gesture detection and handling
    private func processGesture() {
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
            let handleResult = handleGesture(detection, state)
            switch handleResult {
            case .yet:
                break

            case .finished:
                state.handleFinished = handleResult == .finished

            case .cancel:
                state.detection = nil
            }

            // Call gestureEnded callback when handling is complete
            if state.handleFinished {
                gestureEnded?(detection, state)
            }
        }
    }
}

public enum HandleGestureReturn {
    /// don't finish handling yet
    case yet
    /// finish handling
    case finished
    /// cancel detection
    case cancel
}

public extension View {
    /// Set multiple custom gestures simultaneously and detect only one of them.
    ///
    /// - Note: GestureDetection is the gesture you want to detect. It's better to use an enum.
    ///
    /// - Parameters:
    ///   - gestureType: The type of gesture to detect
    ///   - detectGesture: Closure that returns the detected gesture (generic GestureDetection type). Like Gesture.changed(), it is called when the gesture state is updated and is passed a DetectGestureState containing gesture information. If it returns a GestureDetection type, it indicates the gesture was detected and will not be called again; from then on, handleGesture will be called. It continues to be called as long as it returns nil. It can also handle across multiple taps.
    ///   - handleGesture: Closure that processes the detected gesture. This is called after the detectGesture phase completes. It receives the GestureDetection type returned by detectGesture. It returns a HandleGestureReturn enum to indicate whether handling is finished. If it returns .finished, it will not be called again, and all gesture processing is completely finished and reset. As long as it returns .yet, it continues to be called when the gesture state is updated (timing is the same as Gesture.changed()). It can also handle across multiple taps.
    ///   - gestureEnded: Optional closure called immediately after handleGesture returns .finished, indicating gesture handling has completed. Useful for cleanup or state reset operations.
    func detectGesture<GestureDetection: Equatable>(
        _: GestureDetection.Type,
        detect: @escaping (DetectGestureState<GestureDetection>) -> GestureDetection?,
        handle: @escaping (_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> HandleGestureReturn,
        gestureEnded: ((_ detection: GestureDetection, DetectGestureState<GestureDetection>) -> Void)? = nil
    ) -> some View {
        modifier(DetectGestureViewModifier<GestureDetection>(detect: detect, handle: handle, gestureEnded: gestureEnded))
    }
}
