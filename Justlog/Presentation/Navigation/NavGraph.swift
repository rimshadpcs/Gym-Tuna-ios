import SwiftUI
import Combine

struct NavGraph: View {
    @StateObject private var coordinator = NavCoordinator()
    @StateObject private var workoutSessionManager = WorkoutSessionManager()
    @StateObject private var exerciseSelectionManager = ExerciseSelectionManager()
    @ObservedObject var authViewModel: AuthViewModel
    let authRepository: AuthRepository
    let workoutRepository: WorkoutRepository
    let exerciseRepository: ExerciseRepository
    
    @State private var currentRoute: String = Screen.auth.route
    
    var body: some View {
        NavigationStack {
            Group {
                switch coordinator.currentScreen {
                case .auth:
                    AuthScreen(
                        viewModel: authViewModel,
                        onNavigateToHome: {
                            coordinator.navigate(to: .home)
                        }
                    )
                    
                case .home:
                    HomeScreen(
                        viewModel: HomeViewModel(
                            workoutRepository: workoutRepository,
                            authRepository: authRepository,
                            workoutSessionManager: workoutSessionManager
                        ),
                        workoutSessionManager: workoutSessionManager,
                        onSignOut: {
                            Task {
                                await authViewModel.signOut()
                            }
                        },
                        onStartEmptyWorkout: {
                            coordinator.navigate(to: .activeWorkout)
                        },
                        onStartRoutine: { routineId in
                            coordinator.navigate(to: .workout)
                        },
                        onEditRoutine: { routineId in
                            let route = Screen.createRoutine.withRoutineId(routineId)
                            coordinator.navigateWithRoute(route)
                        },
                        onNewRoutine: {
                            coordinator.navigate(to: .createRoutine)
                        },
                        onNavigateToSearch: {
                            coordinator.navigate(to: .exerciseSearch)
                        },
                        onNavigateToSettings: {
                            coordinator.navigate(to: .settings)
                        },
                        onNavigateToHistory: {
                            coordinator.navigate(to: .history)
                        },
                        onNavigateToWorkout: { routineId, routineName in
                            coordinator.navigate(to: .workout)
                        },
                        onNavigateToCounter: {
                            coordinator.navigate(to: .counter)
                        },
                        onNavigateToRoutinePreview: { routineId in
                            coordinator.navigate(to: .routinePreview)
                        }
                    )
                    
                // TODO: Implement these screen views when ready
                case .activeWorkout:
                    PlaceholderView(screenName: "Active Workout", coordinator: coordinator)
                    
                case .createRoutine:
                    let routeParameters = coordinator.getRouteParameters(coordinator.currentRoute)
                    let routineId = routeParameters["routineId"]
                    
                    CreateRoutineView(
                        workoutRepository: workoutRepository,
                        authRepository: authRepository,
                        routineId: routineId,
                        exerciseSelectionManager: exerciseSelectionManager,
                        onBack: {
                            coordinator.pop()
                        },
                        onRoutineCreated: {
                            coordinator.navigate(to: .home)
                        },
                        onAddExercise: {
                            coordinator.navigate(to: .exerciseSearch)
                        },
                        onNavigateToSubscription: {
                            coordinator.navigate(to: .subscription)
                        }
                    )
                    
                case .exerciseSearch:
                    ExerciseSearchView(
                        exerciseRepository: exerciseRepository,
                        exerciseSelectionManager: exerciseSelectionManager,
                        onBack: {
                            print("🔙 NavGraph: ExerciseSearch - Back button tapped")
                            coordinator.pop()
                        },
                        onExerciseSelected: { exercise in
                            print("🚀 NavGraph: Exercise selected: \(exercise.name) → Setting in ExerciseSelectionManager")
                            exerciseSelectionManager.selectExercise(exercise)
                            print("🔙 NavGraph: Navigating back to CreateRoutine")
                            coordinator.pop()
                        },
                        onCreateExercise: {
                            coordinator.navigate(to: .createExercise)
                        }
                    )
                    
                case .history:
                    PlaceholderView(screenName: "History", coordinator: coordinator)
                    
                case .workoutDetail:
                    PlaceholderView(screenName: "Workout Detail", coordinator: coordinator)
                    
                case .settings:
                    PlaceholderView(screenName: "Settings", coordinator: coordinator)
                    
                case .profile:
                    PlaceholderView(screenName: "Profile", coordinator: coordinator)
                    
                case .subscription:
                    PlaceholderView(screenName: "Subscription", coordinator: coordinator)
                    
                case .counter:
                    PlaceholderView(screenName: "Counter", coordinator: coordinator)
                    
                case .createExercise:
                    PlaceholderView(screenName: "Create Exercise", coordinator: coordinator)
                    
                case .routinePreview:
                    PlaceholderView(screenName: "Routine Preview", coordinator: coordinator)
                    
                case .workout:
                    PlaceholderView(screenName: "Workout", coordinator: coordinator)
                }
            }
            .onReceive(authViewModel.$authState) { authState in
                handleAuthStateChange(authState)
            }
            .onAppear {
                coordinator.setupWorkoutNavigation()
            }
        }
        .sheet(isPresented: $coordinator.isPresenting) {
            if let presentedScreen = coordinator.presentedScreen {
                NavigationView {
                    PlaceholderView(screenName: "Presented: \(presentedScreen.rawValue)", coordinator: coordinator)
                }
            }
        }
    }
    
    private func handleAuthStateChange(_ authState: AuthState) {
        switch authState {
        case .success:
            if coordinator.currentScreen != .home {
                coordinator.popToRoot()
            }
        case .initial, .error:
            if coordinator.currentScreen != .auth {
                coordinator.navigate(to: .auth)
            }
        case .loading:
            break // Stay on current screen
        }
    }
}


// MARK: - Placeholder View for unimplemented screens
struct PlaceholderView: View {
    let screenName: String
    let coordinator: NavCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Text(screenName)
                .vagFont(size: 24, weight: .bold)
                .foregroundColor(.primary)
            
            Text("This screen is not implemented yet")
                .vagFont(size: 16, weight: .regular)
                .foregroundColor(.secondary)
            
            if coordinator.currentScreen != .home {
                Button("Back to Home") {
                    coordinator.navigate(to: .home)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .navigationTitle(screenName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !coordinator.navigationStack.isEmpty {
                IOSToolbarBackButton(action: { coordinator.pop() })
            }
        }
    }
}


