//
//  ExerciseSelectionManager.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 29/06/2025.
//

import Foundation
import Combine

@MainActor
class ExerciseSelectionManager: ObservableObject {
    @Published var selectedExercise: Exercise? = nil
    private var lastProcessedExerciseId: String? = nil
    
    func selectExercise(_ exercise: Exercise) {
        print("🎯 ExerciseSelectionManager: Exercise selected: \(exercise.name)")
        selectedExercise = exercise
    }
    
    func clearSelection() {
        print("🧹 ExerciseSelectionManager: Clearing selection")
        // Don't set to nil immediately, just mark as processed
        if let exercise = selectedExercise {
            lastProcessedExerciseId = exercise.id
        }
        selectedExercise = nil
    }
    
    func isNewSelection(_ exercise: Exercise) -> Bool {
        return exercise.id != lastProcessedExerciseId
    }
}