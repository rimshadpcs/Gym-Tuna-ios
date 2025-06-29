//
//  ExerciseSet.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation

struct ExerciseSet: Codable, Equatable {
    let setNumber: Int
    let weight: Double
    let reps: Int
    let distance: Double
    let time: Int
    let isCompleted: Bool
    
    // Previous workout data for reference
    let previousReps: Int?
    let previousWeight: Double?
    let previousDistance: Double?
    let previousTime: Int?
    
    // Best performance tracking (for workout session only)
    let bestReps: Int?
    let bestWeight: Double?
    let bestDistance: Double?
    let bestTime: Int?
    
    init(
        setNumber: Int = 0,
        weight: Double = 0.0,
        reps: Int = 0,
        distance: Double = 0.0,
        time: Int = 0,
        isCompleted: Bool = false,
        previousReps: Int? = nil,
        previousWeight: Double? = nil,
        previousDistance: Double? = nil,
        previousTime: Int? = nil,
        bestReps: Int? = nil,
        bestWeight: Double? = nil,
        bestDistance: Double? = nil,
        bestTime: Int? = nil
    ) {
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.distance = distance
        self.time = time
        self.isCompleted = isCompleted
        self.previousReps = previousReps
        self.previousWeight = previousWeight
        self.previousDistance = previousDistance
        self.previousTime = previousTime
        self.bestReps = bestReps
        self.bestWeight = bestWeight
        self.bestDistance = bestDistance
        self.bestTime = bestTime
    }
    
    // MARK: - Helper Functions for UI Display
    func hasPrevious() -> Bool {
        return (previousWeight != nil && previousReps != nil) ||
               previousDistance != nil || previousTime != nil
    }
    
    func getPreviousDisplay() -> String {
        switch (previousWeight, previousReps, previousDistance, previousTime) {
        case let (weight?, reps?, _, _):
            return "\(weight) x \(reps)"
        case let (_, _, distance?, _):
            return "\(distance) mi"
        case let (_, _, _, time?):
            return formatTimeDisplay(seconds: time)
        default:
            return "-"
        }
    }
    
    private func formatTimeDisplay(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", remainingSeconds))"
        } else {
            return "\(remainingSeconds) s"
        }
    }
}