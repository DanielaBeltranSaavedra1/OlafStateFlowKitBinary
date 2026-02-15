import SwiftUI
import Combine

// MARK: - ROUTE PROTOCOL

public protocol Route: Hashable {
    var routeId: String { get }
}

// MARK: - NAVIGATE UP

public struct NavigateUp: Route {
    public var routeId: String { "navigate_up" }
    public init() {}
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(routeId)
    }
    
    public static func == (lhs: NavigateUp, rhs: NavigateUp) -> Bool {
        return lhs.routeId == rhs.routeId
    }
}

// MARK: - ANY ROUTE

public struct AnyRoute: Hashable {
    public let routeId: String
    public let graphId: String
    
    public init(routeId: String, graphId: String) {
        self.routeId = routeId
        self.graphId = graphId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(routeId)
        hasher.combine(graphId)
    }
    
    public static func == (lhs: AnyRoute, rhs: AnyRoute) -> Bool {
        return lhs.routeId == rhs.routeId && lhs.graphId == rhs.graphId
    }
}

// MARK: - GRAPH PROTOCOL

public protocol Graph {
    var graphId: String { get }
    var routes: [String] { get }
    var startRoute: String? { get }
    
    func buildView(routeId: String, coordinator: NavigationCoordinator) -> AnyView
}

// MARK: - NAVIGATOR PROTOCOL

public protocol Navigator {
    var graph: Graph { get }
    var isStartDestination: Bool { get }
}

// MARK: - NAVIGATION CONFIGURATION

public struct NavScreenConfiguration {
    public let destinationRouteId: String
    public let popUpToRouteId: String?
    public let isPopUpToInclusive: Bool
    public let isLaunchSingleTop: Bool
    public let clearBackStack: Bool
    
    public init(
        destinationRouteId: String,
        popUpToRouteId: String? = nil,
        isPopUpToInclusive: Bool = false,
        isLaunchSingleTop: Bool = true,
        clearBackStack: Bool = false
    ) {
        self.destinationRouteId = destinationRouteId
        self.popUpToRouteId = popUpToRouteId
        self.isPopUpToInclusive = isPopUpToInclusive
        self.isLaunchSingleTop = isLaunchSingleTop
        self.clearBackStack = clearBackStack
    }
}

// MARK: - NAVIGATION COORDINATOR

@MainActor
public class NavigationCoordinator: ObservableObject {
    @Published public var navigationPath = NavigationPath() {
        didSet {
            syncRouteMapWithPath()
        }
    }
    
    private var graphs: [String: Graph] = [:]
    private var startRoute: AnyRoute?
    private var routeMap: [AnyRoute] = []
    private var isInternalUpdate = false
    
    public init() {}
    
    public func configure(navigators: [Navigator]) {
        for navigator in navigators {
            self.graphs[navigator.graph.graphId] = navigator.graph
            
            if navigator.isStartDestination, let start = navigator.graph.startRoute {
                self.startRoute = AnyRoute(routeId: start, graphId: navigator.graph.graphId)
            }
        }
    }
    
    public func getStartRoute() -> AnyRoute? {
        return startRoute
    }
    
    public func getCurrentPath() -> [AnyRoute] {
        return routeMap
    }
    
    private func syncRouteMapWithPath() {
        if isInternalUpdate {
            return
        }
        
        let pathCount = navigationPath.count
        let mapCount = routeMap.count
        
        if pathCount < mapCount {
            let itemsToRemove = mapCount - pathCount
            if itemsToRemove > 0 && itemsToRemove <= mapCount {
                routeMap.removeLast(itemsToRemove)
            }
        }
    }
    
    public func navigate(configuration: NavScreenConfiguration) {
        if configuration.destinationRouteId == "navigate_up" {
            navigateUp()
            return
        }
        
        isInternalUpdate = true
        defer { isInternalUpdate = false }
        
        if configuration.clearBackStack {
            let count = navigationPath.count
            if count > 0 {
                navigationPath.removeLast(count)
            }
            routeMap.removeAll()
        }
        
        if let popUpTo = configuration.popUpToRouteId {
            popTo(routeId: popUpTo, inclusive: configuration.isPopUpToInclusive)
        }
        
        guard let graphId = findGraphForRoute(configuration.destinationRouteId) else {
            return
        }
        
        let route = AnyRoute(routeId: configuration.destinationRouteId, graphId: graphId)
        
        if configuration.isLaunchSingleTop {
            if let index = routeMap.firstIndex(of: route) {
                let itemsToRemove = routeMap.count - index - 1
                if itemsToRemove > 0 {
                    let pathCount = navigationPath.count
                    if itemsToRemove <= pathCount {
                        navigationPath.removeLast(itemsToRemove)
                        routeMap.removeLast(itemsToRemove)
                    }
                }
                return
            }
        }
        
        navigationPath.append(route)
        routeMap.append(route)
    }
    
    public func navigate(routeId: String) {
        navigate(configuration: NavScreenConfiguration(destinationRouteId: routeId))
    }
    
    public func navigateUp() {
        guard !routeMap.isEmpty else {
            return
        }
        
        guard navigationPath.count > 0 else {
            routeMap.removeAll()
            return
        }
        
        isInternalUpdate = true
        defer { isInternalUpdate = false }
        
        navigationPath.removeLast()
        routeMap.removeLast()
    }
    
    public func popTo(routeId: String, inclusive: Bool = false) {
        guard let index = routeMap.firstIndex(where: { $0.routeId == routeId }) else {
            return
        }
        
        let targetIndex = inclusive ? index : index + 1
        let itemsToRemove = routeMap.count - targetIndex
        
        if itemsToRemove > 0 {
            isInternalUpdate = true
            defer { isInternalUpdate = false }
            
            let pathCount = navigationPath.count
            let actualItemsToRemove = min(itemsToRemove, pathCount)
            
            if actualItemsToRemove > 0 {
                navigationPath.removeLast(actualItemsToRemove)
                routeMap.removeLast(actualItemsToRemove)
            }
        }
    }
    
    public func popToRoot() {
        isInternalUpdate = true
        defer { isInternalUpdate = false }
        
        let count = navigationPath.count
        if count > 0 {
            navigationPath.removeLast(count)
        }
        routeMap.removeAll()
    }
    
    public func buildView(for route: AnyRoute) -> AnyView {
        guard let graph = graphs[route.graphId] else {
            return AnyView(EmptyView())
        }
        return graph.buildView(routeId: route.routeId, coordinator: self)
    }
    
    private func findGraphForRoute(_ routeId: String) -> String? {
        let baseRoute = extractBaseRoute(from: routeId)
        
        for (graphId, graph) in graphs {
            if graph.routes.contains(baseRoute) {
                return graphId
            }
        }
        return nil
    }
    
    private func extractBaseRoute(from route: String) -> String {
        if let questionMarkIndex = route.firstIndex(of: "?") {
            return String(route[..<questionMarkIndex])
        }
        return route
    }
}

// MARK: - MODULE PROTOCOL

public protocol Module {
    func load()
}

extension View {
    func onReceiveEffect<Effect>(
        _ publisher: AnyPublisher<Effect, Never>,
        perform: @escaping (Effect) -> Void
    ) -> some View {
        self.onReceive(publisher, perform: perform)
    }
}
