//
//  MuscleGroupIcons.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import Foundation
import SwiftUI

extension String {
    func getMuscleGroupIcon(isDarkTheme: Bool) -> String {
        let normalizedMuscleGroup = self.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let muscleGroupMap: [String: (light: String, dark: String)] = [
            // Chest variations
            "chest": ("chest", "chest_dark"),
            "pectorals": ("chest", "chest_dark"),
            "pecs": ("chest", "chest_dark"),
            
            // Back variations
            "back": ("back", "back_dark"),
            "middle back": ("back", "back_dark"),
            "lower back": ("back", "back_dark"),
            "upper back": ("back", "back_dark"),
            "lats": ("back", "back_dark"),
            "latissimus dorsi": ("back", "back_dark"),
            "rhomboids": ("back", "back_dark"),
            
            // Legs variations
            "legs": ("leg", "leg_dark"),
            "quads": ("leg", "leg_dark"),
            "quadriceps": ("leg", "leg_dark"),
            "hamstrings": ("leg", "leg_dark"),
            "adductors": ("leg", "leg_dark"),
            "hip flexors": ("leg", "leg_dark"),
            "thighs": ("leg", "leg_dark"),
            
            // Shoulders variations
            "shoulders": ("shoulders", "shoulders_dark"),
            "shoulder": ("shoulders", "shoulders_dark"),
            "delts": ("shoulders", "shoulders_dark"),
            "deltoids": ("shoulders", "shoulders_dark"),
            "traps": ("shoulders", "shoulders_dark"),
            "trapezius": ("shoulders", "shoulders_dark"),
            "neck": ("shoulders", "shoulders_dark"),
            
            // Arms - Biceps variations
            "biceps": ("biceps", "biceps_dark"),
            "bicep": ("biceps", "biceps_dark"),
            "arms": ("biceps", "biceps_dark"),
            "arm": ("biceps", "biceps_dark"),
            
            // Arms - Triceps variations
            "triceps": ("triceps", "triceps_dark"),
            "tricep": ("triceps", "triceps_dark"),
            
            // Core/Abs variations
            "core": ("core", "core_dark"),
            "abs": ("core", "core_dark"),
            "abdominals": ("core", "core_dark"),
            "obliques": ("core", "core_dark"),
            
            // Calves variations
            "calves": ("calves", "calves_dark"),
            "calf": ("calves", "calves_dark"),
            
            // Forearms variations
            "forearms": ("forearms", "forearms_dark"),
            "forearm": ("forearms", "forearms_dark"),
            
            // Glutes variations
            "glutes": ("glutes", "glutes_dark"),
            "glute": ("glutes", "glutes_dark"),
            "gluteus": ("glutes", "glutes_dark"),
            "butt": ("glutes", "glutes_dark"),
            
            // Full body variations
            "full body": ("fullbody", "fullbody_dark"),
            "fullbody": ("fullbody", "fullbody_dark"),
            "cardio": ("fullbody", "fullbody_dark"),
            "compound": ("fullbody", "fullbody_dark")
        ]
        
        let iconPair = muscleGroupMap[normalizedMuscleGroup] ?? ("fullbody", "fullbody_dark")
        return isDarkTheme ? iconPair.dark : iconPair.light
    }
}

// Formatting helpers to match Android
extension Double {
    func formatWeight() -> String {
        if self == Double(Int(self)) {
            return String(Int(self))
        } else {
            let formatted = String(format: "%.2f", self)
            return formatted.replacingOccurrences(of: "(\\.?0+)$", with: "", options: .regularExpression)
        }
    }
    
    func removeTrailingZeros() -> String {
        if self == Double(Int(self)) {
            return String(Int(self))
        } else {
            return String(self)
        }
    }
}

func buildDisplayString(
    weight: Double? = nil,
    reps: Int? = nil,
    distance: Double? = nil,
    time: Int? = nil,
    weightUnit: WeightUnit,
    distanceUnit: DistanceUnit,
    showUnits: Bool = false
) -> String {
    var parts: [String] = []
    
    if let weight = weight, weight > 0 {
        let convertedWeight = weightUnit == .kg ? weight : WeightConverter.kgToLbs(weight)
        let w = convertedWeight.formatWeight()
        parts.append(showUnits ? "\(w) \(weightUnit == .kg ? "kg" : "lb")" : w)
    }
    
    if let distance = distance, distance > 0 {
        let d = distance.removeTrailingZeros()
        parts.append(showUnits ? "\(d) \(distanceUnit == .km ? "km" : "mi")" : d)
    }
    
    if let time = time, time > 0 {
        parts.append(showUnits ? "\(time)s" : String(time))
    }
    
    if let reps = reps, reps > 0 && (time == nil || time == 0) {
        parts.append(String(reps))
    }
    
    return parts.isEmpty ? "-" : parts.joined(separator: " x ")
}

func formatVolumeWithUnit(_ volumeInKg: Double, _ weightUnit: WeightUnit) -> String {
    let converted = weightUnit == .kg ? volumeInKg : WeightConverter.kgToLbs(volumeInKg)
    let unitLabel = weightUnit == .kg ? "kg" : "lb"
    
    if converted == Double(Int(converted)) {
        return "\(Int(converted)) \(unitLabel)"
    } else {
        let formatted = String(format: "%.1f", converted).replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
        return "\(formatted) \(unitLabel)"
    }
}

enum WeightUnit: String, CaseIterable {
    case kg = "KG"
    case lb = "LB"
}

enum DistanceUnit: String, CaseIterable {
    case km = "KM"
    case mi = "MI"
}

class WeightConverter {
    static func kgToLbs(_ kg: Double) -> Double {
        return kg * 2.20462
    }
    
    static func lbsToKg(_ lbs: Double) -> Double {
        return lbs / 2.20462
    }
}

class DistanceConverter {
    static func kmToMiles(_ km: Double) -> Double {
        return km * 0.621371
    }
    
    static func milesToKm(_ miles: Double) -> Double {
        return miles / 0.621371
    }
}