//
//  Workout.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation

struct Workout: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let userId: String
    let exercises: [WorkoutExercise]
    let createdAt: Date
    let colorHex: String?
    let lastPerformed: Date?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        userId: String,
        exercises: [WorkoutExercise] = [],
        createdAt: Date = Date(),
        colorHex: String? = nil,
        lastPerformed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.userId = userId
        self.exercises = exercises
        self.createdAt = createdAt
        self.colorHex = colorHex
        self.lastPerformed = lastPerformed
    }
}
