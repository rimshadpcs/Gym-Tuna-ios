
import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var navigationEvent = PassthroughSubject<Void, Never>()
    
    private let authRepository: AuthRepository
    private let googleSignInHelper: GoogleSignInHelper
    private let userPreferences: UserPreferences
    private let logger = "AuthViewModel"
    
    init(authRepository: AuthRepository, googleSignInHelper: GoogleSignInHelper, userPreferences: UserPreferences) {
        self.authRepository = authRepository
        self.googleSignInHelper = googleSignInHelper
        self.userPreferences = userPreferences
        
        checkAuthState()
    }
    
    func startGoogleSignIn() async {
        do {
            print("\(logger): Starting Google sign in")
            authState = .loading
            print("\(logger): Processing sign in")
            
            try await authRepository.signInWithGoogle()
            
            print("\(logger): Sign in successful")
            
            // Set user properties in analytics
            if let user = await authRepository.getCurrentUser() {
                // analyticsManager.setUserId(user.id)
                setInitialUserProperties()
            }
            
            authState = .success
            navigationEvent.send()
            
        } catch {
            print("\(logger): Sign in failed: \(error)")
            authState = .error(error.localizedDescription)
        }
    }
    
    func deleteAccount() async {
        print("\(logger): 🗑️ Starting account deletion...")
        
        let result = await authRepository.deleteAccount()
        
        switch result {
        case .success:
            print("\(logger): 🗑️ Account deleted successfully")
            userPreferences.clearPreferences()
            authState = .initial
        case .failure(let error):
            print("\(logger): ❌ Account deletion failed: \(error)")
            authState = .error("Failed to delete account: \(error.localizedDescription)")
        }
    }
    
    private func checkAuthState() {
        Task {
            print("\(logger): 🔍 Checking initial auth state...")
            
            // Add a small delay to prevent flicker
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            let isFirebaseSignedIn = authRepository.isUserSignedIn()
            let isSignedInPref = userPreferences.isUserSignedIn
            
            print("\(logger): 🔍 Auth check results:")
            print("\(logger):   - Firebase signed in: \(isFirebaseSignedIn)")
            print("\(logger):   - Preferences signed in: \(isSignedInPref)")
            
            if isFirebaseSignedIn && isSignedInPref {
                print("\(logger): ✅ User is authenticated, setting Success state")
                authState = .success
                navigationEvent.send()
            } else {
                print("\(logger): ❌ User is NOT authenticated")
                if isFirebaseSignedIn || isSignedInPref {
                    print("\(logger): 🧹 Inconsistent auth state detected, cleaning up...")
                    await signOutSilently()
                }
                print("\(logger): 📝 Setting state to Initial (show sign-in)")
                authState = .initial
            }
        }
    }
    
    func signOut() async {
        print("\(logger): 🚪 Starting user-initiated sign out...")
        print("\(logger): 🚪 Current state before sign out: \(authState)")
        
        // Don't show loading for sign-out - go straight to clearing
        authState = .loading
        
        do {
            // Clear auth state
            print("\(logger): 🚪 Clearing auth repository...")
            try await authRepository.signOut()
            
            print("\(logger): 🚪 Clearing user preferences...")
            userPreferences.clearPreferences()
            
            // Small delay to ensure cleanup is complete
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            print("\(logger): 🚪 Sign out completed, setting to Initial state")
            authState = .initial
            
            print("\(logger): 🚪 Final state after sign out: \(authState)")
            
        } catch {
            print("\(logger): ❌ Error during sign out: \(error)")
            // Force to Initial state even if there's an error
            authState = .initial
        }
    }
    
    // Silent sign out used internally for cleanup
    private func signOutSilently() async {
        do {
            print("\(logger): 🔇 Silent sign out for cleanup...")
            try await authRepository.signOut()
            userPreferences.clearPreferences()
            print("\(logger): 🔇 Silent sign out completed")
        } catch {
            print("\(logger): ❌ Error during silent sign out: \(error)")
        }
    }
    
    // Force reset auth state - useful for debugging
    func forceInitialState() {
        print("\(logger): 🔧 Force setting auth state to Initial")
        authState = .initial
    }
    
    // Set initial user properties in analytics
    private func setInitialUserProperties() {
        Task {
            do {
                // Get current preferences or use defaults
                let weightUnit = userPreferences.weightUnit
                let distanceUnit = userPreferences.distanceUnit
                let theme = userPreferences.appTheme
                
                // analyticsManager.setUserProperties(...) - implement when needed
                print("\(logger): Set user properties - theme: \(theme), weight: \(weightUnit), distance: \(distanceUnit)")
                
            } catch {
                print("\(logger): Error setting initial user properties: \(error)")
            }
        }
    }
}
