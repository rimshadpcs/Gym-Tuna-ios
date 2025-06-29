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
    
    func selectExercise(_ exercise: Exercise) {
        print("🎯 ExerciseSelectionManager: Exercise selected: \(exercise.name)")
        selectedExercise = exercise
    }
    
    func clearSelection() {
        print("🧹 ExerciseSelectionManager: Clearing selection")
        selectedExercise = nil
    }
}