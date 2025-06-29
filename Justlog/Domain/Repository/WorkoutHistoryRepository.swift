//
//  WorkoutHistoryRepository.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation
import Combine

protocol WorkoutHistoryRepository {
    
    /// Save a completed workout to history
    func saveWorkoutHistory(_ workoutHistory: WorkoutHistory) async throws
    
    /// Get all workout history for a user, ordered by start time (most recent first)
    func getWorkoutHistory(userId: String) -> AnyPublisher<[WorkoutHistory], Error>
    
    /// Get workout history for a specific month
    func getMonthlyHistory(
        userId: String,
        monthStart: Date,
        timeZone: TimeZone
    ) -> AnyPublisher<[WorkoutHistory], Error>
    
    /// Update routine name in all historical workouts that used this routine
    func updateRoutineNameInHistory(
        userId: String,
        routineId: String,
        newName: String
    ) async throws
}