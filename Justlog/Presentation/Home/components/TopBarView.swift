//
//  TopBarView.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//


import SwiftUI

struct TopBarView: View {
    let onSettingsClick: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkTheme: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        HStack {
            // Left side - Logo and title (Material Design style)
            HStack(spacing: MaterialSpacing.sm) {
                Image("gymloglogo")
                    .resizable()
                    .frame(width: 32, height: 32)
                
                Text("Just log")
                    .font(MaterialTypography.headline6)
                    .foregroundColor(MaterialColors.onSurface)
            }
            
            Spacer()
            
            // Right side - Settings button (Material Icon Button)
            Button(action: onSettingsClick) {
                let settingsImageName = isDarkTheme ? "usersetting_dark" : "usersetting"
                
                Image(settingsImageName)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(MaterialColors.onSurface.opacity(0.8))
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(MaterialColors.surface)
                    .overlay(
                        Circle()
                            .stroke(MaterialColors.outline, lineWidth: 1)
                    )
            )
        }
        .padding(.vertical, MaterialSpacing.sm)
    }
}