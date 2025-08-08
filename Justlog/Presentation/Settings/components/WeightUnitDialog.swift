import SwiftUI

struct WeightUnitDialog: View {
    let currentUnit: WeightUnit
    let onDismiss: () -> Void
    let onUnitSelected: (WeightUnit) -> Void
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        dialogContent
            .background(backgroundOverlay)
    }
    
    private var dialogContent: some View {
        VStack(spacing: MaterialSpacing.md) {
            titleView
            optionsView
        }
        .background(themeManager?.colors.surface ?? LightThemeColors.surface)
        .cornerRadius(16)
        .overlay(borderOverlay)
        .padding(MaterialSpacing.md)
    }
    
    private var titleView: some View {
        Text("Weight Unit")
            .vagFont(size: 18, weight: .semibold)
            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            .padding(.top, MaterialSpacing.md)
    }
    
    private var optionsView: some View {
        VStack(spacing: MaterialSpacing.sm) {
            ForEach(WeightUnit.allCases, id: \.self) { unit in
                unitRowView(unit: unit)
                
                if unit != WeightUnit.allCases.last {
                    dividerView
                }
            }
        }
        .padding(.horizontal, MaterialSpacing.md)
        .padding(.bottom, MaterialSpacing.sm)
    }
    
    private func unitRowView(unit: WeightUnit) -> some View {
        Button(action: {
            onUnitSelected(unit)
        }) {
            HStack {
                Text(unit.rawValue)
                    .font(MaterialTypography.body1)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                
                Spacer()
                
                if unit == currentUnit {
                    checkmarkView
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
    
    private var checkmarkView: some View {
        Image(systemName: "checkmark")
            .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
            .font(.system(size: 16, weight: .medium))
    }
    
    private var dividerView: some View {
        Divider()
            .background((themeManager?.colors.outline ?? LightThemeColors.outline).opacity(0.5))
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
    }
    
    private var backgroundOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture {
                onDismiss()
            }
    }
}