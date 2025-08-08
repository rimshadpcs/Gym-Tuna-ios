import SwiftUI
import Combine

@MainActor
class NavCoordinator: ObservableObject {
    @Published var currentScreen: Screen = .auth
    @Published var navigationStack: [Screen] = []
    @Published var isPresenting = false
    @Published var presentedScreen: Screen?
    @Published var currentRoute: String = "auth"
    
    private let logger = "NavCoordinator"
    
    // Navigation callbacks
    var navigateToWorkout: ((String?, String?) -> Void)?
    
    // View reference for direct callback pattern (matching Android)
    private var createRoutineView: CreateRoutineView?
    
    func navigate(to screen: Screen) {
        print("\(logger): Navigating to \(screen.route)")
        
        if screen == .auth {
            // Clear stack when going to auth
            navigationStack.removeAll()
            currentScreen = screen
        } else {
            navigationStack.append(currentScreen)
            currentScreen = screen
        }
    }
    
    func navigateWithRoute(_ route: String) {
        print("\(logger): Navigating to route: \(route)")
        
        // Parse route to determine screen and parameters
        if let screen = parseRoute(route) {
            currentRoute = route
            navigate(to: screen)
        }
    }
    
    func popToRoot() {
        print("\(logger): Popping to root")
        navigationStack.removeAll()
        currentScreen = .home
    }
    
    func pop() {
        print("\(logger): Popping back")
        guard !navigationStack.isEmpty else { return }
        currentScreen = navigationStack.removeLast()
    }
    
    func present(_ screen: Screen) {
        print("\(logger): Presenting \(screen.route)")
        presentedScreen = screen
        isPresenting = true
    }
    
    func dismiss() {
        print("\(logger): Dismissing presented screen")
        isPresenting = false
        presentedScreen = nil
    }
    
    // MARK: - Workout Navigation (matching Kotlin logic)
    func setupWorkoutNavigation() {
        navigateToWorkout = { [weak self] routineId, routineName in
            guard let self = self else { return }
            
            print("\(self.logger): 🏋️ navigateToWorkout called with routineId=\(routineId ?? "nil"), routineName=\(routineName ?? "nil")")
            
            // TODO: Add WorkoutSessionManager equivalent
            // let sessionState = workoutSessionManager.getWorkoutState()
            
            switch (routineId, routineName) {
            case (nil, _): // where sessionState != nil:
                print("\(self.logger): 🏋️ CASE 1: RESUMING existing session")
                self.navigate(to: .activeWorkout)
                
            case let (id?, name?) where !id.isEmpty && !name.isEmpty:
                print("\(self.logger): 🏋️ CASE 2: STARTING new workout with routine")
                let route = Screen.activeWorkout.withRoutine(routineId: id, routineName: name)
                self.navigateWithRoute(route)
                
            default:
                print("\(self.logger): 🏋️ CASE 3: STARTING empty workout (Quick Workout)")
                let route = Screen.activeWorkout.route + "?routineName=Quick%20Workout"
                self.navigateWithRoute(route)
            }
        }
    }
    
    private func parseRoute(_ route: String) -> Screen? {
        let components = route.components(separatedBy: "?")
        let basePath = components[0]
        
        return Screen.allCases.first { $0.route == basePath }
    }
    
    func getRouteParameters(_ route: String) -> [String: String] {
        let components = route.components(separatedBy: "?")
        guard components.count > 1 else { return [:] }
        
        let queryString = components[1]
        let pairs = queryString.components(separatedBy: "&")
        
        var parameters: [String: String] = [:]
        for pair in pairs {
            let keyValue = pair.components(separatedBy: "=")
            if keyValue.count == 2 {
                let key = keyValue[0]
                let value = keyValue[1].removingPercentEncoding ?? keyValue[1]
                parameters[key] = value
            }
        }
        
        return parameters
    }
    
    func getQueryParam(for key: String) -> String? {
        let parameters = getRouteParameters(currentRoute)
        return parameters[key]
    }
    
    // MARK: - View Management (matching Android pattern)
    func setCreateRoutineView(_ view: CreateRoutineView) {
        print("🏪 NavCoordinator: Setting CreateRoutineView reference")
        self.createRoutineView = view
    }
    
    func getCreateRoutineView() -> CreateRoutineView? {
        let hasView = createRoutineView != nil
        print("🔍 NavCoordinator: Getting CreateRoutineView reference: \(hasView ? "FOUND" : "NIL")")
        return createRoutineView
    }
    
    // MARK: - Utility
    func reset() {
        print("\(logger): Resetting navigation to auth")
        currentScreen = .auth
        navigationStack.removeAll()
        createRoutineView = nil
    }
}