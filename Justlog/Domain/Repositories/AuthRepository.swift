
import Foundation

protocol AuthRepository {
    func signInWithGoogle() async throws
    func signInWithGoogleIntent() async throws
    func signOut() async throws
    func deleteAccount() async -> Result<Void, Error>
    func isUserSignedIn() -> Bool
    func getCurrentUser() async -> User?
}
