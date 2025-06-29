
import SwiftUI

struct AuthScreenPreview: View {
    var body: some View {
        AuthScreen(
            viewModel: AuthViewModel(
                authRepository: MockAuthRepository(),
                googleSignInHelper: GoogleSignInHelper(),
                userPreferences: UserPreferences()
            ),
            onNavigateToHome: {
                print("Navigate to home")
            }
        )
    }
}

// Mock repository for preview
class MockAuthRepository: AuthRepository {
    func signInWithGoogle() async throws {
        // Mock implementation
    }
    
    func signInWithGoogleIntent() async throws {
        // Mock implementation
    }
    
    func signOut() async throws {
        // Mock implementation
    }
    
    func deleteAccount() async -> Result<Void, Error> {
        return .success(())
    }
    
    func isUserSignedIn() -> Bool {
        return false
    }
    
    func getCurrentUser() async -> User? {
        return nil
    }
}

#Preview {
    AuthScreenPreview()
}
