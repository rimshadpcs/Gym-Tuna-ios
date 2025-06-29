//
//  WorkoutItemView.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI
import Foundation

struct WorkoutItemView: View {
    let workout: Workout
    let onStartClick: () -> Void
    let onRoutineNameClick: () -> Void
    let onDuplicate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showOptions = false
    @State private var isPressed = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isLightTheme: Bool {
        colorScheme == .light
    }
    
    var body: some View {
        HStack {
            // Left side - Workout info
            VStack(alignment: .leading, spacing: MaterialSpacing.xs) {
                HStack(spacing: MaterialSpacing.sm) {
                    Text(workout.name)
                        .font(MaterialTypography.subtitle1)
                        .fontWeight(.medium)
                        .foregroundColor(MaterialColors.onSurface)
                    
                    // Color dot (Material Design style)
                    if let colorHex = workout.colorHex,
                       let color = Color(hex: colorHex) {
                        Circle()
                            .fill(color)
                            .frame(width: 12, height: 12)
                            .materialElevation(1)
                    }
                }
                
                Text("\(workout.exercises.count) exercises")
                    .font(MaterialTypography.body2)
                    .foregroundColor(MaterialColors.onSurface.opacity(0.7))
            }
            .onTapGesture {
                onRoutineNameClick()
            }
            
            Spacer()
            
            // Right side - Actions
            HStack(spacing: MaterialSpacing.sm) {
                // Start Button (Material Primary)
                Button(action: onStartClick) {
                    Text("Start")
                        .font(MaterialTypography.button)
                        .padding(.horizontal, MaterialSpacing.lg)
                }
                .buttonStyle(.materialPrimary)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { isPressing in
                    withAnimation(.easeInOut(duration: 0.08)) {
                        isPressed = isPressing
                    }
                } perform: {}
                
                // More options (Material Icon Button)
                Button(action: { showOptions = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MaterialColors.onSurface.opacity(0.7))
                        .frame(width: 32, height: 32)
                }
                .background(
                    Circle()
                        .fill(MaterialColors.surface)
                        .materialElevation(1)
                )
            }
        }
        .padding(MaterialSpacing.cardPadding)
        .frame(minHeight: MaterialComponentTokens.ListItem.height)
        .materialCard()
        .actionSheet(isPresented: $showOptions) {
            ActionSheet(
                title: Text(workout.name),
                buttons: [
                    .default(Text("Duplicate")) {
                        onDuplicate()
                    },
                    .default(Text("Edit")) {
                        onEdit()
                    },
                    .destructive(Text("Delete")) {
                        onDelete()
                    },
                    .cancel()
                ]
            )
        }
    }
}
