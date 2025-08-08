import SwiftUI

struct ThemeSelector: View {
    let currentTheme: AppTheme
    let onThemeSelected: (AppTheme) -> Void
    
    var body: some View {
        VStack(spacing: MaterialSpacing.lg) {
            HStack(spacing: MaterialSpacing.sm) {
                // Light Theme
                ThemeButton(
                    theme: .light,
                    title: "Light",
                    backgroundColor: .white,
                    contentColor: .black,
                    isSelected: currentTheme == .light,
                    onTap: { onThemeSelected(.light) }
                )
                
                // Neutral Theme  
                ThemeButton(
                    theme: .neutral,
                    title: "Neutral",
                    backgroundColor: Color(UIColor.systemGray5),
                    contentColor: .black,
                    isSelected: currentTheme == .neutral,
                    onTap: { onThemeSelected(.neutral) }
                )
                
                // Dark Theme
                ThemeButton(
                    theme: .dark,
                    title: "Dark",
                    backgroundColor: .black,
                    contentColor: .white,
                    isSelected: currentTheme == .dark,
                    onTap: { onThemeSelected(.dark) }
                )
            }
            .frame(height: 48)
        }
        .padding(.vertical, MaterialSpacing.sm)
    }
}

private struct ThemeButton: View {
    let theme: AppTheme
    let title: String
    let backgroundColor: Color
    let contentColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(title)
                    .vagFont(size: 14, weight: isSelected ? .semibold : .medium)
                    .foregroundColor(contentColor)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(contentColor)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? MaterialColors.outline : MaterialColors.outline.opacity(0.5),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color.black.opacity(0.1) : Color.clear,
                radius: isSelected ? 4 : 0
            )
        }
        .buttonStyle(.plain)
    }
}