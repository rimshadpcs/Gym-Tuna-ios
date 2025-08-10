import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.themeManager) private var themeManager
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MaterialSpacing.sm) {
            Text(title)
                .font(MaterialTypography.headline6)
                .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                .padding(.vertical, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(themeManager?.colors.surface ?? LightThemeColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
            )
        }
        .padding(.vertical, 4)
    }
}