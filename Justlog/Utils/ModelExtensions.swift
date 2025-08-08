// Utils/ModelExtensions.swift
import Foundation
import SwiftUI

// MARK: - Debug Extensions
extension WorkoutSessionState: CustomStringConvertible {
    var description: String {
        return "WorkoutSessionState(routineId='\(routineId ?? "nil")', routineName='\(routineName)', " +
               "exercises=\(exercises.count), startTime=\(startTime), isActive=\(isActive), " +
               "currentExercise='\(currentExercise ?? "nil")', completedSets=\(completedSets))"
    }
}

// MARK: - String Extensions
extension String {
    func normalizeForSearch() -> String {
        return self.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }
    
    func toCamelId() -> String {
        return self.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    }
}

// MARK: - Color Extensions
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var hexString: String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// MARK: - Exercise Extensions
extension Exercise {
    func matchesFlexibleSearch(query: String) -> Bool {
        let normalizedQuery = query.normalizeForSearch()
        return name.normalizeForSearch().contains(normalizedQuery) ||
               equipment.normalizeForSearch().contains(normalizedQuery) ||
               muscleGroup.normalizeForSearch().contains(normalizedQuery)
    }
    
    func copyWith(
        id: String? = nil,
        name: String? = nil,
        muscleGroup: String? = nil,
        equipment: String? = nil,
        defaultReps: Int? = nil,
        defaultSets: Int? = nil,
        isBodyweight: Bool? = nil,
        usesWeight: Bool? = nil,
        tracksDistance: Bool? = nil,
        isTimeBased: Bool? = nil,
        description: String? = nil,
        isSuperset: Bool? = nil,
        isDropset: Bool? = nil
    ) -> Exercise {
        return Exercise(
            id: id ?? self.id,
            name: name ?? self.name,
            muscleGroup: muscleGroup ?? self.muscleGroup,
            equipment: equipment ?? self.equipment,
            defaultReps: defaultReps ?? self.defaultReps,
            defaultSets: defaultSets ?? self.defaultSets,
            isBodyweight: isBodyweight ?? self.isBodyweight,
            usesWeight: usesWeight ?? self.usesWeight,
            tracksDistance: tracksDistance ?? self.tracksDistance,
            isTimeBased: isTimeBased ?? self.isTimeBased,
            description: description ?? self.description ?? "",
            isSuperset: isSuperset ?? self.isSuperset,
            isDropset: isDropset ?? self.isDropset
        )
    }
}

// MARK: - Array Extensions
extension Array where Element == Exercise {
    func groupedByMuscleGroup() -> [String: [Exercise]] {
        return Dictionary(grouping: self) { $0.muscleGroup }
    }
}

// MARK: - Double Extensions
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    var formattedWeight: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.1f", self)
        }
    }
}

// MARK: - Int Extensions  
extension Int {
    var formattedTime: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
