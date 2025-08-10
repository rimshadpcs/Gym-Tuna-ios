import SwiftUI
import Combine

struct NavGraph: View {
    @StateObject private var coordinator = NavCoordinator()
    @StateObject private var workoutSessionManager = WorkoutSessionManager.shared
    @StateObject private var homeViewModel: HomeViewModel
    @ObservedObject var authViewModel: AuthViewModel
    let authRepository: AuthRepository
    let workoutRepository: WorkoutRepository
    let exerciseRepository: ExerciseRepository
    let workoutHistoryRepository: WorkoutHistoryRepository
    let counterRepository: CounterRepository
    let subscriptionRepository: SubscriptionRepository
    let userPreferences: UserPreferences
    
    @State private var currentRoute: String = Screen.auth.route
    
    // Keep CreateRoutineViewModel as state to prevent recreation
    @State private var createRoutineViewModel: CreateRoutineViewModel?
    @State private var currentRoutineId: String? = nil
    @State private var isInCreateRoutineFlow: Bool = false

    init(authViewModel: AuthViewModel, authRepository: AuthRepository, workoutRepository: WorkoutRepository, exerciseRepository: ExerciseRepository, workoutHistoryRepository: WorkoutHistoryRepository, counterRepository: CounterRepository, subscriptionRepository: SubscriptionRepository, userPreferences: UserPreferences) {
        self.authRepository = authRepository
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
        self.workoutHistoryRepository = workoutHistoryRepository
        self.counterRepository = counterRepository
        self.subscriptionRepository = subscriptionRepository
        self.userPreferences = userPreferences
        _authViewModel = ObservedObject(wrappedValue: authViewModel)
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            workoutRepository: workoutRepository,
            authRepository: authRepository,
            workoutSessionManager: WorkoutSessionManager.shared,
            workoutHistoryRepository: workoutHistoryRepository,
            subscriptionRepository: subscriptionRepository
        ))
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                currentScreenView
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
        } else {
            // Fallback on earlier versions
        }
    }
    
    @ViewBuilder
    private var currentScreenView: some View {
        switch coordinator.currentScreen {
        case .auth:
            authScreenView
        case .home:
            homeScreenView
        case .activeWorkout:
            activeWorkoutScreenView
        case .createRoutine:
            createRoutineScreenView
        case .exerciseSearch:
            exerciseSearchScreenView
        case .history:
            historyScreenView
        case .workoutDetail:
            PlaceholderView(screenName: "Workout Detail", coordinator: coordinator)
        case .settings:
            settingsScreenView
        case .profile:
            profileScreenView
        case .subscription:
            subscriptionScreenView
        case .counter:
            counterScreenView
        case .createExercise:
            createExerciseScreenView
        case .routinePreview:
            PlaceholderView(screenName: "Routine Preview", coordinator: coordinator)
        case .workout:
            workoutScreenView
        }
    }
    
    private var authScreenView: some View {
        AuthScreen(
            viewModel: authViewModel,
            onNavigateToHome: {
                coordinator.navigate(to: .home)
            }
        )
    }
    
    private var homeScreenView: some View {
        HomeScreen(
            viewModel: homeViewModel,
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
                // Find the routine to get its name
                if let routine = homeViewModel.workouts.first(where: { $0.id == routineId }) {
                    let route = Screen.workout.withRoutine(routineId: routineId, routineName: routine.name)
                    coordinator.navigateWithRoute(route)
                } else {
                    coordinator.navigate(to: .workout)
                }
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
                if let routineId = routineId, let routineName = routineName {
                    let route = Screen.workout.withRoutine(routineId: routineId, routineName: routineName)
                    coordinator.navigateWithRoute(route)
                } else {
                    coordinator.navigate(to: .workout)
                }
            },
            onNavigateToCounter: {
                coordinator.navigate(to: .counter)
            },
            onNavigateToRoutinePreview: { routineId in
                coordinator.navigate(to: .routinePreview)
            }
        )
    }
    
    private var createRoutineScreenView: some View {
        let routeParameters = coordinator.getRouteParameters(coordinator.currentRoute)
        let routineId = routeParameters["routineId"]
        
        print("🔍 NavGraph: createRoutineScreenView - currentRoute: '\(coordinator.currentRoute)'")
        print("🔍 NavGraph: routeParameters: \(routeParameters)")
        print("🔍 NavGraph: extracted routineId: '\(routineId ?? "nil")'")
        
        return CreateRoutineViewContainer(
            routineId: routineId,
            createRoutineViewModel: $createRoutineViewModel,
            currentRoutineId: $currentRoutineId,
            isInCreateRoutineFlow: $isInCreateRoutineFlow,
            workoutRepository: workoutRepository,
            authRepository: authRepository,
            subscriptionRepository: subscriptionRepository,
            homeViewModel: homeViewModel,
            coordinator: coordinator
        )
    }
    
    private var exerciseSearchScreenView: some View {
        let routeParameters = coordinator.getRouteParameters(coordinator.currentRoute)
        let fromSource = routeParameters["from"]
        
        return ExerciseSearchView(
            exerciseRepository: exerciseRepository,
            onBack: {
                print("🔙 NavGraph: ExerciseSearch - Back button tapped")
                coordinator.pop()
            },
            onExerciseSelected: { exercise in
                print("🚀 NavGraph: Exercise selected: \(exercise.name) from source: \(fromSource ?? "routine")")
                
                // The exercise has already been sent through ExerciseChannel in ExerciseSearchView
                // Just navigate back - the channel will handle the exercise delivery
                print("🔙 NavGraph: Navigating back (exercise sent via ExerciseChannel)")
                coordinator.pop()
            },
            onCreateExercise: {
                coordinator.navigate(to: .createExercise)
            }
        )
    }
    
    private var settingsScreenView: some View {
        SettingsView(
            authRepository: authRepository,
            subscriptionRepository: subscriptionRepository,
            userPreferences: userPreferences,
            onBack: {
                coordinator.pop()
            },
            onNavigateToProfile: {
                coordinator.navigate(to: .profile)
            },
            onNavigateToSubscription: {
                coordinator.navigate(to: .subscription)
            }
        )
    }
    
    private var profileScreenView: some View {
        ProfileView(
            authRepository: authRepository,
            subscriptionRepository: subscriptionRepository,
            userPreferences: userPreferences,
            onBack: {
                coordinator.pop()
            },
            onSignOut: {
                Task {
                    await authViewModel.signOut()
                }
                coordinator.navigate(to: .auth)
            },
            onDeleteAccount: {
                Task {
                    await authViewModel.deleteAccount()
                }
                coordinator.navigate(to: .auth)
            }
        )
        .navigationBarHidden(true)
    }
    
    private var counterScreenView: some View {
        CounterView(
            counterRepository: counterRepository,
            subscriptionRepository: subscriptionRepository,
            authRepository: authRepository,
            onNavigateToSubscription: {
                coordinator.navigate(to: .subscription)
            }
        )
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !coordinator.navigationStack.isEmpty {
                IOSToolbarBackButton(action: { coordinator.pop() })
            }
        }
    }
    
    private var historyScreenView: some View {
        HistoryView(
            historyRepository: workoutHistoryRepository,
            authRepository: authRepository,
            userPreferences: userPreferences
        )
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !coordinator.navigationStack.isEmpty {
                IOSToolbarBackButton(action: { coordinator.pop() })
            }
        }
    }
    
    private var subscriptionScreenView: some View {
        SubscriptionView(
            subscriptionRepository: subscriptionRepository,
            onBack: { coordinator.pop() }
        )
        .navigationBarHidden(true)
    }
    
    private var workoutScreenView: some View {
        if let routineId = coordinator.getQueryParam(for: "routineId"),
           let routineName = coordinator.getQueryParam(for: "routineName") {
            WorkoutScreen(
                routineId: routineId,
                routineName: routineName,
                onBack: {
                    coordinator.pop()
                },
                onFinish: {
                    coordinator.navigate(to: .home)
                },
                onAddExercise: {
                    coordinator.navigateWithRoute(Screen.exerciseSearch.withSource("workout"))
                },
                onReplaceExercise: {
                    coordinator.navigateWithRoute(Screen.exerciseSearch.withReplacement())
                },
                onNavigateToSubscription: {
                    coordinator.navigate(to: .subscription)
                }
            )
        } else {
            // Quick workout - no routine
            WorkoutScreen(
                routineId: nil,
                routineName: "Quick Workout",
                onBack: {
                    coordinator.pop()
                },
                onFinish: {
                    coordinator.navigate(to: .home)
                },
                onAddExercise: {
                    coordinator.navigateWithRoute(Screen.exerciseSearch.withSource("workout"))
                },
                onReplaceExercise: {
                    coordinator.navigateWithRoute(Screen.exerciseSearch.withReplacement())
                },
                onNavigateToSubscription: {
                    coordinator.navigate(to: .subscription)
                }
            )
        }
    }
    
    private var createExerciseScreenView: some View {
        CreateExerciseScreen(
            workoutRepository: workoutRepository,
            authRepository: authRepository,
            subscriptionRepository: subscriptionRepository,
            onBack: {
                coordinator.pop()
            },
            onSave: { exercise in
                // Exercise was successfully created, send it through ExerciseChannel
                ExerciseChannel.shared.sendExercise(exercise)
                coordinator.pop()
            },
            onNavigateToPremiumBenefits: {
                coordinator.navigate(to: .subscription)
            }
        )
        .navigationBarHidden(true)
    }
    
    private var activeWorkoutScreenView: some View {
        // Active workout is the same as workout screen, just different navigation flow
        workoutScreenView
    }
    
    private func handleAuthStateChange(_ authState: AuthState) {
        switch authState {
        case .success:
            if coordinator.currentScreen != .home {
                coordinator.popToRoot()
            }
            // Refresh HomeViewModel data when user successfully logs in
            Task {
                await homeViewModel.loadInitialData()
            }
        case .initial, .error:
            if coordinator.currentScreen != .auth {
                coordinator.navigate(to: .auth)
            }
            // Clear HomeViewModel data when user logs out to prevent showing old data
            homeViewModel.workouts = []
            homeViewModel.currentUser = nil
        case .loading:
            break // Stay on current screen
        }
    }
}


