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
        print("📤 ExerciseChannel: Sending exercise: \(exercise.name) (ID: '\(exercise.id)')")
        print("📤 Previous pending exercise: \(pendingExercise?.name ?? "nil")")
        pendingExercise = exercise
        print("📤 Exercise sent successfully")
    }
    
    func consumeExercise() -> Exercise? {
        let exercise = pendingExercise
        print("📥 ExerciseChannel: Consuming exercise: \(exercise?.name ?? "nil") (ID: '\(exercise?.id ?? "nil")')")
        pendingExercise = nil
        print("📥 Exercise consumed, channel cleared")
        return exercise
    }
    
    func hasPendingExercise() -> Bool {
        let hasPending = pendingExercise != nil
        print("🔍 ExerciseChannel: hasPendingExercise() -> \(hasPending)")
        if hasPending {
            print("🔍 Pending exercise: \(pendingExercise?.name ?? "unknown")")
        }
        return hasPending
    }
    
    func clearPendingExercise() {
        print("🧹 ExerciseChannel: Clearing pending exercise")
        pendingExercise = nil
    }
}