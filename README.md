# Navigation System and MVI for SwiftUI

This project implements a modular graph-based navigation system and the MVI (Model-View-Intent) architectural pattern for SwiftUI applications.

## 📋 Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Navigation](#navigation)
  - [Core Concepts](#core-concepts)
  - [Setup](#setup)
  - [Usage Examples](#usage-examples)
- [MVI Pattern](#mvi-pattern)
  - [Components](#components)
  - [Implementation](#implementation)
- [Complete Examples](#complete-examples)
- [Best Practices](#best-practices)

## 🚀 Features

### Navigation System
- ✅ Modular graph-based navigation
- ✅ Support for routes with parameters
- ✅ Back stack management
- ✅ Advanced configurations (popUpTo, singleTop, clearBackStack)
- ✅ Integrated dependency injection
- ✅ Type-safe routing

### MVI Pattern
- ✅ Clear separation of State, Events, and Effects
- ✅ Unidirectional data flow
- ✅ Asynchronous state management (UiState)
- ✅ Reusable ScreenContent component
- ✅ Effect handling with Combine

---

## 📦 Installation

1. Copy the following files to your project:
   - `NavigationCoordinator.swift`
   - `AppNavHost.swift`
   - `MVIDelegate.swift`
   - `ScreenContent.swift`

2. Make sure to import SwiftUI and Combine in your files.

---

## 🧭 Navigation

### Core Concepts

The navigation system is based on three main concepts:

1. **Route**: Defines a specific route in your app
2. **Graph**: Groups related routes (e.g., authentication flow)
3. **Navigator**: Connects a graph with the coordinator

### Setup

#### 1. Define Routes

```swift
// Authentication routes
enum AuthRoute: String, Route {
    case login
    case register
    case forgotPassword
    
    var routeId: String { rawValue }
}

// Home routes
enum HomeRoute: String, Route {
    case main
    case profile
    case settings
    
    var routeId: String { rawValue }
}
```

#### 2. Create Graphs

```swift
struct AuthGraph: Graph {
    var graphId: String { "auth" }
    var routes: [String] { ["login", "register", "forgotPassword"] }
    var startRoute: String? { "login" }
    
    func buildView(routeId: String, coordinator: NavigationCoordinator) -> AnyView {
        switch routeId {
        case "login":
            return AnyView(LoginScreen())
        case "register":
            return AnyView(RegisterScreen())
        case "forgotPassword":
            return AnyView(ForgotPasswordScreen())
        default:
            return AnyView(EmptyView())
        }
    }
}

struct HomeGraph: Graph {
    var graphId: String { "home" }
    var routes: [String] { ["main", "profile", "settings"] }
    var startRoute: String? { "main" }
    
    func buildView(routeId: String, coordinator: NavigationCoordinator) -> AnyView {
        switch routeId {
        case "main":
            return AnyView(HomeScreen())
        case "profile":
            return AnyView(ProfileScreen())
        case "settings":
            return AnyView(SettingsScreen())
        default:
            return AnyView(EmptyView())
        }
    }
}
```

#### 3. Register Navigators

```swift
struct AuthNavigator: Navigator {
    var graph: Graph { AuthGraph() }
    var isStartDestination: Bool { true } // Initial app screen
}

struct HomeNavigator: Navigator {
    var graph: Graph { HomeGraph() }
    var isStartDestination: Bool { false }
}
```

#### 4. Configure App

```swift
@main
struct MyApp: App {
    let coordinator = NavigationCoordinator()
    
    init() {
        // Register navigators
        let container = DependencyContainer.shared
        container.registerNavigator(AuthNavigator())
        container.registerNavigator(HomeNavigator())
        
        // Configure coordinator
        coordinator.configure(navigators: container.resolveNavigators())
    }
    
    var body: some Scene {
        WindowGroup {
            AppNavHost(coordinator: coordinator)
        }
    }
}
```

### Usage Examples

#### Simple Navigation

```swift
struct LoginScreen: View {
    @Environment(\.coordinator) var coordinator
    
    var body: some View {
        VStack {
            Text("Login")
            
            Button("Go to Register") {
                coordinator.navigate(routeId: "register")
            }
            
            Button("Forgot Password?") {
                coordinator.navigate(routeId: "forgotPassword")
            }
        }
    }
}
```

#### Navigation with Advanced Configuration

```swift
struct LoginScreen: View {
    @Environment(\.coordinator) var coordinator
    
    func onLoginSuccess() {
        // Clear back stack and navigate to home
        coordinator.navigate(configuration: NavScreenConfiguration(
            destinationRouteId: "main",
            clearBackStack: true
        ))
    }
    
    func onLoginFailed() {
        // Return to login, removing intermediate screens
        coordinator.navigate(configuration: NavScreenConfiguration(
            destinationRouteId: "login",
            popUpToRouteId: "login",
            isPopUpToInclusive: true,
            isLaunchSingleTop: true
        ))
    }
    
    var body: some View {
        VStack {
            Button("Login Success") {
                onLoginSuccess()
            }
            
            Button("Login Failed") {
                onLoginFailed()
            }
        }
    }
}
```

#### Back Navigation

```swift
struct RegisterScreen: View {
    @Environment(\.coordinator) var coordinator
    
    var body: some View {
        VStack {
            Text("Register")
            
            // Go back to previous screen
            Button("Back") {
                coordinator.navigateUp()
            }
            
            // Go back to specific screen
            Button("Back to Login") {
                coordinator.popTo(routeId: "login")
            }
            
            // Go back to flow start
            Button("Cancel") {
                coordinator.popToRoot()
            }
        }
    }
}
```

#### Navigation with Parameters

```swift
// Define route with parameters
enum ProductRoute: String, Route {
    case list
    case detail // detail?id=123&name=Product
    
    var routeId: String { rawValue }
}

// Navigation with parameters
struct ProductListScreen: View {
    @Environment(\.coordinator) var coordinator
    
    func navigateToDetail(productId: String, productName: String) {
        let routeWithParams = "detail?id=\(productId)&name=\(productName)"
        coordinator.navigate(routeId: routeWithParams)
    }
    
    var body: some View {
        List {
            Button("View Product 1") {
                navigateToDetail(productId: "123", productName: "iPhone")
            }
        }
    }
}

// Extract parameters
struct ProductDetailScreen: View {
    let routeId: String // Injected by the system
    
    var productId: String? {
        guard let url = URL(string: "dummy://\(routeId)"),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems else { return nil }
        return items.first(where: { $0.name == "id" })?.value
    }
    
    var body: some View {
        Text("Product ID: \(productId ?? "N/A")")
    }
}
```

### Configuration Options

#### NavScreenConfiguration

```swift
NavScreenConfiguration(
    destinationRouteId: String,      // Destination route (required)
    popUpToRouteId: String?,         // Remove screens up to this route
    isPopUpToInclusive: Bool,        // Include the popUpTo route in removal
    isLaunchSingleTop: Bool,         // Avoid duplicates in stack
    clearBackStack: Bool             // Clear entire back stack
)
```

**Examples:**

```swift
// Normal navigation
NavScreenConfiguration(destinationRouteId: "profile")

// Clear stack and navigate
NavScreenConfiguration(
    destinationRouteId: "home",
    clearBackStack: true
)

// Pop up to login and navigate to home
NavScreenConfiguration(
    destinationRouteId: "home",
    popUpToRouteId: "login",
    isPopUpToInclusive: true
)

// Navigate without duplicating (if already in stack, return to it)
NavScreenConfiguration(
    destinationRouteId: "profile",
    isLaunchSingleTop: true
)
```

---

## 🏗️ MVI Pattern

### Components

The MVI pattern consists of:

1. **State**: Represents the UI state
2. **Event**: User or system actions
3. **Effect**: Side effects (navigation, toasts, etc.)
4. **MVIDelegate**: ViewModel that handles the logic

### Implementation

#### 1. Define State, Events, and Effects

```swift
// State
struct LoginUiState: BaseUiState {
    var email: String = ""
    var password: String = ""
    var loginState: UiState<User> = .initial
    var isButtonEnabled: Bool {
        !email.isEmpty && !password.isEmpty
    }
}

// Events
enum LoginEvent: UiEvent {
    case emailChanged(String)
    case passwordChanged(String)
    case loginButtonClicked
    case retryButtonClicked
}

// Effects
enum LoginEffect: UiEffect {
    case navigateToHome
    case showError(String)
}
```

#### 2. Create ViewModel (MVIDelegate)

```swift
@MainActor
class LoginViewModel: MVIDelegate<LoginUiState, LoginEvent, LoginEffect> {
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        super.init(initialState: LoginUiState())
    }
    
    override func handleEvent(_ event: LoginEvent) {
        switch event {
        case .emailChanged(let email):
            setState { state in
                var newState = state
                newState.email = email
                return newState
            }
            
        case .passwordChanged(let password):
            setState { state in
                var newState = state
                newState.password = password
                return newState
            }
            
        case .loginButtonClicked:
            performLogin()
            
        case .retryButtonClicked:
            performLogin()
        }
    }
    
    private func performLogin() {
        setState { state in
            var newState = state
            newState.loginState = .loading
            return newState
        }
        
        Task {
            do {
                let user = try await authRepository.login(
                    email: state.email,
                    password: state.password
                )
                
                setState { state in
                    var newState = state
                    newState.loginState = .success(value: user)
                    return newState
                }
                
                setEffect { _ in .navigateToHome }
                
            } catch {
                setState { state in
                    var newState = state
                    newState.loginState = .systemError(
                        code: "LOGIN_ERROR",
                        message: error.localizedDescription
                    )
                    return newState
                }
                
                setEffect { _ in .showError(error.localizedDescription) }
            }
        }
    }
}
```

#### 3. Create the View

```swift
struct LoginScreen: View {
    @StateObject private var viewModel: LoginViewModel
    @Environment(\.coordinator) var coordinator
    
    init() {
        let authRepo = DependencyContainer.shared.resolve(AuthRepository.self)!
        _viewModel = StateObject(wrappedValue: LoginViewModel(authRepository: authRepo))
    }
    
    var body: some View {
        ScreenContent(
            viewModel: viewModel,
            isScrollable: true,
            handleEffects: handleEffect
        ) { state, sendEvent in
            VStack(spacing: 20) {
                // Email
                TextField("Email", text: Binding(
                    get: { state.email },
                    set: { sendEvent(.emailChanged($0)) }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Password
                SecureField("Password", text: Binding(
                    get: { state.password },
                    set: { sendEvent(.passwordChanged($0)) }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Content based on state
                switch state.loginState {
                case .initial, .empty:
                    EmptyView()
                    
                case .loading:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    
                case .success:
                    Text("✓ Login successful")
                        .foregroundColor(.green)
                    
                case .businessError(_, let message),
                     .systemError(_, let message):
                    VStack {
                        Text("❌ \(message)")
                            .foregroundColor(.red)
                        
                        Button("Retry") {
                            sendEvent(.retryButtonClicked)
                        }
                    }
                }
                
                // Button
                Button(action: { sendEvent(.loginButtonClicked) }) {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(state.isButtonEnabled ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!state.isButtonEnabled || state.loginState.isLoading)
            }
            .padding()
        }
    }
    
    private func handleEffect(_ effect: LoginEffect) {
        switch effect {
        case .navigateToHome:
            coordinator.navigate(configuration: NavScreenConfiguration(
                destinationRouteId: "main",
                clearBackStack: true
            ))
            
        case .showError(let message):
            // Show toast or alert
            print("Error: \(message)")
        }
    }
}
```

### UiState<T>

The `UiState` enum helps manage different loading states:

```swift
struct ProfileUiState: BaseUiState {
    var profileData: UiState<Profile> = .initial
    var postsData: UiState<[Post]> = .initial
}

// Usage in ViewModel
override func handleEvent(_ event: ProfileEvent) {
    switch event {
    case .loadProfile:
        setState { state in
            var newState = state
            newState.profileData = .loading
            return newState
        }
        
        Task {
            do {
                let profile = try await repository.getProfile()
                
                setState { state in
                    var newState = state
                    newState.profileData = .success(value: profile)
                    return newState
                }
            } catch {
                setState { state in
                    var newState = state
                    newState.profileData = .systemError(
                        code: "FETCH_ERROR",
                        message: error.localizedDescription
                    )
                    return newState
                }
            }
        }
    }
}

// Usage in View
if case .loading = state.profileData {
    ProgressView()
}

if let profile = state.profileData.result {
    ProfileView(profile: profile)
}

if let errorMessage = state.profileData.errorMessage {
    Text(errorMessage).foregroundColor(.red)
}
```

---

## 📚 Complete Examples

### Example 1: Onboarding Flow

```swift
// Routes
enum OnboardingRoute: String, Route {
    case welcome
    case step1
    case step2
    case complete
    
    var routeId: String { rawValue }
}

// Graph
struct OnboardingGraph: Graph {
    var graphId: String { "onboarding" }
    var routes: [String] { ["welcome", "step1", "step2", "complete"] }
    var startRoute: String? { "welcome" }
    
    func buildView(routeId: String, coordinator: NavigationCoordinator) -> AnyView {
        switch routeId {
        case "welcome": return AnyView(WelcomeScreen())
        case "step1": return AnyView(Step1Screen())
        case "step2": return AnyView(Step2Screen())
        case "complete": return AnyView(CompleteScreen())
        default: return AnyView(EmptyView())
        }
    }
}

// Screen
struct WelcomeScreen: View {
    @Environment(\.coordinator) var coordinator
    
    var body: some View {
        VStack {
            Text("Welcome")
                .font(.largeTitle)
            
            Button("Get Started") {
                coordinator.navigate(routeId: "step1")
            }
            
            Button("Skip") {
                coordinator.navigate(configuration: NavScreenConfiguration(
                    destinationRouteId: "complete",
                    clearBackStack: true
                ))
            }
        }
    }
}
```

### Example 2: List with Detail

```swift
// State
struct ProductListUiState: BaseUiState {
    var products: UiState<[Product]> = .initial
    var searchQuery: String = ""
    
    var filteredProducts: [Product] {
        guard let products = products.result else { return [] }
        if searchQuery.isEmpty { return products }
        return products.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }
}

// Events
enum ProductListEvent: UiEvent {
    case onAppear
    case searchQueryChanged(String)
    case productTapped(String) // productId
    case refreshTriggered
}

// Effects
enum ProductListEffect: UiEffect {
    case navigateToDetail(productId: String)
}

// ViewModel
@MainActor
class ProductListViewModel: MVIDelegate<ProductListUiState, ProductListEvent, ProductListEffect> {
    private let repository: ProductRepository
    
    init(repository: ProductRepository) {
        self.repository = repository
        super.init(
            initialState: ProductListUiState(),
            initEvent: .onAppear
        )
    }
    
    override func handleEvent(_ event: ProductListEvent) {
        switch event {
        case .onAppear, .refreshTriggered:
            loadProducts()
            
        case .searchQueryChanged(let query):
            setState { state in
                var newState = state
                newState.searchQuery = query
                return newState
            }
            
        case .productTapped(let productId):
            setEffect { _ in .navigateToDetail(productId: productId) }
        }
    }
    
    private func loadProducts() {
        setState { state in
            var newState = state
            newState.products = .loading
            return newState
        }
        
        Task {
            do {
                let products = try await repository.getProducts()
                setState { state in
                    var newState = state
                    newState.products = products.isEmpty ? .empty : .success(value: products)
                    return newState
                }
            } catch {
                setState { state in
                    var newState = state
                    newState.products = .systemError(
                        code: "LOAD_ERROR",
                        message: error.localizedDescription
                    )
                    return newState
                }
            }
        }
    }
}

// View
struct ProductListScreen: View {
    @StateObject private var viewModel: ProductListViewModel
    @Environment(\.coordinator) var coordinator
    
    init() {
        let repo = DependencyContainer.shared.resolve(ProductRepository.self)!
        _viewModel = StateObject(wrappedValue: ProductListViewModel(repository: repo))
    }
    
    var body: some View {
        ScreenContent(
            viewModel: viewModel,
            handleEffects: handleEffect
        ) { state, sendEvent in
            VStack {
                // Search bar
                TextField("Search products...", text: Binding(
                    get: { state.searchQuery },
                    set: { sendEvent(.searchQueryChanged($0)) }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                
                // Content
                switch state.products {
                case .initial:
                    Spacer()
                    
                case .loading:
                    Spacer()
                    ProgressView()
                    Spacer()
                    
                case .success:
                    if state.filteredProducts.isEmpty {
                        Text("No matching products")
                            .foregroundColor(.gray)
                    } else {
                        List(state.filteredProducts) { product in
                            Button(action: { sendEvent(.productTapped(product.id)) }) {
                                HStack {
                                    Text(product.name)
                                    Spacer()
                                    Text("$\(product.price, specifier: "%.2f")")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                case .empty:
                    VStack {
                        Text("No products available")
                        Button("Reload") {
                            sendEvent(.refreshTriggered)
                        }
                    }
                    
                case .businessError(_, let message),
                     .systemError(_, let message):
                    VStack {
                        Text("Error: \(message)")
                            .foregroundColor(.red)
                        Button("Retry") {
                            sendEvent(.refreshTriggered)
                        }
                    }
                }
            }
        }
        .navigationTitle("Products")
    }
    
    private func handleEffect(_ effect: ProductListEffect) {
        switch effect {
        case .navigateToDetail(let productId):
            coordinator.navigate(routeId: "detail?id=\(productId)")
        }
    }
}
```

---

## 💡 Best Practices

### Navigation

1. **Use typed routes**: Define enums for your routes instead of strings
2. **Organize by features**: Group related routes into graphs
3. **Centralize logic**: All navigation should go through the coordinator
4. **Clean the stack**: Use `clearBackStack` when switching main flows

### MVI

1. **Immutable state**: Always create a new state instead of modifying existing one
2. **One event per action**: Each user interaction = one event
3. **Effects for side-effects**: Use effects for navigation, analytics, toasts, etc.
4. **Lightweight ViewModel**: Delegate business logic to repositories/use cases
5. **UiState for async**: Use `UiState<T>` to handle loading states

### Dependency Injection

```swift
// Registration in App
@main
struct MyApp: App {
    init() {
        setupDependencies()
    }
    
    func setupDependencies() {
        let container = DependencyContainer.shared
        
        // Repositories
        container.register(AuthRepository.self) {
            AuthRepositoryImpl()
        }
        
        container.register(ProductRepository.self) {
            ProductRepositoryImpl()
        }
        
        // Navigators
        container.registerNavigator(AuthNavigator())
        container.registerNavigator(HomeNavigator())
    }
    
    var body: some Scene {
        WindowGroup {
            let coordinator = NavigationCoordinator()
            coordinator.configure(navigators: DependencyContainer.shared.resolveNavigators())
            return AppNavHost(coordinator: coordinator)
        }
    }
}

// Usage in ViewModel
init() {
    let authRepo = DependencyContainer.shared.resolve(AuthRepository.self)!
    _viewModel = StateObject(wrappedValue: LoginViewModel(authRepository: authRepo))
}
```

---

## 🎯 Summary

This system provides you with:

- **Modular and scalable navigation** with graphs
- **MVI architecture** for predictable data flow
- **Type-safety** throughout navigation
- **Robust state management** with UiState
- **Clear separation of concerns**

Questions or issues? Open an issue! 🚀

---

## 📝 Author & Updates

**Author:** [Daniela Beltran]([https://tusitio.com](https://www.linkedin.com/in/danielabeltransaavedra/)
**Last Updated:** February 15, 2026
