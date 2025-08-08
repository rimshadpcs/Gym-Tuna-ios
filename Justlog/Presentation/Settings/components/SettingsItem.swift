import SwiftUI

struct SettingsItem: View {
    let iconName: String
    let title: String
    let subtitle: String?
    let onClick: () -> Void
    let endContent: (() -> AnyView)?
    @Environment(\.themeManager) private var themeManager
    
    init(
        iconName: String,
        title: String,
        subtitle: String? = nil,
        onClick: @escaping () -> Void,
        endContent: (() -> AnyView)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.onClick = onClick
        self.endContent = endContent
    }
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: MaterialSpacing.md) {
                // Icon
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .vagFont(size: 16, weight: .medium)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(MaterialTypography.body2)
                            .foregroundColor((themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.6))
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // End content or default arrow
                if let endContent = endContent {
                    endContent()
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor((themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.6))
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .padding(.horizontal, MaterialSpacing.md)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}