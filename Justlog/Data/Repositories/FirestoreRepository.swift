import Foundation
import FirebaseFirestore
import FirebaseAuth
import os.log

class FirestoreRepository {
    
    // MARK: - Properties
    private let firestore: Firestore
    private let auth: Auth
    private let logger = Logger(subsystem: "com.justlog.app", category: "FirestoreRepository")
    
    // MARK: - Constants
    private static let USERS_COLLECTION = "users"
    private static let USER_STATS_COLLECTION = "user_stats"
    
    // MARK: - Initialization
    init(firestore: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.firestore = firestore
        self.auth = auth
    }
    
    // MARK: - User Profile Management
    func createOrUpdateUser(_ userProfile: UserProfile) async throws {
        guard !userProfile.uid.isEmpty else {
            throw FirestoreError.invalidUserProfile("User UID cannot be empty")
        }
        
        do {
            logger.info("Creating/updating user profile for uid: \(userProfile.uid)")
            
            // First, check if user document exists
            let userDoc = try await firestore.collection(Self.USERS_COLLECTION)
                .document(userProfile.uid)
                .getDocument()
            
            if !userDoc.exists {
                logger.info("User document doesn't exist, creating new profile")
                
                // Create new profile
                try await firestore.collection(Self.USERS_COLLECTION)
                    .document(userProfile.uid)
                    .setData(userProfile.toDictionary())
                
                // Create initial stats
                let initialStats: [String: Any] = [
                    "totalWorkouts": 0,
                    "totalVolume": 0.0,
                    "lastWorkoutDate": NSNull(),
                    "createdAt": Date().millisecondsSince1970
                ]
                
                try await firestore.collection(Self.USERS_COLLECTION)
                    .document(userProfile.uid)
                    .collection(Self.USER_STATS_COLLECTION)
                    .document("stats")
                    .setData(initialStats)
                
                logger.info("Successfully created new user profile and stats")
            } else {
                logger.info("Updating existing user profile")
                
                // Update last login
                let updateData: [String: Any] = [
                    "lastLoginAt": Date().millisecondsSince1970
                ]
                
                try await firestore.collection(Self.USERS_COLLECTION)
                    .document(userProfile.uid)
                    .setData(updateData, merge: true)
                
                logger.info("Successfully updated user profile")
            }
        } catch {
            logger.error("Error in createOrUpdateUser: \(error.localizedDescription)")
            throw FirestoreError.operationFailed("Failed to create/update user profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Workout Management
    func getWorkoutById(_ workoutId: String) async throws -> Workout? {
        do {
            let document = try await firestore.collection("user_workouts")
                .document(workoutId)
                .getDocument()
            
            guard document.exists, let data = document.data() else {
                return nil
            }
            
            // Map the exercises field
            let exercisesList = (data["exercises"] as? [[String: Any]])?.compactMap { exerciseMap in
                mapToExercise(exerciseMap)
            } ?? []
            
            return Workout(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                userId: data["userId"] as? String ?? "",
                exercises: exercisesList,
                createdAt: Date(millisecondsSince1970: data["createdAt"] as? Int64 ?? Date().millisecondsSince1970)
            )
        } catch {
            logger.error("Error getting workout by ID: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Exercise Mapping
    private func mapToExercise(_ exerciseMap: [String: Any]) -> Exercise? {
        guard let name = exerciseMap["name"] as? String else {
            logger.warning("Exercise mapping failed: missing name")
            return nil
        }
        
        do {
            // Create the base exercise from Firestore data
            let baseExercise = Exercise(
                id: exerciseMap["id"] as? String ?? "",
                name: name,
                muscleGroup: exerciseMap["muscleGroup"] as? String ?? "",
                equipment: exerciseMap["equipment"] as? String ?? "",
                defaultReps: exerciseMap["defaultReps"] as? Int ?? 15,
                defaultSets: exerciseMap["defaultSets"] as? Int ?? 3,
                isBodyweight: exerciseMap["isBodyweight"] as? Bool ?? false,
                usesWeight: exerciseMap["usesWeight"] as? Bool ?? true,
                tracksDistance: exerciseMap["tracksDistance"] as? Bool ?? false,
                isTimeBased: exerciseMap["isTimeBased"] as? Bool ?? false,
                description: exerciseMap["description"] as? String ?? ""
            )
            
            // Apply special handling for well-known exercises
            return applyExerciseDefaults(baseExercise)
            
        } catch {
            logger.error("Error mapping exercise: \(error.localizedDescription)")
            return nil
        }
    }
    
    /**
     * Applies special handling for well-known exercises to ensure they have the correct properties
     * regardless of what's in the database.
     */
    private func applyExerciseDefaults(_ exercise: Exercise) -> Exercise {
        // Convert the name to lowercase for case-insensitive matching
        let name = exercise.name.lowercased()
        
        switch true {
        case name.contains("plank"):
            // Plank is a time-based, bodyweight exercise
            logger.debug("Applying plank defaults for: \(exercise.name)")
            return exercise.copyWith(
                isTimeBased: true,
                usesWeight: false,
                isBodyweight: true
            )
            
        case name.contains("hang") && !name.contains("hanging leg raise"):
            // Hanging exercises are typically time-based
            logger.debug("Applying hang defaults for: \(exercise.name)")
            return exercise.copyWith(
                isTimeBased: true,
                isBodyweight: true
            )
            
        case name.contains("run") || name.contains("jog") || name.contains("walk"):
            // Running, jogging, and walking are distance-based
            logger.debug("Applying running/walking defaults for: \(exercise.name)")
            return exercise.copyWith(
                tracksDistance: true,
                isTimeBased: true
            )
            
        case name.contains("swim"):
            // Swimming is distance-based
            logger.debug("Applying swimming defaults for: \(exercise.name)")
            return exercise.copyWith(
                tracksDistance: true,
                isTimeBased: true
            )
            
        default:
            // Return the original exercise
            return exercise
        }
    }
    
    // MARK: - User Stats
    func getUserStats(for userId: String) async throws -> UserStats? {
        do {
            let document = try await firestore.collection(Self.USERS_COLLECTION)
                .document(userId)
                .collection(Self.USER_STATS_COLLECTION)
                .document("stats")
                .getDocument()
            
            guard document.exists, let data = document.data() else {
                logger.info("No user stats found for user: \(userId)")
                return nil
            }
            
            return UserStats(
                totalWorkouts: data["totalWorkouts"] as? Int ?? 0,
                totalVolume: data["totalVolume"] as? Double ?? 0.0,
                lastWorkoutDate: data["lastWorkoutDate"] as? Int64,
                createdAt: data["createdAt"] as? Int64 ?? Date().millisecondsSince1970
            )
            
        } catch {
            logger.error("Error getting user stats: \(error.localizedDescription)")
            throw FirestoreError.operationFailed("Failed to get user stats: \(error.localizedDescription)")
        }
    }
    
    func updateUserStats(_ stats: UserStats, for userId: String) async throws {
        do {
            let statsData: [String: Any] = [
                "totalWorkouts": stats.totalWorkouts,
                "totalVolume": stats.totalVolume,
                "lastWorkoutDate": stats.lastWorkoutDate as Any,
                "updatedAt": Date().millisecondsSince1970
            ]
            
            try await firestore.collection(Self.USERS_COLLECTION)
                .document(userId)
                .collection(Self.USER_STATS_COLLECTION)
                .document("stats")
                .setData(statsData, merge: true)
            
            logger.info("Successfully updated user stats for: \(userId)")
            
        } catch {
            logger.error("Error updating user stats: \(error.localizedDescription)")
            throw FirestoreError.operationFailed("Failed to update user stats: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Profile Retrieval
    func getUserProfile(for userId: String) async throws -> UserProfile? {
        do {
            let document = try await firestore.collection(Self.USERS_COLLECTION)
                .document(userId)
                .getDocument()
            
            guard document.exists, let data = document.data() else {
                logger.info("No user profile found for user: \(userId)")
                return nil
            }
            
            return UserProfile(
                uid: document.documentID,
                displayName: data["displayName"] as? String ?? "",
                email: data["email"] as? String ?? "",
                photoURL: data["photoURL"] as? String,
                createdAt: data["createdAt"] as? Int64 ?? Date().millisecondsSince1970,
                lastLoginAt: data["lastLoginAt"] as? Int64
            )
            
        } catch {
            logger.error("Error getting user profile: \(error.localizedDescription)")
            throw FirestoreError.operationFailed("Failed to get user profile: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Types
enum FirestoreError: LocalizedError {
    case invalidUserProfile(String)
    case operationFailed(String)
    case documentNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidUserProfile(let message):
            return "Invalid user profile: \(message)"
        case .operationFailed(let message):
            return "Firestore operation failed: \(message)"
        case .documentNotFound(let message):
            return "Document not found: \(message)"
        }
    }
}

// MARK: - Extensions
extension UserProfile {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "uid": uid,
            "displayName": displayName,
            "email": email,
            "createdAt": createdAt,
            "lastLoginAt": lastLoginAt ?? Date().millisecondsSince1970
        ]
        
        if let photoURL = photoURL {
            dict["photoURL"] = photoURL
        }
        
        return dict
    }
}

// MARK: - UserStats Model
struct UserStats {
    let totalWorkouts: Int
    let totalVolume: Double
    let lastWorkoutDate: Int64?
    let createdAt: Int64
    
    init(
        totalWorkouts: Int = 0,
        totalVolume: Double = 0.0,
        lastWorkoutDate: Int64? = nil,
        createdAt: Int64 = Date().millisecondsSince1970
    ) {
        self.totalWorkouts = totalWorkouts
        self.totalVolume = totalVolume
        self.lastWorkoutDate = lastWorkoutDate
        self.createdAt = createdAt
    }
}