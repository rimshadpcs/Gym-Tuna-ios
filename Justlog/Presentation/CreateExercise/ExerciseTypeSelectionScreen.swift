//
//  ExerciseTypeSelectionScreen.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 09/08/2025.
//

import SwiftUI

struct ExerciseTypeSelectionScreen: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    
    let onBack: () -> Void
    let onSelect: (String) -> Void
    let selectedType: String
    
    private var isDarkTheme: Bool {
        colorScheme == .dark
    }
    
    private var contentColor: Color {
        themeManager?.colors.onBackground ?? LightThemeColors.onBackground
    }
    
    private var backgroundColor: Color {
        themeManager?.colors.background ?? LightThemeColors.background
    }
    
    private var surfaceColor: Color {
        themeManager?.colors.surface ?? LightThemeColors.surface
    }
    
    private var outlineColor: Color {
        themeManager?.colors.outline ?? LightThemeColors.outline
    }
    
    private let exerciseTypes = [
        ExerciseType(
            name: "Weighted Reps",
            description: "Exercises using added weight and reps",
            primaryButton: "REPS",
            secondaryButton: "+KG",
            iconResId: "gym"
        ),
        ExerciseType(
            name: "Bodyweight Reps",
            description: "Exercises using only your body weight",
            primaryButton: "REPS",
            secondaryButton: nil,
            iconResId: "gym"
        ),
        ExerciseType(
            name: "Weighted Bodyweight",
            description: "Bodyweight exercises with added weight",
            primaryButton: "REPS",
            secondaryButton: "+KG",
            iconResId: "gym"
        ),
        ExerciseType(
            name: "Assisted Bodyweight",
            description: "Bodyweight exercises with assistance",
            primaryButton: "REPS",
            secondaryButton: "-KG",
            iconResId: "gym"
        ),
        ExerciseType(
            name: "Duration",
            description: "Timed exercises like planks or stretching",
            primaryButton: "TIME",
            secondaryButton: nil,
            iconResId: "gym"
        ),
        ExerciseType(
            name: "Duration & Weight",
            description: "Timed exercises with weights",
            primaryButton: "TIME",
            secondaryButton: "KG",
            iconResId: "gym"
        ),
        ExerciseType(
            name: "Distance & Duration",
            description: "Exercises tracking distance and time",
            primaryButton: "TIME",
            secondaryButton: "MI",
            iconResId: "gym"
        ),
        ExerciseType(
            name: "Weight & Distance",
            description: "Exercises tracking weight and distance",
            primaryButton: "KG",
            secondaryButton: "MI",
            iconResId: "gym"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            topBar
            
            // Description
            descriptionText
            
            // Exercise types list
            ScrollView {
                LazyVStack(spacing: MaterialSpacing.lg) {
                    ForEach(exerciseTypes, id: \.name) { type in
                        exerciseTypeCard(type)
                    }
                }
                .padding(.horizontal, MaterialSpacing.screenHorizontal)
                .padding(.vertical, MaterialSpacing.sm)
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    private var topBar: some View {
        HStack(spacing: MaterialSpacing.md) {
            IOSBackButton(action: onBack)
            
            Text("Select Exercise Type")
                .vagFont(size: 20, weight: .semibold)
                .foregroundColor(contentColor)
            
            Spacer()
            
            // Empty space for layout balance
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, MaterialSpacing.screenHorizontal)
        .padding(.vertical, MaterialSpacing.md)
        .background(surfaceColor)
    }
    
    private var descriptionText: some View {
        HStack {
            Text("Choose how this exercise is performed and tracked")
                .vagFont(size: 14, weight: .regular)
                .foregroundColor(contentColor.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, MaterialSpacing.screenHorizontal)
        .padding(.vertical, MaterialSpacing.md)
    }
    
    private func exerciseTypeCard(_ type: ExerciseType) -> some View {
        let isSelected = selectedType == type.name
        let iconResId = isDarkTheme ? "\(type.iconResId)_dark" : type.iconResId
        
        return Button(action: { onSelect(type.name) }) {
            VStack(alignment: .leading, spacing: MaterialSpacing.sm) {
                // Header row
                HStack(spacing: MaterialSpacing.md) {
                    // Icon
                    Image(iconResId)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(isSelected ?
                            themeManager?.colors.primary ?? Color.blue :
                            contentColor
                        )
                    
                    // Type name
                    Text(type.name)
                        .vagFont(size: 16, weight: isSelected ? .bold : .medium)
                        .foregroundColor(isSelected ?
                            themeManager?.colors.primary ?? Color.blue :
                            contentColor
                        )
                    
                    Spacer()
                    
                    // Selected checkmark
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(themeManager?.colors.primary ?? Color.blue)
                    }
                }
                
                // Description
                HStack {
                    Spacer().frame(width: 36) // Align with icon
                    Text(type.description)
                        .vagFont(size: 14, weight: .regular)
                        .foregroundColor(contentColor.opacity(0.7))
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                
                // Tracking buttons
                HStack(spacing: MaterialSpacing.xs) {
                    Spacer().frame(width: 36) // Align with icon
                    
                    TrackingButton(text: type.primaryButton)
                    
                    if let secondaryButton = type.secondaryButton {
                        TrackingButton(text: secondaryButton)
                    }
                    
                    Spacer()
                }
            }
            .padding(MaterialSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                        themeManager?.colors.primaryContainer ?? Color.blue.opacity(0.1) :
                        surfaceColor
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ?
                                themeManager?.colors.primary ?? Color.blue :
                                outlineColor,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tracking Button Component

private struct TrackingButton: View {
    let text: String
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        Text(text)
            .vagFont(size: 12, weight: .medium)
            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            .padding(.horizontal, MaterialSpacing.md)
            .padding(.vertical, MaterialSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
            )
    }
}

// MARK: - Data Model

struct ExerciseType {
    let name: String
    let description: String
    let primaryButton: String
    let secondaryButton: String?
    let iconResId: String
}