import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import os.log

class ExerciseRepositoryImpl: ExerciseRepository {
    
    // MARK: - Properties
    private let firestore: Firestore
    private let authRepository: AuthRepository
    private let logger = Logger(subsystem: "com.justlog.app", category: "ExerciseRepository")
    
    // Cache management
    private var exerciseCache: [Exercise] = []
    private var lastCacheUpdate: Date = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    init(
        firestore: Firestore = Firestore.firestore(),
        authRepository: AuthRepository
    ) {
        self.firestore = firestore
        self.authRepository = authRepository
        
        logger.info("🏋️‍♂️ ExerciseRepositoryImpl initialized")
    }
    
    
    // MARK: - Repository Implementation
    
    func getAllExercises() -> AnyPublisher<[Exercise], Error> {
        let isCacheValid = Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration
        
        if isCacheValid && !exerciseCache.isEmpty {
            logger.info("⚡ Using cached exercises (\(self.exerciseCache.count) exercises)")
            return Just(self.exerciseCache)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            logger.info("📡 Fetching exercises from Firestore")
            return firestore.collection("exercises")
                .snapshotPublisher()
                .map { [weak self] snapshot in
                    let exercises = snapshot.documents.compactMap { doc in
                        self?.mapDocumentToExercise(doc)
                    }
                    
                    // Update cache
                    self?.exerciseCache = exercises
                    self?.lastCacheUpdate = Date()
                    
                    self?.logger.info("✅ Loaded \(exercises.count) exercises from Firestore")
                    return exercises
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getExercisesByMuscleGroup(_ muscleGroup: String) -> AnyPublisher<[Exercise], Error> {
        return getAllExercises()
            .map { exercises in
                exercises.filter { exercise in
                    exercise.muscleGroup.lowercased() == muscleGroup.lowercased()
                }
            }
            .eraseToAnyPublisher()
    }
    
    func searchExercises(query: String) -> AnyPublisher<[Exercise], Error> {
        return getAllExercises()
            .map { exercises in
                guard !query.isEmpty else { return exercises }
                
                return exercises.filter { exercise in
                    exercise.matchesFlexibleSearch(query: query)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getExerciseById(_ id: String) -> AnyPublisher<Exercise?, Error> {
        return getAllExercises()
            .map { exercises in
                exercises.first { $0.id == id }
            }
            .eraseToAnyPublisher()
    }
    
    func createCustomExercise(_ exercise: Exercise) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        logger.info("🆕 Creating custom exercise: \(exercise.name)")
        
        let finalExercise = exercise.id.isEmpty ? 
            exercise.copyWith(id: exercise.name.toCamelId()) : exercise
        
        // Store in flat structure format matching Firebase exercises collection
        let exerciseData: [String: Any] = [
            "name": finalExercise.name,
            "id": finalExercise.id,
            "primaryMuscles": [finalExercise.muscleGroup],
            "secondaryMuscles": [],
            "equipment": finalExercise.equipment,
            "category": "strength",
            "force": "pull",
            "level": "beginner", 
            "mechanic": "compound",
            "usesWeight": finalExercise.usesWeight,
            "isBodyweight": finalExercise.isBodyweight,
            "isTimeBased": finalExercise.isTimeBased,
            "isDistanceBased": finalExercise.tracksDistance,
            "defaultReps": finalExercise.defaultReps,
            "defaultSets": finalExercise.defaultSets,
            "instructions": finalExercise.description,
            "createdAt": Date().millisecondsSince1970,
            "createdBy": userId,
            "isCustom": true
        ]
        
        try await firestore.collection("exercises")
            .document(finalExercise.id)
            .setData(exerciseData)
        
        // Update cache
        exerciseCache.append(finalExercise)
        
        logger.info("✅ Successfully created custom exercise: \(finalExercise.name)")
    }
    
    func updateExercise(_ exercise: Exercise) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        logger.info("🔄 Updating exercise: \(exercise.name)")
        
        let exerciseData: [String: Any] = [
            "name": exercise.name,
            "primaryMuscles": [exercise.muscleGroup],
            "equipment": exercise.equipment,
            "usesWeight": exercise.usesWeight,
            "isBodyweight": exercise.isBodyweight,
            "isTimeBased": exercise.isTimeBased,
            "isDistanceBased": exercise.tracksDistance,
            "defaultReps": exercise.defaultReps,
            "defaultSets": exercise.defaultSets,
            "instructions": exercise.description,
            "updatedAt": Date().millisecondsSince1970,
            "updatedBy": userId
        ]
        
        try await firestore.collection("exercises")
            .document(exercise.id)
            .setData(exerciseData, merge: true)
        
        // Update cache
        if let index = exerciseCache.firstIndex(where: { $0.id == exercise.id }) {
            exerciseCache[index] = exercise
        }
        
        logger.info("✅ Successfully updated exercise: \(exercise.name)")
    }
    
    func deleteCustomExercise(_ exerciseId: String) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        logger.info("🗑️ Deleting custom exercise: \(exerciseId)")
        
        // Verify this is a custom exercise created by the user
        let document = try await firestore.collection("exercises")
            .document(exerciseId)
            .getDocument()
        
        guard document.exists,
              let data = document.data(),
              let createdBy = data["createdBy"] as? String,
              let isCustom = data["isCustom"] as? Bool,
              isCustom && createdBy == userId else {
            throw RepositoryError.unauthorized("Cannot delete this exercise")
        }
        
        try await firestore.collection("exercises")
            .document(exerciseId)
            .delete()
        
        // Update cache
        exerciseCache.removeAll { $0.id == exerciseId }
        
        logger.info("✅ Successfully deleted custom exercise: \(exerciseId)")
    }
    
    func getCustomExercises() -> AnyPublisher<[Exercise], Error> {
        return getAllExercises()
            .map { exercises in
                exercises.filter { exercise in
                    // This would need to be determined by checking if the exercise has isCustom = true
                    // For now, we'll return empty array since we can't determine this from Exercise model
                    false
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func mapDocumentToExercise(_ document: DocumentSnapshot) -> Exercise? {
        guard let data = document.data() else { return nil }
        
        let name = data["name"] as? String ?? document.documentID
        let exerciseId = data["id"] as? String ?? name.toCamelId()
        
        // Handle field name inconsistencies
        let isTimeBased = data["isTimeBased"] as? Bool ?? false
        let usesWeight = data["usesWeight"] as? Bool ?? true
        let tracksDistance = (data["tracksDistance"] as? Bool) ?? 
                           (data["isDistanceBased"] as? Bool) ?? false
        let isBodyweight = data["isBodyweight"] as? Bool ?? false
        
        // Smart defaults for known exercises
        let finalIsTimeBased = data.keys.contains("isTimeBased") ? isTimeBased :
            name.lowercased().contains("plank") ||
            name.lowercased().contains("wall sit") ||
            name.lowercased().contains("dead hang") ||
            name.lowercased().contains("hold")
        
        let finalUsesWeight = data.keys.contains("usesWeight") ? usesWeight :
            !(finalIsTimeBased && !name.lowercased().contains("weighted")) &&
            !name.lowercased().contains("bodyweight") &&
            !name.lowercased().contains("push") &&
            !name.lowercased().contains("pull")
        
        let finalTracksDistance = data.keys.contains("tracksDistance") || data.keys.contains("isDistanceBased") ?
            tracksDistance :
            name.lowercased().contains("running") ||
            name.lowercased().contains("cycling") ||
            name.lowercased().contains("rowing") ||
            name.lowercased().contains("swimming")
        
        let finalIsBodyweight = data.keys.contains("isBodyweight") ? isBodyweight : !finalUsesWeight
        
        return Exercise(
            id: exerciseId,
            name: name,
            muscleGroup: mapPrimaryMuscleToMuscleGroup(data["primaryMuscles"] as? [String]),
            equipment: data["equipment"] as? String ?? "",
            defaultReps: (data["defaultReps"] as? NSNumber)?.intValue ?? (finalIsTimeBased ? 0 : 12),
            defaultSets: (data["defaultSets"] as? NSNumber)?.intValue ?? 3,
            isBodyweight: finalIsBodyweight,
            usesWeight: finalUsesWeight,
            tracksDistance: finalTracksDistance,
            isTimeBased: finalIsTimeBased,
            description: data["instructions"] as? String ?? ""
        )
    }
    
    private func mapPrimaryMuscleToMuscleGroup(_ primaryMuscles: [String]?) -> String {
        guard let muscle = primaryMuscles?.first?.lowercased() else { return "full body" }
        
        switch muscle {
        case "abdominals": return "core"
        case "quadriceps", "hamstrings", "glutes": return "legs"
        case "calves": return "calves"
        case "chest": return "chest"
        case "shoulders": return "shoulders"
        case "triceps": return "triceps"
        case "biceps": return "biceps"
        case "forearms": return "forearms"
        case "lats", "middle back", "lower back", "traps": return "back"
        default: return muscle
        }
    }
}

// MARK: - Extensions

extension Query {
    func snapshotPublisher() -> AnyPublisher<QuerySnapshot, Error> {
        return Future { promise in
            let listener = self.addSnapshotListener { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                } else if let snapshot = snapshot {
                    promise(.success(snapshot))
                }
            }
            // Note: In a real implementation, you'd want to manage listener cleanup
        }
        .eraseToAnyPublisher()
    }
}
