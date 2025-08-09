import SwiftUI

// Base Colors (matching Android exactly)
struct ThemeColors {
    static let white = Color(red: 1.0, green: 1.0, blue: 1.0)           // 0xFFFFFFFF
    static let black = Color(red: 0.0, green: 0.0, blue: 0.0)           // 0xFF000000
    static let lightGray = Color(red: 0.961, green: 0.961, blue: 0.961) // 0xFFF5F5F5
    static let mediumGray = Color(red: 0.878, green: 0.878, blue: 0.878) // 0xFFE0E0E0
    static let darkGray = Color(red: 0.459, green: 0.459, blue: 0.459)   // 0xFF757575
    static let neutralColor = Color(red: 0.965, green: 0.945, blue: 0.922) // 0xFFF6F1EB - Sand color for neutral theme
    
    // Dark Theme Colors (matching Android)
    static let darkSurface = Color(red: 0.071, green: 0.071, blue: 0.071) // 0xFF121212
    static let darkBackground = Color(red: 0.0, green: 0.0, blue: 0.0)     // 0xFF000000
    static let darkOnSurface = Color(red: 1.0, green: 1.0, blue: 1.0)      // 0xFFFFFFFF
    static let darkOutline = Color.white.opacity(0.3)                      // 30% opacity white (0x4DFFFFFF)
    
    // Additional dark theme colors
    static let darkSurfaceVariant = Color(red: 0.118, green: 0.118, blue: 0.118) // 0xFF1E1E1E
    static let darkOnSurfaceVariant = Color(red: 0.69, green: 0.69, blue: 0.69) // 0xFFB0B0B0
    static let darkPrimaryContainer = Color(red: 0.173, green: 0.173, blue: 0.173) // 0xFF2C2C2C
    static let darkSecondaryContainer = Color(red: 0.173, green: 0.173, blue: 0.173).opacity(0.2) // 0xFF2C2C2C with 20% alpha
}

// Light Theme Color Scheme
struct LightThemeColors {
    static let primary = ThemeColors.black
    static let onPrimary = ThemeColors.white
    static let secondary = ThemeColors.black
    static let onSecondary = ThemeColors.white
    static let background = ThemeColors.white
    static let onBackground = ThemeColors.black
    static let surface = ThemeColors.white
    static let onSurface = ThemeColors.black
    static let surfaceVariant = ThemeColors.lightGray
    static let onSurfaceVariant = ThemeColors.darkGray
    static let outline = ThemeColors.black
    static let primaryContainer = ThemeColors.lightGray
    static let onPrimaryContainer = ThemeColors.black
    static let error = Color.red
    static let shadow = ThemeColors.black.opacity(0.2)
}

// Neutral Theme Color Scheme
struct NeutralThemeColors {
    static let primary = ThemeColors.black
    static let onPrimary = ThemeColors.white
    static let secondary = ThemeColors.black
    static let onSecondary = ThemeColors.white
    static let background = ThemeColors.neutralColor
    static let onBackground = ThemeColors.black
    static let surface = ThemeColors.neutralColor
    static let onSurface = ThemeColors.black
    static let surfaceVariant = ThemeColors.lightGray
    static let onSurfaceVariant = ThemeColors.darkGray
    static let outline = ThemeColors.black
    static let primaryContainer = ThemeColors.lightGray
    static let onPrimaryContainer = ThemeColors.black
    static let error = Color.red
    static let shadow = ThemeColors.black.opacity(0.2)
}

// Dark Theme Color Scheme (exactly matching Android DarkColorScheme)
struct DarkThemeColors {
    static let primary = ThemeColors.white              // Changed from Teal200 to White
    static let onPrimary = ThemeColors.black
    static let secondary = ThemeColors.white            // Changed from Teal200 to White
    static let onSecondary = ThemeColors.black
    static let background = ThemeColors.darkBackground
    static let onBackground = ThemeColors.white
    static let surface = ThemeColors.darkSurface
    static let onSurface = ThemeColors.white
    static let outline = ThemeColors.white
    static let surfaceVariant = ThemeColors.darkSurfaceVariant     // 0xFF1E1E1E
    static let onSurfaceVariant = ThemeColors.darkOnSurfaceVariant // 0xFFB0B0B0
    static let primaryContainer = ThemeColors.darkPrimaryContainer // 0xFF2C2C2C
    static let onPrimaryContainer = ThemeColors.white
    static let secondaryContainer = ThemeColors.darkSecondaryContainer // 0xFF2C2C2C with 20% alpha
    static let onSecondaryContainer = ThemeColors.white            // Changed from Teal200 to White
    static let error = Color.red
    static let shadow = ThemeColors.black.opacity(0.5)
}

