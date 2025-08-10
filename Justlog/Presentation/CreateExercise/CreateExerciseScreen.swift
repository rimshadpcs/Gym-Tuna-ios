//
//  CreateExerciseScreen.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 09/08/2025.
//

import SwiftUI

struct CreateExerciseScreen: View {
    @Environment(\.themeManager) private var themeManager
    @StateObject private var viewModel: CreateExerciseViewModel
    @State private var exerciseName: String = ""
    @State private var showMuscleGroupSelection: Bool = false
    @State private var showExerciseTypeSelection: Bool = false
    @State private var showSnackbar: Bool = false
    @State private var snackbarMessage: String = ""
    @State private var isError: Bool = false
    
    let onBack: () -> Void
    let onSave: (Exercise) -> Void
    let onNavigateToPremiumBenefits: () -> Void
    
    init(
        workoutRepository: WorkoutRepository,
        authRepository: AuthRepository,
        subscriptionRepository: SubscriptionRepository,
        onBack: @escaping () -> Void,
        onSave: @escaping (Exercise) -> Void,
        onNavigateToPremiumBenefits: @escaping () -> Void = {}
    ) {
        self._viewModel = StateObject(wrappedValue: CreateExerciseViewModel(
            workoutRepository: workoutRepository,
            authRepository: authRepository,
            subscriptionRepository: subscriptionRepository
        ))
        self.onBack = onBack
        self.onSave = onSave
        self.onNavigateToPremiumBenefits = onNavigateToPremiumBenefits
    }
    
    private var contentColor: Color {
        themeManager?.colors.onBackground ?? LightThemeColors.onBackground
    }
    
    private var backgroundColor: Color {
        themeManager?.colors.background ?? LightThemeColors.background
    }
    
    private var borderColor: Color {
        themeManager?.colors.outline ?? LightThemeColors.outline
    }
    
    private var secondaryContentColor: Color {
        contentColor.opacity(0.6)
    }
    
    private var isPremium: Bool {
        viewModel.subscription.tier == .premium && viewModel.subscription.isActive
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            if !showMuscleGroupSelection && !showExerciseTypeSelection {
                mainScreen
            } else if showMuscleGroupSelection {
                MuscleGroupSelectionScreen(
                    onBack: { showMuscleGroupSelection = false },
                    onSelect: { muscleGroup in
                        viewModel.setSelectedMuscleGroup(muscleGroup)
                        showMuscleGroupSelection = false
                    },
                    selectedMuscle: viewModel.selectedMuscleGroup
                )
            } else if showExerciseTypeSelection {
                ExerciseTypeSelectionScreen(
                    onBack: { showExerciseTypeSelection = false },
                    onSelect: { exerciseType in
                        viewModel.setSelectedExerciseType(exerciseType)
                        showExerciseTypeSelection = false
                    },
                    selectedType: viewModel.selectedExerciseType
                )
            }
        }
        .onChange(of: viewModel.showPremiumBenefits) { showPremium in
            if showPremium {
                viewModel.resetPremiumBenefitsNavigation()
                onNavigateToPremiumBenefits()
            }
        }
        .onChange(of: showSnackbar) { isShowing in
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showSnackbar = false
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var mainScreen: some View {
        VStack(spacing: 0) {
            // Top App Bar
            topAppBar
            
            // Snackbar
            if showSnackbar {
                snackbarView
                    .padding(.horizontal, MaterialSpacing.screenHorizontal)
                    .padding(.bottom, MaterialSpacing.md)
            }
            
            // Content
            ScrollView {
                LazyVStack(spacing: MaterialSpacing.md) {
                    // Exercise Name
                    exerciseNameField
                        .padding(.horizontal, MaterialSpacing.screenHorizontal)
                    
                    // Primary Muscle Group Selector
                    SelectionField(
                        label: "Primary Muscle Group",
                        value: viewModel.selectedMuscleGroup.isEmpty ? "Select" : viewModel.selectedMuscleGroup,
                        onClick: { showMuscleGroupSelection = true },
                        contentColor: contentColor,
                        borderColor: borderColor
                    )
                    .padding(.horizontal, MaterialSpacing.screenHorizontal)
                    
                    // Exercise Type Selector
                    SelectionField(
                        label: "Exercise Type",
                        value: viewModel.selectedExerciseType.isEmpty ? "Select" : viewModel.selectedExerciseType,
                        onClick: { showExerciseTypeSelection = true },
                        contentColor: contentColor,
                        borderColor: borderColor
                    )
                    .padding(.horizontal, MaterialSpacing.screenHorizontal)
                }
                .padding(.vertical, MaterialSpacing.md)
            }
        }
    }
    
    private var topAppBar: some View {
        HStack(spacing: MaterialSpacing.md) {
            IOSBackButton(action: onBack)
            
            Text("Create Exercise")
                .vagFont(size: 20, weight: .medium)
                .foregroundColor(contentColor)
            
            Spacer()
            
            // Save Button
            Button(action: saveExercise) {
                Group {
                    if viewModel.isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    } else {
                        Text("Save")
                            .vagFont(size: 14, weight: .semibold)
                    }
                }
            }
            .disabled(!canSave || viewModel.isSaving)
            .buttonStyle(.materialSecondary)
            .opacity((canSave && !viewModel.isSaving) ? 1.0 : 0.6)
        }
        .padding(.horizontal, MaterialSpacing.screenHorizontal)
        .padding(.vertical, MaterialSpacing.md)
        .background(themeManager?.colors.surface ?? LightThemeColors.surface)
    }
    
