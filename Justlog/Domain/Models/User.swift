
import Foundation
import FirebaseAuth

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String?
    let displayName: String?
    let isAnonymous: Bool
    
    // Initialize from Firebase User
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.isAnonymous = firebaseUser.isAnonymous
    }
    
    // Manual initializer
    init(
        uid: String,
        email: String? = nil,
        displayName: String? = nil,
        isAnonymous: Bool = false
    ) {
        self.id = uid
        self.email = email
        self.displayName = displayName
        self.isAnonymous = isAnonymous
    }
}
