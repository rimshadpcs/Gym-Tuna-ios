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
    private var isReplacementMode: Bool = false
    
    private init() {}
    
    func sendExercise(_ exercise: Exercise, isReplacement: Bool = false) {
        print("📤 ExerciseChannel: Sending exercise: \(exercise.name) (ID: '\(exercise.id)') - Replacement: \(isReplacement)")
        print("📤 Previous pending exercise: \(pendingExercise?.name ?? "nil")")
        pendingExercise = exercise
        isReplacementMode = isReplacement
        print("📤 Exercise sent successfully")
    }
    
    func consumeExercise() -> (exercise: Exercise?, isReplacement: Bool) {
        let exercise = pendingExercise
        let isReplacement = isReplacementMode
        print("📥 ExerciseChannel: Consuming exercise: \(exercise?.name ?? "nil") (ID: '\(exercise?.id ?? "nil")') - Replacement: \(isReplacement)")
        pendingExercise = nil
        isReplacementMode = false
        print("📥 Exercise consumed, channel cleared")
        return (exercise, isReplacement)
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
        isReplacementMode = false
    }
    
    func isInReplacementMode() -> Bool {
        return isReplacementMode
    }
}