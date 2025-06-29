// Utils/ModelExtensions.swift
import Foundation

// MARK: - Debug Extensions
extension WorkoutSessionState: CustomStringConvertible {
    var description: String {
        return "WorkoutSessionState(routineId='\(routineId ?? "nil")', routineName='\(routineName)', " +
               "exercises=\(exercises.count), startTime=\(startTime), isActive=\(isActive), " +
               "currentExercise='\(currentExercise ?? "nil")', completedSets=\(completedSets))"
    }
}
