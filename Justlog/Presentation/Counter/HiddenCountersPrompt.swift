import SwiftUI

struct HiddenCountersPrompt: View {
    let hiddenCount: Int
    let onUpgrade: () -> Void
    
    // Calculate total counters (visible + hidden)
    private var totalCounters: Int {
        return 1 + hiddenCount // 1 visible + hidden count
    }
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(spacing: MaterialSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: MaterialSpacing.xs) {
                    Text("You have \(totalCounters) counter\(totalCounters == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    
                    Text("You need to upgrade to use more counters")
                        .font(.caption)
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                }
                
                Spacer()
                
                Button(action: onUpgrade) {
                    Text("Upgrade")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager?.colors.onPrimary ?? LightThemeColors.onPrimary)
                        .padding(.horizontal, MaterialSpacing.md)
                        .padding(.vertical, MaterialSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                        )
                }
            }
        }
        .padding(MaterialSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
        )
    }
}