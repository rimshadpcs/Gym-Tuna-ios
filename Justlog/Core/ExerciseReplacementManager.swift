//
//  ExerciseReplacementManager.swift
//  Justlog
//
//  Created by Claude on 08/12/2025.
//

import Foundation

@MainActor
class ExerciseReplacementManager: ObservableObject {
    static let shared = ExerciseReplacementManager()
    
    @Published var exerciseToReplace: WorkoutExercise? = nil
    @Published var isReplacementMode: Bool = false
    
    private init() {}
    
    func startReplacement(for exercise: WorkoutExercise) {
        print("🔄 ExerciseReplacementManager: Starting replacement for \(exercise.exercise.name)")
        exerciseToReplace = exercise
        isReplacementMode = true
    }
    
    func completeReplacement() -> WorkoutExercise? {
        print("🔄 ExerciseReplacementManager: Completing replacement for \(exerciseToReplace?.exercise.name ?? "nil")")
        let exerciseToReturn = exerciseToReplace
        exerciseToReplace = nil
        isReplacementMode = false
        return exerciseToReturn
    }
    
    func cancelReplacement() {
        print("🔄 ExerciseReplacementManager: Canceling replacement")
        exerciseToReplace = nil
        isReplacementMode = false
    }
}