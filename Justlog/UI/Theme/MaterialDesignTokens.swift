import SwiftUI

// MARK: - Material Design Spacing System
struct MaterialSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    
    // Screen margins (matching Android)
    static let screenHorizontal: CGFloat = 16
    static let screenVertical: CGFloat = 16
    
    // Component spacing
    static let cardPadding: CGFloat = 16
    static let listItemPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
}

// MARK: - Material Design Typography
struct MaterialTypography {
    // Headlines
    static let headline1 = Font.system(size: 96, weight: .light)
    static let headline2 = Font.system(size: 60, weight: .light)
    static let headline3 = Font.system(size: 48, weight: .regular)
    static let headline4 = Font.system(size: 34, weight: .regular)
    static let headline5 = Font.system(size: 24, weight: .regular)
    static let headline6 = Font.system(size: 20, weight: .medium)
    
    // Body text
    static let body1 = Font.system(size: 16, weight: .regular)
    static let body2 = Font.system(size: 14, weight: .regular)
    
    // Buttons
    static let button = Font.system(size: 14, weight: .medium)
    
    // Captions and overlines
    static let caption = Font.system(size: 12, weight: .regular)
    static let overline = Font.system(size: 10, weight: .regular)
    
    // Subtitles
    static let subtitle1 = Font.system(size: 16, weight: .regular)
    static let subtitle2 = Font.system(size: 14, weight: .medium)
}

// MARK: - Material Design Corner Radius
struct MaterialCornerRadius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
    static let extraLarge: CGFloat = 16
    
    // Component specific
    static let button: CGFloat = 8
    static let card: CGFloat = 12
    static let dialog: CGFloat = 16
    static let bottomSheet: CGFloat = 16
}

// MARK: - Material Design Elevation (Shadow) as ViewModifiers
struct MaterialElevationModifier: ViewModifier {
    let level: Int
    
    func body(content: Content) -> some View {
        let shadows: [(opacity: Double, radius: CGFloat, y: CGFloat)] = [
            (0.1, 1, 1),   // Level 1
            (0.15, 2, 1),  // Level 2
            (0.2, 4, 2),   // Level 3
            (0.25, 6, 3),  // Level 4
            (0.3, 8, 4)    // Level 5
        ]
        
        let shadow = shadows[min(max(level - 1, 0), shadows.count - 1)]
        
        return content.shadow(
            color: Color.black.opacity(shadow.opacity),
            radius: shadow.radius,
            x: 0,
            y: shadow.y
        )
    }
}

// MARK: - Material Colors (Dynamic theme-based colors matching Android)
struct MaterialColors {
    // Primary colors - defaults that match your Android light theme
    static let primary = ThemeColors.black
    static let onPrimary = ThemeColors.white
    static let primaryContainer = ThemeColors.lightGray
    static let onPrimaryContainer = ThemeColors.black
    
    // Secondary colors
    static let secondary = ThemeColors.black
    static let onSecondary = ThemeColors.white
    static let secondaryContainer = ThemeColors.lightGray.opacity(0.12)
    static let onSecondaryContainer = ThemeColors.black
    
    // Background colors - default to white (light theme)
    static let background = ThemeColors.white
    static let onBackground = ThemeColors.black
    
    // Surface colors
    static let surface = ThemeColors.white
    static let onSurface = ThemeColors.black
    static let surfaceVariant = ThemeColors.lightGray
    static let onSurfaceVariant = ThemeColors.darkGray
    
    // Error colors (fixed across themes)
    static let error = Color.red
    static let onError = Color.white
    static let errorContainer = Color.red.opacity(0.12)
    static let onErrorContainer = Color.red
    
    // Outline colors
    static let outline = ThemeColors.black
    static let outlineVariant = ThemeColors.black.opacity(0.5)
    
    // Additional Material 3 colors
    static let shadow = Color.black.opacity(0.2)
    static let scrim = Color.black.opacity(0.32)
    static let surfaceTint = primary
    static let inverseSurface = onSurface
    static let inverseOnSurface = surface
    static let inversePrimary = onPrimary
}

// MARK: - Material Design Component Tokens
struct MaterialComponentTokens {
    // Card
    struct Card {
        static let cornerRadius = MaterialCornerRadius.card
        static let padding = MaterialSpacing.cardPadding
    }
    
    // Button
    struct Button {
        static let cornerRadius = MaterialCornerRadius.button
        static let height: CGFloat = 48
        static let minWidth: CGFloat = 64
        static let horizontalPadding = MaterialSpacing.lg
    }
    
    // List Item
    struct ListItem {
        static let height: CGFloat = 72
        static let padding = MaterialSpacing.listItemPadding
        static let avatarSize: CGFloat = 40
    }
}

// MARK: - View Extensions for Material Design
extension View {
    func materialCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: MaterialCornerRadius.card)
                    .fill(MaterialColors.surface)
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
    }
    
    func materialElevation(_ level: Int) -> some View {
        self.modifier(MaterialElevationModifier(level: level))
    }
}