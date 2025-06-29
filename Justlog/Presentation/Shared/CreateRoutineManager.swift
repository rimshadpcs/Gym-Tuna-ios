//
//  CreateRoutineManager.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 29/06/2025.
//

import Foundation
import Combine

@MainActor
class CreateRoutineManager: ObservableObject {
    private var addExerciseFunction: ((Exercise) -> Void)?
    
    func setAddExerciseFunction(_ function: @escaping (Exercise) -> Void) {
        print("🏪 CreateRoutineManager: Setting addExercise function")
        self.addExerciseFunction = function
    }
    
    func addExercise(_ exercise: Exercise) {
        print("🎯 CreateRoutineManager: Calling addExercise function for: \(exercise.name)")
        addExerciseFunction?(exercise)
    }
    
    func clearFunction() {
        print("🧹 CreateRoutineManager: Clearing addExercise function")
        self.addExerciseFunction = nil
    }
}