// MARK: - CreateRoutineView Container
struct CreateRoutineViewContainer: View {
    let routineId: String?
    @Binding var createRoutineViewModel: CreateRoutineViewModel?
    @Binding var currentRoutineId: String?
    @Binding var isInCreateRoutineFlow: Bool
    
    let workoutRepository: WorkoutRepository
    let authRepository: AuthRepository
    let subscriptionRepository: SubscriptionRepository
    let homeViewModel: HomeViewModel
    let coordinator: NavCoordinator
    
    var body: some View {
        Group {
            if let viewModel = createRoutineViewModel {
                CreateRoutineView(
                    workoutRepository: workoutRepository,
                    authRepository: authRepository,
                    subscriptionRepository: subscriptionRepository,
                    routineId: routineId,
                    existingViewModel: viewModel,
                    onBack: {
                        // Clear ViewModel and flow when navigating back
                        print("🔙 NavGraph: User cancelled create routine, clearing ViewModel")
                        createRoutineViewModel = nil
                        currentRoutineId = nil
                        isInCreateRoutineFlow = false
                        
                        // Refresh home data when going back
                        Task {
                            await homeViewModel.refreshData()
                        }
                        
                        coordinator.pop()
                    },
                    onRoutineCreated: {
                        // Clear ViewModel and flow after creation
                        print("✅ NavGraph: Routine created successfully, clearing ViewModel")
                        createRoutineViewModel = nil
                        currentRoutineId = nil
                        isInCreateRoutineFlow = false
                        
                        // Refresh home screen data before navigating back
                        Task {
                            print("🔄 NavGraph: Refreshing HomeViewModel after routine creation")
                            await homeViewModel.refreshData()
                        }
                        
                        coordinator.navigate(to: .home)
                    },
                    onAddExercise: {
                        coordinator.navigate(to: .exerciseSearch)
                    },
                    onNavigateToSubscription: {
                        coordinator.navigate(to: .subscription)
                    }
                )
            } else {
                // This should never happen, but provide a fallback
                ProgressView("Initializing...")
                    .onAppear {
                        print("⚠️ NavGraph: ViewModel is nil, this should not happen!")
                    }
            }
        }
        .onAppear {
            ensureViewModelExists()
        }
    }
    
