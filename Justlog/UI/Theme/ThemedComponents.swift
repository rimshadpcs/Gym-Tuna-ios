import SwiftUI

// Environment key for theme manager
private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager? = nil
}

extension EnvironmentValues {
    var themeManager: ThemeManager? {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// JustlogTheme wrapper that mimics your Android GymLogTheme
struct JustlogTheme<Content: View>: View {
    let content: Content
    @StateObject private var themeManager: ThemeManager
    
    init(theme: AppTheme = .neutral, userPreferences: UserPreferences, @ViewBuilder content: () -> Content) {
        self.content = content()
        self._themeManager = StateObject(wrappedValue: ThemeManager(userPreferences: userPreferences))
    }
    
    var body: some View {
        content
            .environment(\.themeManager, themeManager)
            .preferredColorScheme(colorScheme)
    }
    
    private var colorScheme: ColorScheme? {
        switch themeManager.currentTheme {
        case .light, .neutral:
            return .light
        case .dark:
            return .dark
        }
    }
}

// View modifier to access theme colors easily
struct ThemedView<Content: View>: View {
    let content: (ThemeColorScheme, Bool) -> Content
    @Environment(\.themeManager) private var themeManager
    
    init(@ViewBuilder content: @escaping (ThemeColorScheme, Bool) -> Content) {
        self.content = content
    }
    
    var body: some View {
        if let themeManager = themeManager {
            content(themeManager.colors, themeManager.isLight)
        } else {
            // Fallback to default light theme
            content(
                ThemeColorScheme(
                    primary: LightThemeColors.primary,
                    onPrimary: LightThemeColors.onPrimary,
                    secondary: LightThemeColors.secondary,
                    onSecondary: LightThemeColors.onSecondary,
                    background: LightThemeColors.background,
                    onBackground: LightThemeColors.onBackground,
                    surface: LightThemeColors.surface,
                    onSurface: LightThemeColors.onSurface,
                    outline: LightThemeColors.outline,
                    primaryContainer: LightThemeColors.primaryContainer,
                    onPrimaryContainer: LightThemeColors.onPrimaryContainer,
                    surfaceVariant: LightThemeColors.surfaceVariant,
                    onSurfaceVariant: LightThemeColors.onSurfaceVariant,
                    error: LightThemeColors.error,
                    shadow: LightThemeColors.shadow
                ),
                true
            )
        }
    }
}

// Extension to easily access theme in any view
extension View {
    func themedColors<Content: View>(@ViewBuilder content: @escaping (ThemeColorScheme, Bool) -> Content) -> some View {
        ThemedView(content: content)
    }
}