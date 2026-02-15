import SwiftUI
import Combine

public struct RouteInfo {
    public let graphName: String
    public let screenName: String
    
    public init(graphName: String = "NOT_SET", screenName: String = "NOT_SET") {
        self.graphName = graphName
        self.screenName = screenName
    }
}

// MARK: - ENVIRONMENT KEYS

public struct RouteInfoKey: EnvironmentKey {
    public static let defaultValue = RouteInfo()
}

public struct CoordinatorKey: EnvironmentKey {
    public static let defaultValue = NavigationCoordinator()
}

public extension EnvironmentValues {
    var routeInfo: RouteInfo {
        get { self[RouteInfoKey.self] }
        set { self[RouteInfoKey.self] = newValue }
    }
    
    var coordinator: NavigationCoordinator {
        get { self[CoordinatorKey.self] }
        set { self[CoordinatorKey.self] = newValue }
    }
}

// MARK: - DEPENDENCY CONTAINER

public class DependencyContainer {
    public static let shared = DependencyContainer()
    
    private var modules: [String: Any] = [:]
    private var navigators: [Navigator] = []
    
    private init() {}
    
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        modules[key] = factory
    }
    
    public func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        modules[key] = instance
    }
    
    public func registerNavigator(_ navigator: Navigator) {
        navigators.append(navigator)
    }
    
    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        if let factory = modules[key] as? () -> T {
            return factory()
        }
        
        if let instance = modules[key] as? T {
            return instance
        }
        
        return nil
    }
    
    public func resolveNavigators() -> [Navigator] {
        return navigators
    }
    
    public func getAll<T>(_ type: T.Type) -> [T] {
        return modules.values.compactMap { $0 as? T }
    }
}
