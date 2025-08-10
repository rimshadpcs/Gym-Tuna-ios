import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @StateObject private var dependencyContainer = DependencyContainer.shared
    
    var body: some View {
        JustlogTheme(userPreferences: userPreferences) {
            NavGraph(
                authViewModel: dependencyContainer.makeAuthViewModel(),
                authRepository: dependencyContainer.repositories.auth,
                workoutRepository: dependencyContainer.repositories.workout,
                exerciseRepository: dependencyContainer.repositories.exercise,
                workoutHistoryRepository: dependencyContainer.repositories.workoutHistory,
                counterRepository: dependencyContainer.repositories.counter,
                subscriptionRepository: dependencyContainer.repositories.subscription,
                userPreferences: userPreferences
            )
        }
    }
}

#Preview {
    ContentView()
}
