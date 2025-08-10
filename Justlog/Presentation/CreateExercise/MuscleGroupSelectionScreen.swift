//
//  MuscleGroupSelectionScreen.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 09/08/2025.
//

import SwiftUI

struct MuscleGroupSelectionScreen: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    
    let onBack: () -> Void
    let onSelect: (String) -> Void
    let selectedMuscle: String
    
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
    
    private let muscleGroups = [
        MuscleGroup(name: "Abdominals (Abs)", lightIconResId: "core", darkIconResId: "core_dark"),
        MuscleGroup(name: "Adductors", lightIconResId: "leg", darkIconResId: "leg_dark"),
        MuscleGroup(name: "Biceps", lightIconResId: "biceps", darkIconResId: "biceps_dark"),
        MuscleGroup(name: "Calves", lightIconResId: "calves", darkIconResId: "calves_dark"),
        MuscleGroup(name: "Delts (Shoulders)", lightIconResId: "shoulders", darkIconResId: "shoulders_dark"),
        MuscleGroup(name: "Forearms", lightIconResId: "forearms", darkIconResId: "forearms_dark"),
        MuscleGroup(name: "Glutes", lightIconResId: "glutes", darkIconResId: "glutes_dark"),
        MuscleGroup(name: "Hamstrings", lightIconResId: "leg", darkIconResId: "leg_dark"),
        MuscleGroup(name: "Lats", lightIconResId: "back", darkIconResId: "back_dark"),
        MuscleGroup(name: "Lower Back", lightIconResId: "back", darkIconResId: "back_dark"),
        MuscleGroup(name: "Obliques", lightIconResId: "core", darkIconResId: "core_dark"),
        MuscleGroup(name: "Chest / Pectoral", lightIconResId: "chest", darkIconResId: "chest_dark"),
        MuscleGroup(name: "Quadriceps", lightIconResId: "leg", darkIconResId: "leg_dark"),
        MuscleGroup(name: "Shoulders", lightIconResId: "shoulders", darkIconResId: "shoulders_dark"),
        MuscleGroup(name: "Spine", lightIconResId: "back", darkIconResId: "back_dark"),
        MuscleGroup(name: "Traps", lightIconResId: "back", darkIconResId: "back_dark"),
        MuscleGroup(name: "Triceps", lightIconResId: "triceps", darkIconResId: "triceps_dark")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            topBar
            
            // Description
            descriptionText
            
            // Muscle group list
            ScrollView {
                LazyVStack(spacing: MaterialSpacing.md) {
                    ForEach(muscleGroups, id: \.name) { muscle in
                        muscleGroupCard(muscle)
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
            
            Text("Select Muscle Group")
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
            Text("Choose the primary muscle targeted by this exercise")
                .vagFont(size: 14, weight: .regular)
                .foregroundColor(contentColor.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, MaterialSpacing.screenHorizontal)
        .padding(.vertical, MaterialSpacing.md)
    }
    
    private func muscleGroupCard(_ muscle: MuscleGroup) -> some View {
        let isSelected = selectedMuscle == muscle.name
        let iconResId = isDarkTheme ? muscle.darkIconResId : muscle.lightIconResId
        
        return Button(action: { onSelect(muscle.name) }) {
            HStack(spacing: MaterialSpacing.md) {
                // Icon with circle background
                ZStack {
                    Circle()
                        .fill(isSelected ?
                            themeManager?.colors.primary.opacity(0.2) ?? Color.blue.opacity(0.2) :
                            contentColor.opacity(0.1)
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(iconResId)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
                
                // Muscle name
                Text(muscle.name)
                    .vagFont(size: 16, weight: isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ?
                        themeManager?.colors.primary ?? Color.blue :
                        contentColor
                    )
                
                Spacer()
                
                // Selected indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(themeManager?.colors.primary ?? Color.blue)
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

// MARK: - Data Model

struct MuscleGroup {
    let name: String
    let lightIconResId: String
    let darkIconResId: String
}