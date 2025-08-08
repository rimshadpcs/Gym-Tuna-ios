import SwiftUI

struct EmptyCountersState: View {
    let onAddCounter: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(spacing: MaterialSpacing.lg) {
            // Empty state icon
            Image(systemName: "plus.circle")
                .font(.system(size: 80))
                .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                .opacity(0.6)
            
            VStack(spacing: MaterialSpacing.sm) {
                Text("No counters yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                
                Text("Create your first counter to start tracking")
                    .font(.body)
                    .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddCounter) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Counter")
                }
                .font(.headline)
                .foregroundColor(themeManager?.colors.onPrimary ?? LightThemeColors.onPrimary)
                .padding(.horizontal, MaterialSpacing.lg)
                .padding(.vertical, MaterialSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                        .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MaterialSpacing.xl)
    }
}