//
//  WorkoutExercise.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation

struct WorkoutExercise: Codable, Equatable {
    let exercise: Exercise
    let sets: [ExerciseSet]
    let notes: String
    let isSuperset: Bool
    let supersetGroup: Int?
    let isDropset: Bool
    
    init(
        exercise: Exercise,
        sets: [ExerciseSet] = [],
        notes: String = "",
        isSuperset: Bool = false,
        supersetGroup: Int? = nil,
        isDropset: Bool = false
    ) {
        self.exercise = exercise
        self.sets = sets
        self.notes = notes
        self.isSuperset = isSuperset
        self.supersetGroup = supersetGroup
        self.isDropset = isDropset
    }
}