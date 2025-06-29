
import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    let id: String
    let displayName: String
    let email: String
    let createdAt: Int64
    let lastLoginAt: Int64
    let totalWorkouts: Int
    let totalVolume: Double
    let preferredMuscleGroups: [String]
    
    init(
        uid: String = "",
        displayName: String = "",
        email: String = "",
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        lastLoginAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        totalWorkouts: Int = 0,
        totalVolume: Double = 0.0,
        preferredMuscleGroups: [String] = []
    ) {
        self.id = uid
        self.displayName = displayName
        self.email = email
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.totalWorkouts = totalWorkouts
        self.totalVolume = totalVolume
        self.preferredMuscleGroups = preferredMuscleGroups
    }
}