    @discardableResult
    private func ensureViewModelExists() -> Bool {
        // Only create new ViewModel if we're not in a flow or routineId changed
        let shouldCreateNewViewModel = createRoutineViewModel == nil || 
                                     (!isInCreateRoutineFlow && currentRoutineId != routineId)
        
        print("🔍 NavGraph: ensureViewModelExists called")
        print("🔍 NavGraph: routineId parameter: '\(routineId ?? "nil")'")
        print("🔍 NavGraph: currentRoutineId: '\(currentRoutineId ?? "nil")'")
        print("🔍 NavGraph: isInCreateRoutineFlow: \(isInCreateRoutineFlow)")
        print("🔍 NavGraph: createRoutineViewModel exists: \(createRoutineViewModel != nil)")
        print("🔍 NavGraph: shouldCreateNewViewModel: \(shouldCreateNewViewModel)")
        
        if shouldCreateNewViewModel {
            print("🏗️ NavGraph: Creating/updating CreateRoutineViewModel for routineId: \(routineId ?? "new")")
            if let existing = createRoutineViewModel {
                print("🏗️ NavGraph: Previous ViewModel state - name: '\(existing.routineName)', exercises: \(existing.selectedExercises.count)")
            }
            createRoutineViewModel = CreateRoutineViewModel(
                workoutRepository: workoutRepository,
                authRepository: authRepository,
                subscriptionRepository: subscriptionRepository,
                routineId: routineId
            )
            currentRoutineId = routineId
            isInCreateRoutineFlow = true
            print("🏗️ NavGraph: New ViewModel created and flow started")
        } else {
            print("🔄 NavGraph: Reusing existing ViewModel - name: '\(createRoutineViewModel?.routineName ?? "nil")', exercises: \(createRoutineViewModel?.selectedExercises.count ?? 0)")
            // Ensure we're marked as in flow
            isInCreateRoutineFlow = true
        }
        
        return createRoutineViewModel != nil
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


