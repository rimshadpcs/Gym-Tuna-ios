import SwiftUI
import Foundation

extension Color {
    // Custom color extensions
    static let primaryBackground = Color("PrimaryBackground")
    static let secondaryBackground = Color("SecondaryBackground")
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let accent = Color("AccentColor")
    
    // Theme detection helper
    static var isLight: Bool {
        return UITraitCollection.current.userInterfaceStyle == .light
    }
    
}

// Color scheme detection
extension ColorScheme {
    var isLight: Bool {
        return self == .light
    }
}

// Environment extension for theme detection
extension EnvironmentValues {
    var isLightTheme: Bool {
        return colorScheme == .light
    }
}