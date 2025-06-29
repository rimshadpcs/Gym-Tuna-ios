//
//  RoutineColors.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation
import SwiftUI

struct ColorOption: Identifiable, Codable, Equatable {
    let id: String
    let hex: String
    let name: String
    
    init(hex: String, name: String) {
        self.id = UUID().uuidString
        self.hex = hex
        self.name = name
    }
    
    var color: Color {
        return Color(hex: hex) ?? .blue
    }
}

class RoutineColors {
    
    static let colorOptions: [ColorOption] = [
        ColorOption(hex: "#6B9CD6", name: "Blue"),
        ColorOption(hex: "#D67676", name: "Red"),
        ColorOption(hex: "#76D6A8", name: "Green"),
        ColorOption(hex: "#B576D6", name: "Purple"),
        ColorOption(hex: "#D6CF76", name: "Yellow"),
        ColorOption(hex: "#D676B5", name: "Pink"),
        ColorOption(hex: "#76C6D6", name: "Cyan"),
        ColorOption(hex: "#D6A876", name: "Orange"),
        ColorOption(hex: "#8FD676", name: "Lime"),
        ColorOption(hex: "#D69976", name: "Coral"),
        ColorOption(hex: "#76D6D6", name: "Teal")
    ]
    
    static func byIndex(_ index: Int) -> String {
        let safeIndex = index % colorOptions.count
        return colorOptions[safeIndex].hex
    }
    
    static func getColorOption(byIndex index: Int) -> ColorOption {
        let safeIndex = index % colorOptions.count
        return colorOptions[safeIndex]
    }
    
    static func getRandomColor() -> ColorOption {
        return colorOptions.randomElement() ?? colorOptions[0]
    }
    
    static func getColorByHex(_ hex: String) -> ColorOption? {
        return colorOptions.first { $0.hex.lowercased() == hex.lowercased() }
    }
}