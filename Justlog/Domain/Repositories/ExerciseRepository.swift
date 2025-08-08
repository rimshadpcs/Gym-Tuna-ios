import Foundation
import Combine

protocol ExerciseRepository {
    
    /// Get all available exercises
    func getAllExercises() -> AnyPublisher<[Exercise], Error>
    
    /// Get exercises filtered by muscle group
    func getExercisesByMuscleGroup(_ muscleGroup: String) -> AnyPublisher<[Exercise], Error>
    
    /// Search exercises by name, equipment, or muscle group
    func searchExercises(query: String) -> AnyPublisher<[Exercise], Error>
    
    /// Get a specific exercise by ID
    func getExerciseById(_ id: String) -> AnyPublisher<Exercise?, Error>
    
    /// Create a new custom exercise
    func createCustomExercise(_ exercise: Exercise) async throws
    
    /// Update an existing exercise
    func updateExercise(_ exercise: Exercise) async throws
    
    /// Delete a custom exercise (only custom exercises can be deleted)
    func deleteCustomExercise(_ exerciseId: String) async throws
    
    /// Get all custom exercises created by the current user
    func getCustomExercises() -> AnyPublisher<[Exercise], Error>
}