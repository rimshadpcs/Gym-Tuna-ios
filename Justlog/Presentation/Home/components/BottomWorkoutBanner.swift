//
//  BottomWorkoutBanner.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI
import Foundation

struct BottomWorkoutBanner: View {
    @Environment(\.themeManager) private var themeManager
    @StateObject private var sessionManager = WorkoutSessionManager.shared
    let workout: Workout
    let onResumeClick: () -> Void
    let onDiscardClick: () -> Void
    
    private var isDarkTheme: Bool {
        switch themeManager?.currentTheme {
        case .dark:
            return true
        case .neutral, .light, .none:
            return false
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Gym icon like Android
            Image(isDarkTheme ? "gym_dark" : "gym")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            
            // Workout info
            VStack(alignment: .leading, spacing: 2) {
                Text("Workout")
                    .vagFont(size: 12, weight: .regular)
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.7) ?? LightThemeColors.onSurface.opacity(0.7))
                
                Text("in Progress")
                    .vagFont(size: 12, weight: .regular)
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.7) ?? LightThemeColors.onSurface.opacity(0.7))
                
                Text(workout.name + "...")
                    .vagFont(size: 14, weight: .medium)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    .lineLimit(1)
                
                Text(sessionManager.getCurrentDuration())
                    .vagFont(size: 12, weight: .regular)
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.7) ?? LightThemeColors.onSurface.opacity(0.7))
            }
            
            Spacer()
            
            // Action buttons like original
            HStack(spacing: 12) {
                // Red X button for discard
                Button(action: onDiscardClick) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                
                // Resume button with play icon
                Button(action: onResumeClick) {
                    HStack(spacing: 6) {
                        Image(isDarkTheme ? "play_dark" : "play")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 10, height: 10)
                        Text("Resume")
                            .vagFont(size: 13, weight: .medium)
                    }
                    .foregroundColor(isDarkTheme ? .white : (themeManager?.colors.onSurface ?? LightThemeColors.onSurface))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isDarkTheme ? .black : (themeManager?.colors.surface ?? LightThemeColors.surface))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        isDarkTheme ? .white : Color.black,
                                        lineWidth: 1.5
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.card)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.card)
                        .stroke(
                            isDarkTheme ? Color.white : Color.black,
                            lineWidth: 1.5
                        )
                )
        )
        .padding(.horizontal)
        .padding(.bottom)
    }
}