    private var canSave: Bool {
        !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.selectedMuscleGroup.isEmpty &&
        !viewModel.selectedExerciseType.isEmpty
    }
    
    private var exerciseNameField: some View {
        VStack(alignment: .leading, spacing: MaterialSpacing.xs) {
            Text("Exercise Name")
                .vagFont(size: 14, weight: .medium)
                .foregroundColor(contentColor)
            
            TextField("e.g., Barbell Bench Press", text: $exerciseName)
                .textFieldStyle(MaterialTextFieldStyle(
                    themeManager: themeManager,
                    placeholder: "e.g., Barbell Bench Press"
                ))
        }
    }
    
    private var snackbarView: some View {
        HStack(spacing: MaterialSpacing.md) {
            Image(systemName: isError ? "exclamationmark.triangle" : "checkmark")
                .foregroundColor(isError ? 
                    Color.white :
                    themeManager?.colors.onPrimaryContainer ?? Color.white
                )
                .font(.system(size: 16, weight: .medium))
            
            Text(snackbarMessage)
                .vagFont(size: 14, weight: .medium)
                .foregroundColor(isError ?
                    Color.white :
                    themeManager?.colors.onPrimaryContainer ?? Color.white
                )
                .lineLimit(2)
            
            Spacer()
            
            Button(action: { showSnackbar = false }) {
                Image(systemName: "xmark")
                    .foregroundColor(isError ?
                        Color.white :
                        themeManager?.colors.onPrimaryContainer ?? Color.white
                    )
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(MaterialSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isError ?
                    (themeManager?.colors.error ?? Color.red).opacity(0.8) :
                    themeManager?.colors.primaryContainer ?? Color.blue.opacity(0.1)
                )
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity.combined(with: .move(edge: .top))
        ))
    }
    
    private func saveExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        viewModel.createExercise(
            name: trimmedName,
            onSuccess: { exercise in
                snackbarMessage = "Exercise \"\(exercise.name)\" saved successfully!"
                isError = false
                showSnackbar = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onSave(exercise)
                }
            },
            onError: { errorMessage in
                snackbarMessage = errorMessage
                isError = true
                showSnackbar = true
            }
        )
    }
}

// MARK: - Selection Field Component

struct SelectionField: View {
    let label: String
    let value: String
    let onClick: () -> Void
    let contentColor: Color
    let borderColor: Color
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: MaterialSpacing.xs) {
            Text(label)
                .vagFont(size: 14, weight: .medium)
                .foregroundColor(contentColor)
            
            Button(action: onClick) {
                HStack {
                    Text(value)
                        .vagFont(size: 16, weight: .medium)
                        .foregroundColor(contentColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(contentColor)
                }
                .padding(MaterialSpacing.md)
                .frame(height: 56)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(borderColor, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}