import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showWeightUnitDialog = false
    @State private var showDistanceUnitDialog = false
    @Environment(\.themeManager) private var themeManager
    
    // Navigation actions
    let onBack: () -> Void
    let onNavigateToProfile: () -> Void
    let onNavigateToSubscription: () -> Void
    
    init(
        authRepository: AuthRepository,
        subscriptionRepository: SubscriptionRepository,
        userPreferences: UserPreferences,
        onBack: @escaping () -> Void,
        onNavigateToProfile: @escaping () -> Void,
        onNavigateToSubscription: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(
            authRepository: authRepository,
            subscriptionRepository: subscriptionRepository,
            userPreferences: userPreferences
        ))
        self.onBack = onBack
        self.onNavigateToProfile = onNavigateToProfile
        self.onNavigateToSubscription = onNavigateToSubscription
    }
    
    var body: some View {
        ZStack {
            (themeManager?.colors.background ?? LightThemeColors.background)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    IOSBackButton(action: onBack)
                    
                    Spacer()
                    
                    Text("Settings")
                        .vagFont(size: 20, weight: .semibold)
                        .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                    
                    Spacer()
                    
                    // Empty space to balance the back button
                    Color.clear
                        .frame(width: 48, height: 48)
                }
                .padding(.horizontal, MaterialSpacing.screenHorizontal)
                .padding(.top, MaterialSpacing.lg)
                
                // Main Content
                ScrollView {
                    LazyVStack(spacing: MaterialSpacing.lg) {
                        // Profile Section
                        SettingsSection(title: "Profile") {
                            SettingsItem(
                                iconName: isDarkTheme ? "profile_dark" : "profile",
                                title: viewModel.userProfile.displayName.isEmpty ? "Set Name" : viewModel.userProfile.displayName,
                                subtitle: viewModel.userProfile.email,
                                onClick: onNavigateToProfile
                            )
                        }
                        
                        // Subscription Button
                        subscriptionButton
                        
                        // Weight Unit Button
                        weightUnitButton
                        
                        // Distance Unit Button
                        distanceUnitButton
                        
                        // Theme Section
                        SettingsSection(title: "Theme") {
                            VStack(spacing: 0) {
                                ThemeSelector(
                                    currentTheme: themeManager?.currentTheme ?? .neutral,
                                    onThemeSelected: { theme in
                                        themeManager?.setTheme(theme)
                                    }
                                )
                                .padding(MaterialSpacing.md)
                            }
                        }
                        
                        // App Info Section
                        SettingsSection(title: "Info & Legal") {
                            VStack(spacing: 0) {
                                SettingsItem(
                                    iconName: isDarkTheme ? "info_dark" : "info",
                                    title: "About",
                                    subtitle: "2.0.0",
                                    onClick: {
                                        if let url = URL(string: "https://justlog.app/") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                )
                                
                                Divider()
                                    .background(MaterialColors.outline.opacity(0.5))
                                    .padding(.horizontal, MaterialSpacing.md)
                                
                                SettingsItem(
                                    iconName: isDarkTheme ? "privacy_dark" : "privacy",
                                    title: "Privacy Policy",
                                    onClick: {
                                        if let url = URL(string: "https://justlog.app/privacy") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                )
                                
                                Divider()
                                    .background(MaterialColors.outline.opacity(0.5))
                                    .padding(.horizontal, MaterialSpacing.md)
                                
                                SettingsItem(
                                    iconName: isDarkTheme ? "terms_dark" : "terms",
                                    title: "Terms of Service",
                                    onClick: {
                                        if let url = URL(string: "https://justlog.app/terms") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                )
                                
                                Divider()
                                    .background(MaterialColors.outline.opacity(0.5))
                                    .padding(.horizontal, MaterialSpacing.md)
                                
                                SettingsItem(
                                    iconName: isDarkTheme ? "share_dark" : "share",
                                    title: "Share App",
                                    onClick: {
                                        shareApp()
                                    }
                                )
                            }
                        }
                        
                        // Developer Section (for testing premium features)
                        SettingsSection(title: "🛠️ Developer Testing") {
                            VStack(spacing: 0) {
                                developerPremiumToggle
                            }
                        }
                    }
                    .padding(.horizontal, MaterialSpacing.screenHorizontal)
                    .padding(.bottom, MaterialSpacing.lg)
                }
            }
            
            // Weight Unit Dialog
            if showWeightUnitDialog {
                WeightUnitDialog(
                    currentUnit: viewModel.weightUnit,
                    onDismiss: { showWeightUnitDialog = false },
                    onUnitSelected: { unit in
                        viewModel.updateWeightUnit(unit)
                        showWeightUnitDialog = false
                    }
                )
            }
            
            // Distance Unit Dialog
            if showDistanceUnitDialog {
                DistanceUnitDialog(
                    currentUnit: viewModel.distanceUnit,
                    onDismiss: { showDistanceUnitDialog = false },
                    onUnitSelected: { unit in
                        viewModel.updateDistanceUnit(unit)
                        showDistanceUnitDialog = false
                    }
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isPremium: Bool {
        viewModel.subscription.tier == .premium && viewModel.subscription.isActive
    }
    
    private var subscriptionStatus: String {
        isPremium ? "Premium Plan" : "Free Plan"
    }
    
    // MARK: - UI Components
    
    private var subscriptionButton: some View {
        Button(action: onNavigateToSubscription) {
            HStack(spacing: MaterialSpacing.md) {
                // Icon
                if isPremium {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                } else {
                    Image(isDarkTheme ? "subscription_dark" : "subscription")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(isPremium ? "Manage Premium" : "Manage Subscription")
                        .vagFont(size: 16, weight: .semibold)
                        .foregroundColor(isPremium ? (themeManager?.colors.primary ?? LightThemeColors.primary) : (themeManager?.colors.onSurface ?? LightThemeColors.onSurface))
                    
                    Text(subscriptionStatus)
                        .font(MaterialTypography.body2)
                        .foregroundColor(isPremium ? (themeManager?.colors.primary ?? LightThemeColors.primary).opacity(0.8) : (themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.6))
                }
                
                Spacer()
            }
            .padding(.horizontal, MaterialSpacing.md)
            .padding(.vertical, MaterialSpacing.md)
            .background(isPremium ? (themeManager?.colors.primaryContainer ?? LightThemeColors.primaryContainer) : (themeManager?.colors.surface ?? LightThemeColors.surface))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPremium ? (themeManager?.colors.primary ?? LightThemeColors.primary) : (themeManager?.colors.outline ?? LightThemeColors.outline), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.vertical, MaterialSpacing.sm)
    }
    
    private var weightUnitButton: some View {
        Button(action: { showWeightUnitDialog = true }) {
            weightUnitButtonContent
        }
        .buttonStyle(.plain)
        .padding(.vertical, MaterialSpacing.sm)
    }
    
    private var weightUnitButtonContent: some View {
        HStack(spacing: MaterialSpacing.md) {
            weightUnitIcon
            weightUnitInfo
            Spacer()
        }
        .padding(.horizontal, MaterialSpacing.md)
        .padding(.vertical, MaterialSpacing.md)
        .background(themeManager?.colors.surface ?? LightThemeColors.surface)
        .cornerRadius(12)
        .overlay(weightUnitBorder)
    }
    
    private var weightUnitIcon: some View {
        Image(isDarkTheme ? "weight_dark" : "weight")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
    }
    
    private var weightUnitInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Weight Unit")
                .vagFont(size: 16, weight: .semibold)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            
            Text(viewModel.weightUnit.rawValue)
                .font(MaterialTypography.body2)
                .foregroundColor((themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.6))
        }
    }
    
    private var weightUnitBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
    }
    
    private var distanceUnitButton: some View {
        Button(action: { showDistanceUnitDialog = true }) {
            distanceUnitButtonContent
        }
        .buttonStyle(.plain)
        .padding(.vertical, MaterialSpacing.sm)
    }
    
    private var distanceUnitButtonContent: some View {
        HStack(spacing: MaterialSpacing.md) {
            distanceUnitIcon
            distanceUnitInfo
            Spacer()
        }
        .padding(.horizontal, MaterialSpacing.md)
        .padding(.vertical, MaterialSpacing.md)
        .background(themeManager?.colors.surface ?? LightThemeColors.surface)
        .cornerRadius(12)
        .overlay(distanceUnitBorder)
    }
    
    private var distanceUnitIcon: some View {
        Image(isDarkTheme ? "distance_dark" : "distance")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
    }
    
    private var distanceUnitInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Distance Unit")
                .vagFont(size: 16, weight: .semibold)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            
            Text(viewModel.distanceUnit.rawValue)
                .font(MaterialTypography.body2)
                .foregroundColor((themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.6))
        }
    }
    
    private var distanceUnitBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
    }
    
    // MARK: - Developer Testing Components
    
    private var developerPremiumToggle: some View {
        HStack(spacing: MaterialSpacing.md) {
            // Debug Icon
            Image(systemName: "hammer")
                .font(.system(size: 24))
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text("Premium Override")
                    .vagFont(size: 16, weight: .semibold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                
                Text(isPremium ? "Premium Active" : "Free Tier Active")
                    .font(MaterialTypography.body2)
                    .foregroundColor((themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.6))
            }
            
            Spacer()
            
            // Toggle Switch
            Toggle("", isOn: Binding(
                get: { isPremium },
                set: { newValue in
                    toggleDeveloperPremium(newValue)
                }
            ))
            .labelsHidden()
        }
        .padding(.horizontal, MaterialSpacing.md)
        .padding(.vertical, MaterialSpacing.md)
        .background(themeManager?.colors.surface ?? LightThemeColors.surface)
    }
    
    // MARK: - Helper Methods
    
    private func toggleDeveloperPremium(_ isEnabled: Bool) {
        if isEnabled {
            viewModel.testActivatePremium()
        } else {
            viewModel.testCancelSubscription()
        }
    }
    
    private func getCurrentTheme() -> AppTheme {
        themeManager?.currentTheme ?? .neutral
    }
    
    private var isDarkTheme: Bool {
        themeManager?.currentTheme == .dark
    }
    
    private func shareApp() {
        let shareText = "Check out this awesome gym tracking app: https://play.google.com/store/apps/details?id=com.rimapps.justlog"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}