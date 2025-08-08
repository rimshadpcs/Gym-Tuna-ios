//
//  FocusableNumericTextField.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import SwiftUI

struct FocusableNumericTextField: View {
    @Environment(\.themeManager) private var themeManager
    
    @Binding var value: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $value)
            .keyboardType(keyboardType)
            .multilineTextAlignment(.center)
            .vagFont(size: 14, weight: .medium)
            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                isFocused 
                                    ? (themeManager?.colors.primary ?? LightThemeColors.primary)
                                    : (themeManager?.colors.outline ?? LightThemeColors.outline),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .focused($isFocused)
    }
}