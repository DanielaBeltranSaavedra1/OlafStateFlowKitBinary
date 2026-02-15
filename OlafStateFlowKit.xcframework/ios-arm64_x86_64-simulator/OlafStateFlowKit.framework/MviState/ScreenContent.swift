import SwiftUI

public struct ScreenContent<State: BaseUiState, Event: UiEvent, Effect: UiEffect, Content: View>: View {
    
    @ObservedObject private var viewModel: MVIDelegate<State, Event, Effect>
    private let isScrollable: Bool
    private let handleEffects: (Effect) -> Void
    private let content: (State, @escaping (Event) -> Void) -> Content
    
    public init(
        viewModel: MVIDelegate<State, Event, Effect>,
        isScrollable: Bool = false,
        handleEffects: @escaping (Effect) -> Void = { _ in },
        @ViewBuilder content: @escaping (State, @escaping (Event) -> Void) -> Content
    ) {
        self.viewModel = viewModel
        self.isScrollable = isScrollable
        self.handleEffects = handleEffects
        self.content = content
    }
    
    public var body: some View {
        Group {
            if isScrollable {
                ScrollView {
                    VStack(spacing: 0) {
                        content(viewModel.state, viewModel.sendEvent)
                    }
                }
            } else {
                VStack(spacing: 0) {
                    content(viewModel.state, viewModel.sendEvent)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onReceive(viewModel.effect) { effect in
            handleEffects(effect)
        }
    }
}
