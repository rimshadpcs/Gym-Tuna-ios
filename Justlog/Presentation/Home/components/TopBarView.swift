//
//  TopBarView.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//


import SwiftUI

struct TopBarView: View {
    @Environment(\.themeManager) private var themeManager
    let greeting: String
    let formattedDate: String
    let onSettingsClick: () -> Void
    
    private var isDarkTheme: Bool {
        switch themeManager?.currentTheme {
        case .dark:
            return true
        case .neutral, .light, .none:
            return false
        }
    }
    
    var body: some View {
        HStack {
            // Logo and app name like Android
            HStack(spacing: 8) {
                Image("gymloglogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                
                Text("Just log")
                    .vagFont(size: 20, weight: .bold)
                    .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
            }
            
            Spacer()
            
            // Settings button with custom icon like Android
            Button(action: onSettingsClick) {
                Image(isDarkTheme ? "usersetting_dark" : "usersetting")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .padding(6)
            }
            .frame(width: 36, height: 36)
            .overlay(
                Circle()
                    .stroke(themeManager?.colors.onBackground ?? LightThemeColors.onBackground, lineWidth: 2)
            )
        }
        .padding(.vertical, 4)
    }
}