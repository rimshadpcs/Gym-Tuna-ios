import SwiftUI

struct PremiumUpgradeDialog: View {
    @Environment(\.themeManager) private var themeManager
    
    let onDismiss: () -> Void
    let onUpgrade: () -> Void
    let title: String
    let message: String
    
    init(
        onDismiss: @escaping () -> Void,
        onUpgrade: @escaping () -> Void,
        title: String = "Ready for More?",
        message: String = "You're doing great! Ready to unlock your full potential with unlimited routines and premium features?"
    ) {
        self.onDismiss = onDismiss
        self.onUpgrade = onUpgrade
        self.title = title
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: MaterialSpacing.lg) {
            // Title with star icon
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
            }
            
            // Message
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            
            // Premium benefits
            VStack(alignment: .leading, spacing: MaterialSpacing.sm) {
                PremiumBenefit(text: "✨ Unlimited workout routines")
                PremiumBenefit(text: "🏋️ Unlimited custom exercises")
                PremiumBenefit(text: "🚀 More amazing features coming")
            }
            
            // Launch Offer Badge
            Text("🚀 LAUNCH OFFER - Early Users Only!")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                .padding(.horizontal, MaterialSpacing.sm)
                .padding(.vertical, MaterialSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                        .fill((themeManager?.colors.primaryContainer ?? LightThemeColors.primaryContainer))
                )
            
            // Pricing Section
            VStack(spacing: MaterialSpacing.sm) {
                // Monthly pricing with strikethrough
                HStack {
                    Text("$2.29")
                        .font(.body)
                        .strikethrough()
                        .foregroundColor((themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.6))
                    
                    Text("$1.79/month")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                }
                
                Text("or")
                    .font(.caption)
                    .foregroundColor((themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.7))
                
                // Yearly pricing (better deal)  
                HStack {
                    Text("$22.99")
                        .font(.body)
                        .strikethrough()
                        .foregroundColor((themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.6))
                    
                    Text("$17.99/year")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                }
                
                // Savings highlight
                Text("💰 Save $3.49 with yearly plan!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, MaterialSpacing.sm)
                    .padding(.vertical, MaterialSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                            .fill(Color.green.opacity(0.1))
                    )
            }
            
            // Forever guarantee
            Text("🔒 Lock in this price forever as an early supporter!")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                .multilineTextAlignment(.center)
            
            // Action Buttons
            VStack(spacing: MaterialSpacing.sm) {
                // Upgrade Button
                Button(action: onUpgrade) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.body)
                        Text("Claim Launch Offer")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(themeManager?.colors.onPrimary ?? LightThemeColors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                            .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                    )
                }
                
                // Dismiss Button
                Button(action: onDismiss) {
                    Text("I'll Stay Free")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                }
            }
        }
        .padding(MaterialSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
        )
        .shadow(
            color: (themeManager?.colors.shadow ?? LightThemeColors.shadow).opacity(0.2),
            radius: 10,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Premium Benefit Item
struct PremiumBenefit: View {
    let text: String
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        HStack {
            Text(text)
                .font(.caption)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            Spacer()
        }
    }
}