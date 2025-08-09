//
//  ExerciseOptionsBottomSheet.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import SwiftUI

struct ExerciseOptionsBottomSheet: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    
    let exerciseName: String
    let isSuperset: Bool
    let isDropset: Bool
    let onReArrange: () -> Void
    let onReplace: () -> Void
    let onToggleSuperset: () -> Void
    let onToggleDropset: () -> Void
    let onRemove: () -> Void
    
    private var isDarkTheme: Bool {
        switch themeManager?.currentTheme {
        case .dark:
            return true
        case .neutral, .light, .none:
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(themeManager?.colors.outline.opacity(0.3) ?? LightThemeColors.outline.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(exerciseName)
                    .vagFont(size: 20, weight: .semibold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    .padding(.horizontal, 16)
                
                // Options
                VStack(spacing: 8) {
                    optionButton(
                        title: "Re-arrange Exercise",
                        icon: isDarkTheme ? "reorder_dark" : "reorder",
                        action: {
                            onReArrange()
                            dismiss()
                        }
                    )
                    
                    optionButton(
                        title: "Replace Exercise",
                        icon: isDarkTheme ? "replace_dark" : "replace",
                        action: {
                            onReplace()
                            dismiss()
                        }
                    )
                    
                    optionButton(
                        title: isSuperset ? "Remove from Superset" : "Add to Superset",
                        icon: isDarkTheme ? "superset_dark" : "superset",
                        textColor: isSuperset ? (themeManager?.colors.primary ?? LightThemeColors.primary) : nil,
                        borderColor: isSuperset ? (themeManager?.colors.primary ?? LightThemeColors.primary) : nil,
                        action: {
                            onToggleSuperset()
                            dismiss()
                        }
                    )
                    
                    optionButton(
                        title: isDropset ? "Remove from Dropset" : "Add to Dropset",
                        icon: isDarkTheme ? "dropset_dark" : "dropset",
                        textColor: isDropset ? ExerciseColors.dropsetColor : nil,
                        borderColor: isDropset ? ExerciseColors.dropsetColor : nil,
                        action: {
                            onToggleDropset()
                            dismiss()
                        }
                    )
                    
                    optionButton(
                        title: "Remove Exercise",
                        icon: isDarkTheme ? "trash_dark" : "trash",
                        textColor: themeManager?.colors.error ?? LightThemeColors.error,
                        borderColor: themeManager?.colors.error ?? LightThemeColors.error,
                        action: {
                            onRemove()
                            dismiss()
                        }
                    )
                }
                .padding(.horizontal, 16)
                
                Spacer()
                    .frame(height: 16)
            }
        }
        .background(themeManager?.colors.surface ?? LightThemeColors.surface)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.hidden)
    }
    
    private func optionButton(
        title: String,
        icon: String,
        textColor: Color? = nil,
        borderColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .vagFont(size: 16, weight: .medium)
                    .foregroundColor(textColor ?? (themeManager?.colors.onSurface ?? LightThemeColors.onSurface))
                
                Spacer()
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            borderColor ?? (themeManager?.colors.outline ?? LightThemeColors.outline),
                            lineWidth: 1
                        )
                )
        )
    }
}

