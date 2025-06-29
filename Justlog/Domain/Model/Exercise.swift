//
//  Exercise.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 29/06/2025.
//

import Foundation

struct Exercise: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let muscleGroup: String  // This will be derived from primaryMuscles[0]
    let primaryMuscles: [String]  // Array from Firestore
    let equipment: String
    let defaultReps: Int
    let defaultSets: Int
    let isBodyweight: Bool
    let usesWeight: Bool
    let tracksDistance: Bool
    let isTimeBased: Bool
    let description: String
    let isSuperset: Bool
    let isDropset: Bool
    
    init(
        id: String = UUID().uuidString,
        name: String,
        muscleGroup: String = "",
        primaryMuscles: [String] = [],
        equipment: String = "",
        defaultReps: Int = 15,
        defaultSets: Int = 3,
        isBodyweight: Bool = false,
        usesWeight: Bool = true,
        tracksDistance: Bool = false,
        isTimeBased: Bool = false,
        description: String = "",
        isSuperset: Bool = false,
        isDropset: Bool = false
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup.isEmpty ? (primaryMuscles.first ?? "") : muscleGroup
        self.primaryMuscles = primaryMuscles
        self.equipment = equipment
        self.defaultReps = defaultReps
        self.defaultSets = defaultSets
        self.isBodyweight = isBodyweight
        self.usesWeight = usesWeight
        self.tracksDistance = tracksDistance
        self.isTimeBased = isTimeBased
        self.description = description
        self.isSuperset = isSuperset
        self.isDropset = isDropset
    }
    
    func isValid() -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Firestore Extensions
extension Exercise {
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "primaryMuscles": primaryMuscles.isEmpty ? [muscleGroup] : primaryMuscles,
            "equipment": equipment,
            "defaultReps": defaultReps,
            "defaultSets": defaultSets,
            "isBodyweight": isBodyweight,
            "usesWeight": usesWeight,
            "tracksDistance": tracksDistance,
            "isTimeBased": isTimeBased,
            "description": description,
            "isSuperset": isSuperset,
            "isDropset": isDropset
        ]
    }
    
    static func fromFirestoreData(_ data: [String: Any]) -> Exercise? {
        guard let name = data["name"] as? String else { return nil }
        
        // Get primaryMuscles array from Firestore
        let primaryMuscles = data["primaryMuscles"] as? [String] ?? []
        
        return Exercise(
            id: data["id"] as? String ?? UUID().uuidString,
            name: name,
            muscleGroup: "", // Will be derived from primaryMuscles in init
            primaryMuscles: primaryMuscles,
            equipment: data["equipment"] as? String ?? "",
            defaultReps: data["defaultReps"] as? Int ?? 15,
            defaultSets: data["defaultSets"] as? Int ?? 3,
            isBodyweight: data["isBodyweight"] as? Bool ?? false,
            usesWeight: data["usesWeight"] as? Bool ?? true,
            tracksDistance: data["tracksDistance"] as? Bool ?? false,
            isTimeBased: data["isTimeBased"] as? Bool ?? false,
            description: data["description"] as? String ?? "",
            isSuperset: data["isSuperset"] as? Bool ?? false,
            isDropset: data["isDropset"] as? Bool ?? false
        )
    }
}

// MARK: - Sample Data
extension Exercise {
    static let sampleExercises: [Exercise] = [
        Exercise(
            name: "Push-ups",
            primaryMuscles: ["chest"],
            equipment: "Body Weight",
            isBodyweight: true,
            usesWeight: false
        ),
        Exercise(
            name: "Barbell Bench Press",
            primaryMuscles: ["chest"],
            equipment: "Barbell"
        ),
        Exercise(
            name: "Squats",
            primaryMuscles: ["legs"],
            equipment: "Barbell"
        ),
        Exercise(
            name: "Deadlift",
            primaryMuscles: ["back"],
            equipment: "Barbell"
        ),
        Exercise(
            name: "Pull-ups",
            primaryMuscles: ["back"],
            equipment: "Body Weight",
            isBodyweight: true,
            usesWeight: false
        )
    ]
}