
import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthRepositoryImpl: AuthRepository {
    private let auth = Auth.auth()
    private let userPreferences: UserPreferences
    private let googleSignInHelper: GoogleSignInHelper
    private let firestore = Firestore.firestore()
    private let logger = "AuthRepository"
    
    init(userPreferences: UserPreferences, googleSignInHelper: GoogleSignInHelper) {
        self.userPreferences = userPreferences
        self.googleSignInHelper = googleSignInHelper
    }
    
    func signInWithGoogle() async throws {
        print("\(logger): Starting Google sign in process in repository")
        try await googleSignInHelper.startSignIn()
        
        if auth.currentUser != nil {
            print("\(logger): Firebase user verified: \(auth.currentUser?.email ?? "no email")")
            userPreferences.setUserSignedIn(true)
        } else {
            throw AuthRepositoryError.firebaseSignInFailed
        }
    }
    
    func signInWithGoogleIntent() async throws {
        // This method is Android-specific, so we'll use the same as signInWithGoogle
        try await signInWithGoogle()
    }
    
    func signOut() async throws {
        print("\(logger): Starting sign out process")
        
        do {
            // First sign out from Google
            try await googleSignInHelper.signOut()
            print("\(logger): Google sign out completed")
            
            // Then clear Firebase auth
            try auth.signOut()
            print("\(logger): Firebase sign out completed")
            
            // Verify Firebase auth state is cleared
            if auth.currentUser == nil {
                print("\(logger): Firebase user successfully cleared")
            } else {
                print("\(logger): Warning: Firebase user still exists after signOut")
            }
            
        } catch {
            print("\(logger): Error during sign out: \(error)")
            // Even if there's an error, try to clear Firebase auth
            try? auth.signOut()
            throw error
        }
    }
    
    func deleteAccount() async -> Result<Void, Error> {
        do {
            guard let currentUser = auth.currentUser else {
                print("\(logger): No user signed in to delete")
                return .failure(AuthRepositoryError.noUserSignedIn)
            }
            
            let userId = currentUser.uid
            print("\(logger): Starting account deletion for user: \(userId)")
            
            // Step 1: Delete user data from Firestore
            do {
                let workoutsSnapshot = try await firestore.collection("workouts")
                    .whereField("userId", isEqualTo: userId)
                    .getDocuments()
                
                for document in workoutsSnapshot.documents {
                    try await document.reference.delete()
                }
                
                let routinesSnapshot = try await firestore.collection("routines")
                    .whereField("userId", isEqualTo: userId)
                    .getDocuments()
                
                for document in routinesSnapshot.documents {
                    try await document.reference.delete()
                }
                
                let exercisesSnapshot = try await firestore.collection("exercises")
                    .whereField("userId", isEqualTo: userId)
                    .getDocuments()
                
                for document in exercisesSnapshot.documents {
                    try await document.reference.delete()
                }
                
                try await firestore.collection("users").document(userId).delete()
                print("\(logger): User data deleted from Firestore")
            } catch {
                print("\(logger): Error deleting user data from Firestore: \(error)")
            }
            
            // Step 2: Sign out from Google
            try await googleSignInHelper.signOut()
            
            // Step 3: Delete Firebase Auth user
            try await currentUser.delete()
            print("\(logger): Firebase Auth user deleted")
            
            print("\(logger): Account deletion completed successfully")
            return .success(())
            
        } catch {
            print("\(logger): Error during account deletion: \(error)")
            return .failure(error)
        }
    }
    
    func isUserSignedIn() -> Bool {
        let isSignedIn = auth.currentUser != nil
        print("\(logger): Checking Firebase auth state: \(isSignedIn)")
        return isSignedIn
    }
    
    func getCurrentUser() async -> User? {
        guard let firebaseUser = auth.currentUser else { return nil }
        return User(from: firebaseUser)
    }
}

enum AuthRepositoryError: LocalizedError {
    case firebaseSignInFailed
    case noUserSignedIn
    
    var errorDescription: String? {
        switch self {
        case .firebaseSignInFailed:
            return "Firebase sign in failed to create user"
        case .noUserSignedIn:
            return "No user signed in"
        }
    }
}
