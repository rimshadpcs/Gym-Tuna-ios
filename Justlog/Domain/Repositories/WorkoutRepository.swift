// Domain/Repositories/WorkoutRepository.swift
import Foundation
import Combine

// MARK: - Sync State
enum SyncState: Equatable {
    case idle
    case checkingCache
    case fetchingNetwork
    case syncingToCache
    case complete(source: String, count: Int)
    case error(String)
}

// MARK: - WorkoutRepository Protocol
protocol WorkoutRepository {
    
    // MARK: - Sync Progress
    var syncProgress: AnyPublisher<SyncState, Never> { get }
    
    // MARK: - Exercise Methods
    func getExercises() async throws -> AnyPublisher<[Exercise], Error>
    func searchExercises(query: String) -> AnyPublisher<[Exercise], Error>
    func createCustomExercise(_ exercise: Exercise) async throws
    
    // MARK: - Workout Methods
    func getWorkouts(userId: String) async throws -> AnyPublisher<[Workout], Error>
    func getWorkoutById(_ workoutId: String) async throws -> Workout?
    func createWorkout(_ workout: Workout) async throws
    func updateWorkout(_ workout: Workout) async throws
    func deleteWorkout(_ workoutId: String) async throws
    func updateWorkoutColor(workoutId: String, colorHex: String) async throws
    func updateWorkoutLastPerformed(routineId: String, lastPerformed: Date) async throws
    
    // MARK: - Statistics
    func getWorkoutCount(userId: String) async throws -> Int
    func getCustomExerciseCount(userId: String) async throws -> Int
    
    // MARK: - Calendar and Suggestions
    func getWeeklyCalendar() -> AnyPublisher<[WeeklyCalendarDay], Error>
    func getSuggestedNextWorkout() -> AnyPublisher<Workout?, Error>
    
    // MARK: - Cleanup
    func onCleared()
}

// MARK: - Repository Error Types
enum RepositoryError: LocalizedError {
    case userNotAuthenticated
    case unauthorized(String)
    case networkError(String)
    case dataCorruption
    case documentNotFound
    case firestoreError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .unauthorized(let message):
            return "Unauthorized: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .dataCorruption:
            return "Data corruption detected"
        case .documentNotFound:
            return "Document not found"
        case .firestoreError(let message):
            return "Firestore error: \(message)"
        }
    }
}
