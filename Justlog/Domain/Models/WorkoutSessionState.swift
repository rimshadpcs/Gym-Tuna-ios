//
//  WorkoutSessionState.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation

struct WorkoutSessionState: Codable, Equatable {
    let routineId: String?
    let routineName: String
    let exercises: [WorkoutExercise]
    let startTime: Date
    let isActive: Bool
    let currentExercise: String?
    let pausedAt: Date?
    let completedSets: Int
    
    init(
        routineId: String? = nil,
        routineName: String = "",
        exercises: [WorkoutExercise] = [],
        startTime: Date = Date(),
        isActive: Bool = false,
        currentExercise: String? = nil,
        pausedAt: Date? = nil,
        completedSets: Int = 0
    ) {
        self.routineId = routineId
        self.routineName = routineName
        self.exercises = exercises
        self.startTime = startTime
        self.isActive = isActive
        self.currentExercise = currentExercise
        self.pausedAt = pausedAt
        self.completedSets = completedSets
    }
}