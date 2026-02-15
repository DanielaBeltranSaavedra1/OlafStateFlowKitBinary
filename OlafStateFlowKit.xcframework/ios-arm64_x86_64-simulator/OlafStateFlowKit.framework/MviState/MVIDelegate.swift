import SwiftUI
import Combine

// MARK: - BASE UI STATE

public protocol BaseUiState {}

// MARK: - UI EVENT

public protocol UiEvent {}

// MARK: - UI EFFECT

public protocol UiEffect {}


// MARK: - MVI DELEGATE

open class MVIDelegate<State: BaseUiState, Event: UiEvent, Effect: UiEffect>: ObservableObject {
    
    // State
    @Published public private(set) var state: State
    
    // Events channel
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    // Effects channel
    private let effectSubject = PassthroughSubject<Effect, Never>()
    public var effect: AnyPublisher<Effect, Never> {
        effectSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    public init(initialState: State, initEvent: Event? = nil) {
        self.state = initialState
        
        // Subscribe to events
        subscribeToEvents()
        
        // Send init event if provided
        if let initEvent = initEvent {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.sendEvent(initEvent)
            }
        }
    }
    
    // MARK: - Abstract Methods
    
    /// Override this method to handle events
    open func handleEvent(_ event: Event) {
        fatalError("handleEvent must be overridden")
    }
    
    // MARK: - Public Methods
    
    /// Update state
    public func setState(_ transform: (State) -> State) {
        self.state = transform(self.state)
    }
    
    /// Send event
    public func sendEvent(_ event: Event) {
        eventSubject.send(event)
    }
    
    /// Emit effect
    public func setEffect(_ transform: (State) -> Effect) {
        let effect = transform(state)
        effectSubject.send(effect)
    }
    
    private func subscribeToEvents() {
        eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)
    }
}
