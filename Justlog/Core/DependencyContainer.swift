import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DependencyContainer: ObservableObject {
    
    // MARK: - Singletons
    static let shared = DependencyContainer()
    
    // MARK: - Firebase
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()
    
    // MARK: - Repositories
    private(set) lazy var authRepository: AuthRepository = AuthRepositoryImpl(
        userPreferences: userPreferences,
        googleSignInHelper: googleSignInHelper
    )
    
    private(set) lazy var workoutRepository: WorkoutRepository = WorkoutRepositoryImpl(
        firestore: firestore,
        authRepository: authRepository,
        workoutHistoryRepository: workoutHistoryRepository
    )
    
    private(set) lazy var exerciseRepository: ExerciseRepository = ExerciseRepositoryImpl(
        firestore: firestore,
        authRepository: authRepository
    )
    
    private(set) lazy var workoutHistoryRepository: WorkoutHistoryRepository = WorkoutHistoryRepositoryImpl()
    
    private(set) lazy var subscriptionRepository: SubscriptionRepository = SubscriptionRepositoryImpl(
        firestore: firestore,
        auth: auth
    )
    
    private(set) lazy var counterRepository: CounterRepository = CounterRepositoryImpl()
    
    // MARK: - Utilities
    private(set) lazy var firestoreRepository = FirestoreRepository(
        firestore: firestore,
        auth: auth
    )
    
    private(set) lazy var userPreferences = UserPreferences.shared
    private(set) lazy var restTimerManager = RestTimerManager()
    private(set) lazy var googleSignInHelper = GoogleSignInHelper()
    private(set) lazy var workoutSessionManager = WorkoutSessionManager.shared
    
    // MARK: - Initialization
    private init() {
        // Private initializer for singleton
    }
    
    // MARK: - ViewModel Factories
    
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(
            authRepository: authRepository,
            googleSignInHelper: googleSignInHelper,
            userPreferences: userPreferences,
            dependencyContainer: self
        )
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            workoutRepository: workoutRepository,
            authRepository: authRepository,
            workoutSessionManager: workoutSessionManager,
            workoutHistoryRepository: workoutHistoryRepository,
            subscriptionRepository: subscriptionRepository
        )
    }
    
    func makeWorkoutViewModel(routineId: String?, routineName: String) -> WorkoutViewModel {
        return WorkoutViewModel(
            routineId: routineId,
            routineName: routineName,
            workoutSessionManager: workoutSessionManager,
            workoutHistoryRepository: workoutHistoryRepository
        )
    }
    
    func makeExerciseSearchViewModel() -> ExerciseSearchViewModel {
        return ExerciseSearchViewModel(
            exerciseRepository: exerciseRepository
        )
    }
    
    func makeCreateRoutineViewModel() -> CreateRoutineViewModel {
        return CreateRoutineViewModel(
            workoutRepository: workoutRepository,
            authRepository: authRepository,
            subscriptionRepository: subscriptionRepository
        )
    }
    
    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(
            authRepository: authRepository,
            subscriptionRepository: subscriptionRepository,
            userPreferences: userPreferences
        )
    }
    
    func makeSubscriptionViewModel() -> SubscriptionViewModel {
        return SubscriptionViewModel(
            subscriptionRepository: subscriptionRepository
        )
    }
    
    func makeHistoryViewModel() -> HistoryViewModel {
        return HistoryViewModel(
            historyRepository: workoutHistoryRepository,
            authRepository: authRepository,
            userPreferences: userPreferences
        )
    }
    
    func makeCounterViewModel() -> CounterViewModel {
        return CounterViewModel(
            counterRepository: counterRepository,
            subscriptionRepository: subscriptionRepository,
            authRepository: authRepository
        )
    }
    
    // MARK: - Repository Access (for legacy compatibility)
    
    var repositories: Repositories {
        return Repositories(
            auth: authRepository,
            workout: workoutRepository,
            exercise: exerciseRepository,
            workoutHistory: workoutHistoryRepository,
            subscription: subscriptionRepository,
            counter: counterRepository
        )
    }
    
    // MARK: - Cache Management
    
    func clearAllCaches() {
        print("🧹 DependencyContainer: Clearing all repository caches")
        workoutRepository.clearCache()
        exerciseRepository.clearCache()
        subscriptionRepository.clearCache()
        counterRepository.clearCache()
    }
}

// MARK: - Repository Container
struct Repositories {
    let auth: AuthRepository
    let workout: WorkoutRepository
    let exercise: ExerciseRepository
    let workoutHistory: WorkoutHistoryRepository
    let subscription: SubscriptionRepository
    let counter: CounterRepository
}

// MARK: - Environment Key for SwiftUI
struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}