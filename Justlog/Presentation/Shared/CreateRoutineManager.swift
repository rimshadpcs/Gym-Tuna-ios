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
    private var addExerciseToWorkoutFunction: ((Exercise) -> Void)?
    
    func setAddExerciseFunction(_ function: @escaping (Exercise) -> Void) {
        print("🏪 CreateRoutineManager: Setting addExercise function for routine creation")
        self.addExerciseFunction = function
    }
    
    func setAddExerciseToWorkoutFunction(_ function: @escaping (Exercise) -> Void) {
        print("🏋️ CreateRoutineManager: Setting addExercise function for active workout")
        self.addExerciseToWorkoutFunction = function
    }
    
    func addExercise(_ exercise: Exercise) {
        print("🎯 CreateRoutineManager: Calling addExercise function for routine: \(exercise.name)")
        addExerciseFunction?(exercise)
    }
    
    func addExerciseToWorkout(_ exercise: Exercise) {
        print("🎯 CreateRoutineManager: Calling addExercise function for workout: \(exercise.name)")
        addExerciseToWorkoutFunction?(exercise)
    }
    
    func clearFunction() {
        print("🧹 CreateRoutineManager: Clearing routine addExercise function")
        self.addExerciseFunction = nil
    }
    
    func clearWorkoutFunction() {
        print("🧹 CreateRoutineManager: Clearing workout addExercise function") 
        self.addExerciseToWorkoutFunction = nil
    }
    
    var hasActiveWorkoutFunction: Bool {
        return addExerciseToWorkoutFunction != nil
    }
}