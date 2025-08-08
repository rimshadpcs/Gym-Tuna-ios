//
//  QuickActionsSection.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI
import Foundation

struct QuickActionsSection: View {
    @Environment(\.themeManager) private var themeManager
    let onStartEmptyWorkout: () -> Void
    let onNewRoutine: () -> Void
    let onNavigateToCounter: () -> Void
    
    private var isDarkTheme: Bool {
        switch themeManager?.currentTheme {
        case .dark:
            return true
        case .neutral, .light, .none:
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Section header with counter button on the right
            HStack {
                Text("Quick Actions")
                    .vagFont(size: 18, weight: .semibold)
                    .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                
                Spacer()
                
                // Counter Button - match Android exactly
                Button(action: onNavigateToCounter) {
                    HStack(spacing: 4) {
                        Text("Custom counter")
                            .vagFont(size: 14, weight: .semibold)
                        
                        Image(isDarkTheme ? "counter_dark" : "counter")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    }
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                            )
                    )
                }
            }
            
            // Quick action buttons - match Android layout
            HStack(spacing: 8) {
                // Quick Start Button
                QuickActionButton(
                    icon: "plus",
                    title: "Quick Start",
                    action: onStartEmptyWorkout
                )
                
                // New Routine Button
                QuickActionButton(
                    icon: "gym",
                    title: "New Routine", 
                    action: onNewRoutine
                )
            }
        }
        .padding(.horizontal, MaterialSpacing.lg)
        .padding(.vertical, 8)
    }
}

// MARK: - QuickActionButton
struct QuickActionButton: View {
    @Environment(\.themeManager) private var themeManager
    let icon: String
    let title: String
    let action: () -> Void
    
    private var isDarkTheme: Bool {
        switch themeManager?.currentTheme {
        case .dark:
            return true
        case .neutral, .light, .none:
            return false
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Use custom icons like Android
                if title == "Quick Start" {
                    Image("plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    Image(isDarkTheme ? "gym_dark" : "gym")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                
                Text(title)
                    .vagFont(size: 13, weight: .semibold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}