import SwiftUI

struct PremiumBenefitsView: View {
    @Environment(\.themeManager) private var themeManager
    
    let onBack: () -> Void
    let onUpgrade: () -> Void
    
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
                    
                    VStack(spacing: MaterialSpacing.xxl) {
                        // Hero Section
                        heroSection
                            .padding(.horizontal, MaterialSpacing.lg)
                        
                        // Benefits List
                        benefitsSection
                            .padding(.horizontal, MaterialSpacing.lg)
                        
                        // Pricing Plans
                        pricingPlansSection
                            .padding(.horizontal, MaterialSpacing.lg)
                        
                        // Upgrade Button
                        upgradeButton
                            .padding(.horizontal, MaterialSpacing.lg)
                        
                        // Footer Text
                        footerText
                            .padding(.horizontal, MaterialSpacing.lg)
                            .padding(.bottom, MaterialSpacing.xxl)
                    }
                }
            }
        }
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
            
            Text("Upgrade to Premium")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
            
            Spacer()
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: MaterialSpacing.lg) {
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
            
            Text("Unlock Premium Features")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                .multilineTextAlignment(.center)
            
            Text("Take your fitness journey to the next level with unlimited access")
                .font(.body)
                .foregroundColor((themeManager?.colors.primary ?? LightThemeColors.primary).opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(MaterialSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.extraLarge)
                .fill(themeManager?.colors.primaryContainer ?? LightThemeColors.primaryContainer)
        )
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: MaterialSpacing.md) {
            Text("What You Get")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: MaterialSpacing.md) {
                BenefitItem(
                    title: "Unlimited Workout Routines",
                    description: "Create as many custom routines as you need"
                )
                
                BenefitItem(
                    title: "Unlimited Custom Exercises",
                    description: "Build your perfect exercise library"
                )
                
                BenefitItem(
                    title: "Unlimited Custom Counters",
                    description: "Track any habit or activity you want"
                )
            }
        }
    }
    
    // MARK: - Pricing Plans Section
    private var pricingPlansSection: some View {
        VStack(alignment: .leading, spacing: MaterialSpacing.md) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: MaterialSpacing.sm) {
                // Annual Plan (Recommended)
                annualPlanCard
                
                // Monthly Plan
                monthlyPlanCard
            }
        }
    }
    
    private var annualPlanCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Annual Plan")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                
                Text("$17.99/year")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                
                Text("Save $6.89")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
            }
            
            Spacer()
            
            Text("BEST VALUE")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.onPrimary ?? LightThemeColors.onPrimary)
                .padding(.horizontal, MaterialSpacing.sm)
                .padding(.vertical, MaterialSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.small)
                        .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                )
        }
        .padding(MaterialSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                .stroke((themeManager?.colors.primary ?? LightThemeColors.primary), lineWidth: 2)
        )
    }
    
    private var monthlyPlanCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Monthly Plan")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            
            Text("$1.99/month")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MaterialSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
        )
    }
    
    // MARK: - Upgrade Button
    private var upgradeButton: some View {
        Button(action: onUpgrade) {
            Text("Upgrade to Premium")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(themeManager?.colors.onPrimary ?? LightThemeColors.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                        .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                )
        }
    }
    
    // MARK: - Footer Text
    private var footerText: some View {
        Text("Cancel anytime • No commitments")
            .font(.caption)
            .foregroundColor((themeManager?.colors.onBackground ?? LightThemeColors.onBackground).opacity(0.6))
            .multilineTextAlignment(.center)
    }
}

// MARK: - Benefit Item
struct BenefitItem: View {
    let title: String
    let description: String
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: MaterialSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                
                Text(description)
                    .font(.body)
                    .foregroundColor((themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.7))
            }
            
            Spacer()
        }
        .padding(MaterialSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
        )
    }
}