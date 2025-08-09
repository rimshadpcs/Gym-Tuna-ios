//
//  WorkoutItemView.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI
import Foundation

struct WorkoutItemView: View {
    @Environment(\.themeManager) private var themeManager
    let workout: Workout
    let onStartClick: () -> Void
    let onRoutineNameClick: () -> Void
    let onEditClick: () -> Void
    
    @State private var showOptions = false
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Workout info - clickable area
            Button(action: onRoutineNameClick) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(workout.name)
                            .vagFont(size: 15, weight: .medium)
                            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        
                        // Small colored dot like in original
                        Circle()
                            .fill(workoutColor)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text("\(workout.exercises.count) exercise\(workout.exercises.count != 1 ? "s" : "")")
                        .vagFont(size: 12, weight: .regular)
                        .foregroundColor(themeManager?.colors.onSurface.opacity(0.5) ?? LightThemeColors.onSurface.opacity(0.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Action buttons - compact like original
            HStack(spacing: 8) {
                // Start Button 
                Button(action: onStartClick) {
                    Text("Start")
                        .vagFont(size: 13, weight: .medium)
                        .foregroundColor(isDarkTheme ? Color.white : (themeManager?.colors.onSurface ?? LightThemeColors.onSurface))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isDarkTheme ? Color.black : (themeManager?.colors.surface ?? LightThemeColors.surface))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            isDarkTheme ? Color.white : Color.black,
                                            lineWidth: 1.5
                                        )
                                )
                        )
                }
                .buttonStyle(.plain)

                
                // Options button - three dots
                Button(action: { showOptions = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager?.colors.onSurface.opacity(0.6) ?? LightThemeColors.onSurface.opacity(0.6))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
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
        .actionSheet(isPresented: $showOptions) {
            ActionSheet(
                title: Text(workout.name),
                buttons: [
                    .default(Text("Edit")) {
                        onEditClick()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - Computed Properties
    private var isDarkTheme: Bool {
        themeManager?.currentTheme == .dark
    }
    
    private var workoutColor: Color {
        if let colorHex = workout.colorHex {
            return Color(hex: colorHex) ?? (themeManager?.colors.primary ?? LightThemeColors.primary)
        } else {
            return themeManager?.colors.primary ?? LightThemeColors.primary
        }
    }
}
