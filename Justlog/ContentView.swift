import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @StateObject private var googleSignInHelper = GoogleSignInHelper()
    
    private var authRepository: AuthRepository {
        AuthRepositoryImpl(userPreferences: userPreferences, googleSignInHelper: googleSignInHelper)
    }
    
    private var workoutRepository: WorkoutRepository {
        WorkoutRepositoryImpl(authRepository: authRepository)
    }
    
    private var exerciseRepository: ExerciseRepository {
        ExerciseRepositoryImpl(authRepository: authRepository)
    }
    
    private var workoutHistoryRepository: WorkoutHistoryRepository {
        WorkoutHistoryRepositoryImpl()
    }
    
    private var authViewModel: AuthViewModel {
        AuthViewModel(
            authRepository: authRepository,
            googleSignInHelper: googleSignInHelper,
            userPreferences: userPreferences
        )
    }
    
    var body: some View {
        JustlogTheme(userPreferences: userPreferences) {
            NavGraph(
                authViewModel: authViewModel,
                authRepository: authRepository,
                workoutRepository: workoutRepository,
                exerciseRepository: exerciseRepository,
                workoutHistoryRepository: workoutHistoryRepository,
                userPreferences: userPreferences
            )
        }
    }
}

#Preview {
    ContentView()
}
