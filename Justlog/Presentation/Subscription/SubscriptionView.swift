import SwiftUI

struct SubscriptionView: View {
    @StateObject private var viewModel: SubscriptionViewModel
    @Environment(\.themeManager) private var themeManager
    
    let onBack: () -> Void
    
    init(
        subscriptionRepository: SubscriptionRepository,
        onBack: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: SubscriptionViewModel(
            subscriptionRepository: subscriptionRepository
        ))
        self.onBack = onBack
    }
    
    var body: some View {
        ZStack {
            (themeManager?.colors.background ?? LightThemeColors.background)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Top Bar
                    topBar
                        .padding(.horizontal, MaterialSpacing.md)
                        .padding(.vertical, MaterialSpacing.md)
                    
                    VStack(spacing: MaterialSpacing.lg) {
                        // Current Status Card (if premium)
                        if viewModel.isPremium {
                            currentSubscriptionCard
                                .padding(.horizontal, MaterialSpacing.lg)
                        }
                        
                        // Premium Features Section
                        premiumFeaturesSection
                            .padding(.horizontal, MaterialSpacing.lg)
                        
                        // Pricing Section or Manage Subscription
                        if !viewModel.isPremium {
                            pricingSection
                                .padding(.horizontal, MaterialSpacing.lg)
                            
                            // Restore Purchases Button
                            restorePurchasesButton
                                .padding(.horizontal, MaterialSpacing.lg)
                        } else {
                            manageSubscriptionSection
                                .padding(.horizontal, MaterialSpacing.lg)
                        }
                        
                        // Footer Text
                        footerText
                            .padding(.horizontal, MaterialSpacing.lg)
                            .padding(.bottom, MaterialSpacing.xxl)
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK") {
                viewModel.clearError()
            }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
            }
            
            Spacer()
            
            Text(viewModel.isPremium ? "Manage Premium" : "Upgrade to Premium")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
            
            Spacer()
            
            // Invisible spacer to center the title
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            .opacity(0)
            .disabled(true)
        }
    }
    
    // MARK: - Current Subscription Card
    private var currentSubscriptionCard: some View {
        VStack(spacing: MaterialSpacing.md) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title)
                    .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                
                Spacer()
            }
            
            Text("Premium Active")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
            
            if let renewalText = renewalDateText {
                Text(renewalText)
                    .font(.body)
                    .foregroundColor((themeManager?.colors.primary ?? LightThemeColors.primary).opacity(0.8))
            }
        }
        .padding(MaterialSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.primaryContainer ?? LightThemeColors.primaryContainer)
        )
    }
    
    // MARK: - Premium Features Section
    private var premiumFeaturesSection: some View {
        VStack(alignment: .leading, spacing: MaterialSpacing.md) {
            Text("Features")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
            
            VStack(spacing: MaterialSpacing.md) {
                // Table Header
                HStack {
                    Text("Feature")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Free")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .frame(width: 60, alignment: .center)
                    
                    Text("Premium")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .frame(width: 80, alignment: .center)
                }
                .padding(.bottom, MaterialSpacing.md)
                
                // Feature Rows
                FeatureTableRow(
                    feature: "Workout Routines",
                    freeValue: "3",
                    premiumValue: "Unlimited"
                )
                
                FeatureTableRow(
                    feature: "Custom Exercises", 
                    freeValue: "10",
                    premiumValue: "Unlimited"
                )
                
                FeatureTableRow(
                    feature: "Custom Counters",
                    freeValue: "1", 
                    premiumValue: "Unlimited"
                )
            }
            .padding(MaterialSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                    .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                    .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: MaterialSpacing.md) {
            // Launch Offer Badge
            Text("LAUNCH OFFER")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.onPrimary ?? LightThemeColors.onPrimary)
                .padding(.horizontal, MaterialSpacing.md)
                .padding(.vertical, MaterialSpacing.sm)
                .background(
                    Capsule()
                        .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                )
            
            Text("Early Supporter Pricing")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
            
            // Monthly subscription button
            Button(action: viewModel.purchaseMonthly) {
                VStack(spacing: 4) {
                    Text("Get Monthly Premium")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("$1.99/month")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                        .stroke(themeManager?.colors.primary ?? LightThemeColors.primary, lineWidth: 1)
                )
            }
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0.6 : 1.0)
            
            // Annual subscription button (recommended)
            Button(action: viewModel.purchaseYearly) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.title3)
                    
                    VStack(spacing: 4) {
                        Text("Get Annual Premium (BEST VALUE)")
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("$17.99/year (Save $5.89)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .foregroundColor(themeManager?.colors.onPrimary ?? LightThemeColors.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                        .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                )
            }
            .disabled(viewModel.isLoading)
            .opacity(viewModel.isLoading ? 0.6 : 1.0)
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager?.colors.primary ?? LightThemeColors.primary))
            }
        }
    }
    
    // MARK: - Restore Purchases Button
    private var restorePurchasesButton: some View {
        Button(action: viewModel.restorePurchases) {
            Text("Restore Purchases")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                        .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                )
        }
        .disabled(viewModel.isLoading)
    }
    
    // MARK: - Manage Subscription Section
    private var manageSubscriptionSection: some View {
        VStack(spacing: MaterialSpacing.md) {
            Text("Manage Subscription")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                // Open Google Play Store - iOS equivalent would be App Store
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Manage in App Store")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                            .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                    )
            }
            
            Button(action: viewModel.cancelSubscription) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager?.colors.error ?? LightThemeColors.error))
                    }
                    Text("Cancel Subscription")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(themeManager?.colors.error ?? LightThemeColors.error)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                        .stroke(themeManager?.colors.error ?? LightThemeColors.error, lineWidth: 1)
                )
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    // MARK: - Footer Text
    private var footerText: some View {
        Text(viewModel.isPremium 
             ? "You can manage your subscription in the App Store."
             : "Cancel anytime in App Store. No commitments.")
            .font(.caption)
            .foregroundColor((themeManager?.colors.onBackground ?? LightThemeColors.onBackground).opacity(0.6))
            .multilineTextAlignment(.center)
    }
    
    // MARK: - Computed Properties
    private var renewalDateText: String? {
        guard let expirationDate = viewModel.subscription.expirationDate else { return nil }
        let date = Date(timeIntervalSince1970: expirationDate)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Renews on \(formatter.string(from: date))"
    }
}

// MARK: - Feature Table Row
struct FeatureTableRow: View {
    let feature: String
    let freeValue: String
    let premiumValue: String
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(freeValue)
                .font(.body)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                .frame(width: 60, alignment: .center)
            
            Text(premiumValue)
                .font(.body)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                .frame(width: 80, alignment: .center)
        }
        .padding(.vertical, MaterialSpacing.sm)
    }
}