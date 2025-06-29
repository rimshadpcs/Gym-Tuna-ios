//
//  CompletedExercise.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation

struct CompletedSet: Identifiable, Codable, Equatable {
    let id: String
    let setNumber: Int
    let weight: Double
    let reps: Int
    let distance: Double
    let time: Double
    
    init(
        id: String = UUID().uuidString,
        setNumber: Int = 0,
        weight: Double = 0.0,
        reps: Int = 0,
        distance: Double = 0.0,
        time: Double = 0.0
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.distance = distance
        self.time = time
    }
}

struct CompletedExercise: Identifiable, Codable, Equatable {
    let id: String
    let exerciseId: String
    let name: String
    let notes: String
    let muscleGroup: String
    let equipment: String
    let sets: [CompletedSet]
    
    init(
        id: String = UUID().uuidString,
        exerciseId: String = "",
        name: String = "",
        notes: String = "",
        muscleGroup: String = "",
        equipment: String = "",
        sets: [CompletedSet] = []
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.notes = notes
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.sets = sets
    }
}