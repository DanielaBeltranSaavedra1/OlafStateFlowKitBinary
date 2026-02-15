import SwiftUI
import Combine

public struct AppNavHost: View {
    @StateObject var coordinator: NavigationCoordinator
    
    public init(coordinator: NavigationCoordinator) {
        _coordinator = StateObject(wrappedValue: coordinator)
    }
    
    public var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            if let startRoute = coordinator.getStartRoute() {
                coordinator.buildView(for: startRoute)
                    .navigationDestination(for: AnyRoute.self) { route in
                        coordinator.buildView(for: route)
                            .environment(\.coordinator, coordinator)
                    }
            }
        }
        .environment(\.coordinator, coordinator)
    }
}
