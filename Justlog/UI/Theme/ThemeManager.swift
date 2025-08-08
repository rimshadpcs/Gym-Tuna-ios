import SwiftUI
import Combine

@MainActor
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .neutral
    private let userPreferences: UserPreferences
    private var cancellables = Set<AnyCancellable>()
    
    init(userPreferences: UserPreferences) {
        self.userPreferences = userPreferences
        
        // Subscribe to theme changes from preferences
        userPreferences.$appTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.currentTheme = theme
                self?.updateSystemColors(for: theme)
            }
            .store(in: &cancellables)
    }
    
    func setTheme(_ theme: AppTheme) {
        // Update immediately for instant UI response
        currentTheme = theme
        updateSystemColors(for: theme)
        
        // Then persist the change
        Task {
            await userPreferences.setAppTheme(theme)
        }
    }
    
    private func updateSystemColors(for theme: AppTheme) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        // Update status bar style
        let _ = theme == .dark
        
        // Set status bar and navigation bar colors (matching Android implementation)
        switch theme {
        case .light:
            window.backgroundColor = UIColor(ThemeColors.white)
            if #available(iOS 13.0, *) {
                window.overrideUserInterfaceStyle = .light
            }
            
        case .neutral:
            window.backgroundColor = UIColor(ThemeColors.neutralColor)
            if #available(iOS 13.0, *) {
                window.overrideUserInterfaceStyle = .light // Neutral uses light interface style
            }
            
        case .dark:
            window.backgroundColor = UIColor(ThemeColors.darkSurface) // Use darkSurface like Android
            if #available(iOS 13.0, *) {
                window.overrideUserInterfaceStyle = .dark
            }
        }
    }
    
    // Get current color scheme based on theme
    var colors: ThemeColorScheme {
        switch currentTheme {
        case .light:
            return ThemeColorScheme(
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
            )
        case .neutral:
            return ThemeColorScheme(
                primary: NeutralThemeColors.primary,
                onPrimary: NeutralThemeColors.onPrimary,
                secondary: NeutralThemeColors.secondary,
                onSecondary: NeutralThemeColors.onSecondary,
                background: NeutralThemeColors.background,
                onBackground: NeutralThemeColors.onBackground,
                surface: NeutralThemeColors.surface,
                onSurface: NeutralThemeColors.onSurface,
                outline: NeutralThemeColors.outline,
                primaryContainer: NeutralThemeColors.primaryContainer,
                onPrimaryContainer: NeutralThemeColors.onPrimaryContainer,
                surfaceVariant: NeutralThemeColors.surfaceVariant,
                onSurfaceVariant: NeutralThemeColors.onSurfaceVariant,
                error: NeutralThemeColors.error,
                shadow: NeutralThemeColors.shadow
            )
        case .dark:
            return ThemeColorScheme(
                primary: DarkThemeColors.primary,
                onPrimary: DarkThemeColors.onPrimary,
                secondary: DarkThemeColors.secondary,
                onSecondary: DarkThemeColors.onSecondary,
                background: DarkThemeColors.background,
                onBackground: DarkThemeColors.onBackground,
                surface: DarkThemeColors.surface,
                onSurface: DarkThemeColors.onSurface,
                outline: DarkThemeColors.outline,
                primaryContainer: DarkThemeColors.primaryContainer,
                onPrimaryContainer: DarkThemeColors.onPrimaryContainer,
                surfaceVariant: DarkThemeColors.surfaceVariant,
                onSurfaceVariant: DarkThemeColors.onSurfaceVariant,
                secondaryContainer: DarkThemeColors.secondaryContainer,
                onSecondaryContainer: DarkThemeColors.onSecondaryContainer,
                error: DarkThemeColors.error,
                shadow: DarkThemeColors.shadow
            )
        }
    }
    
    var isLight: Bool {
        currentTheme != .dark
    }
}

// Color scheme structure
struct ThemeColorScheme {
    let primary: Color
    let onPrimary: Color
    let secondary: Color
    let onSecondary: Color
    let background: Color
    let onBackground: Color
    let surface: Color
    let onSurface: Color
    let outline: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color
    let surfaceVariant: Color?
    let onSurfaceVariant: Color?
    let secondaryContainer: Color?
    let onSecondaryContainer: Color?
    let error: Color
    let shadow: Color
    
    init(
        primary: Color,
        onPrimary: Color,
        secondary: Color,
        onSecondary: Color,
        background: Color,
        onBackground: Color,
        surface: Color,
        onSurface: Color,
        outline: Color,
        primaryContainer: Color,
        onPrimaryContainer: Color,
        surfaceVariant: Color? = nil,
        onSurfaceVariant: Color? = nil,
        secondaryContainer: Color? = nil,
        onSecondaryContainer: Color? = nil,
        error: Color,
        shadow: Color
    ) {
        self.primary = primary
        self.onPrimary = onPrimary
        self.secondary = secondary
        self.onSecondary = onSecondary
        self.background = background
        self.onBackground = onBackground
        self.surface = surface
        self.onSurface = onSurface
        self.outline = outline
        self.primaryContainer = primaryContainer
        self.onPrimaryContainer = onPrimaryContainer
        self.surfaceVariant = surfaceVariant
        self.onSurfaceVariant = onSurfaceVariant
        self.secondaryContainer = secondaryContainer
        self.onSecondaryContainer = onSecondaryContainer
        self.error = error
        self.shadow = shadow
    }
}