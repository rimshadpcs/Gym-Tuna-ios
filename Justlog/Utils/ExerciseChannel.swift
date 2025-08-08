//
//  ExerciseChannel.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 08/08/2025.
//

import Foundation

/// Simple channel to pass exercises between screens
/// Similar to the Kotlin ExerciseChannel pattern
class ExerciseChannel {
    static let shared = ExerciseChannel()
    
    private var pendingExercise: Exercise?
    
    private init() {}
    
    func sendExercise(_ exercise: Exercise) {
        print("📤 ExerciseChannel: Sending exercise: \(exercise.name)")
        pendingExercise = exercise
    }
    
    func consumeExercise() -> Exercise? {
        let exercise = pendingExercise
        pendingExercise = nil
        if let exercise = exercise {
            print("📥 ExerciseChannel: Consuming exercise: \(exercise.name)")
        }
        return exercise
    }
    
    func hasPendingExercise() -> Bool {
        return pendingExercise != nil
    }
    
    func clearPendingExercise() {
        print("🧹 ExerciseChannel: Clearing pending exercise")
        pendingExercise = nil
    }
}