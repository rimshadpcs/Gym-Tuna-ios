//
//  WorkoutHistory.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation

struct WorkoutHistory: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let startTime: Date
    let endTime: Date
    let exercises: [CompletedExercise]
    let totalVolume: Double
    let totalSets: Int
    let colorHex: String
    let routineId: String?
    let userId: String
    let exerciseIds: [String]
    
    init(
        id: String = UUID().uuidString,
        name: String = "",
        startTime: Date = Date(),
        endTime: Date = Date(),
        exercises: [CompletedExercise] = [],
        totalVolume: Double = 0.0,
        totalSets: Int = 0,
        colorHex: String = "",
        routineId: String? = nil,
        userId: String = "",
        exerciseIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.exercises = exercises
        self.totalVolume = totalVolume
        self.totalSets = totalSets
        self.colorHex = colorHex
        self.routineId = routineId
        self.userId = userId
        self.exerciseIds = exerciseIds
    }
    
    // MARK: - Computed Properties
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let interval = Int(duration)
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}

// MARK: - Firestore Encoding/Decoding

extension WorkoutHistory {
    
    // Convert to Firestore-compatible dictionary
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "name": name,
            "startTime": startTime.timeIntervalSince1970 * 1000, // Convert to milliseconds
            "endTime": endTime.timeIntervalSince1970 * 1000,
            "exerciseIds": exerciseIds,
            "exercises": exercises.map { exercise in
                [
                    "exerciseId": exercise.exerciseId,
                    "name": exercise.name,
                    "notes": exercise.notes,
                    "muscleGroup": exercise.muscleGroup,
                    "equipment": exercise.equipment,
                    "sets": exercise.sets.map { set in
                        [
                            "setNumber": set.setNumber,
                            "weight": set.weight,
                            "reps": set.reps,
                            "distance": set.distance,
                            "time": set.time
                        ]
                    }
                ]
            },
            "totalVolume": totalVolume,
            "totalSets": totalSets,
            "colorHex": colorHex,
            "routineId": routineId ?? NSNull()
        ]
    }
    
    // Create from Firestore dictionary
    static func fromFirestoreData(_ data: [String: Any]) -> WorkoutHistory? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let startTimeMs = data["startTime"] as? Double,
              let endTimeMs = data["endTime"] as? Double else {
            return nil
        }
        
        let startTime = Date(timeIntervalSince1970: startTimeMs / 1000) // Convert from milliseconds
        let endTime = Date(timeIntervalSince1970: endTimeMs / 1000)
        
        let exerciseIds = data["exerciseIds"] as? [String] ?? []
        let totalVolume = data["totalVolume"] as? Double ?? 0.0
        let totalSets = data["totalSets"] as? Int ?? 0
        let colorHex = data["colorHex"] as? String ?? ""
        let routineId = data["routineId"] as? String
        
        // Parse exercises
        var exercises: [CompletedExercise] = []
        if let exercisesData = data["exercises"] as? [[String: Any]] {
            exercises = exercisesData.compactMap { exerciseData in
                guard let exerciseId = exerciseData["exerciseId"] as? String,
                      let exerciseName = exerciseData["name"] as? String else {
                    return nil
                }
                
                let notes = exerciseData["notes"] as? String ?? ""
                let muscleGroup = exerciseData["muscleGroup"] as? String ?? ""
                let equipment = exerciseData["equipment"] as? String ?? ""
                
                // Parse sets
                var sets: [CompletedSet] = []
                if let setsData = exerciseData["sets"] as? [[String: Any]] {
                    sets = setsData.compactMap { setData in
                        let setNumber = setData["setNumber"] as? Int ?? 0
                        let weight = setData["weight"] as? Double ?? 0.0
                        let reps = setData["reps"] as? Int ?? 0
                        let distance = setData["distance"] as? Double ?? 0.0
                        let time = setData["time"] as? Double ?? 0.0
                        
                        return CompletedSet(
                            setNumber: setNumber,
                            weight: weight,
                            reps: reps,
                            distance: distance,
                            time: time
                        )
                    }
                }
                
                return CompletedExercise(
                    exerciseId: exerciseId,
                    name: exerciseName,
                    notes: notes,
                    muscleGroup: muscleGroup,
                    equipment: equipment,
                    sets: sets
                )
            }
        }
        
        return WorkoutHistory(
            id: id,
            name: name,
            startTime: startTime,
            endTime: endTime,
            exercises: exercises,
            totalVolume: totalVolume,
            totalSets: totalSets,
            colorHex: colorHex,
            routineId: routineId,
            userId: userId,
            exerciseIds: exerciseIds
        )
    }
}