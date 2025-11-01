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
        content
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: coordinateSpace)
                    .onChanged { value in
                        handleGestureIfNeeded(value: value)
                    }
                    .onEnded { value in
                        // Tap complete here.
                        state.isTapped = true
                        
                        // for onEnded detected gesture.
                        handleGestureIfNeeded(value: value)
                        
                        // Gesture finished => reset state
                        state = DetectGestureState<GestureDetection>()
                    }
            )
    }
    
    /// Handle Gesture If Needed.
    private func handleGestureIfNeeded(value: DragGesture.Value) {
        state.dragGestures.append(value)
        
        // Detection
        let detection: GestureDetection?
        if let existingDetection = state.detection {
            detection = existingDetection
        } else {
            detection = detectGesture(state)
        }
        
        // Handle Detection
        if let detection, !state.handleFinished {
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
