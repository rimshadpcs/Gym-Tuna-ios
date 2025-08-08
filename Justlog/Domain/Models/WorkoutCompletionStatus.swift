import Foundation

struct WorkoutCompletionStatus {
    let totalExercises: Int
    let completedExercises: [ExerciseCompletionInfo]
    let incompleteExercises: [ExerciseCompletionInfo]
    let totalSets: Int
    let completedSets: Int
    let isFullyCompleted: Bool
}

struct ExerciseCompletionInfo {
    let exerciseName: String
    let totalSets: Int
    let completedSets: Int
    let isFullyCompleted: Bool
}