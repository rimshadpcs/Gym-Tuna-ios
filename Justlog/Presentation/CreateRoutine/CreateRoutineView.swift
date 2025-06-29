//
//  CreateRoutineView.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI

struct CreateRoutineView: View {
    @StateObject private var viewModel: CreateRoutineViewModel
    @Environment(\.dismiss) private var dismiss
    
    // UI feedback state
    @State private var showExerciseAddedFeedback = false
    @State private var addedExerciseName = ""
    
    // Navigation callbacks
    let onBack: () -> Void
    let onRoutineCreated: () -> Void
    let onAddExercise: () -> Void
    let onNavigateToSubscription: () -> Void
    @ObservedObject private var createRoutineManager: CreateRoutineManager
    
    private let routineId: String?
    
    
    init(
        workoutRepository: WorkoutRepository,
        authRepository: AuthRepository,
        routineId: String? = nil,
        createRoutineManager: CreateRoutineManager,
        onBack: @escaping () -> Void,
        onRoutineCreated: @escaping () -> Void,
        onAddExercise: @escaping () -> Void,
        onNavigateToSubscription: @escaping () -> Void
    ) {
        self.routineId = routineId
        let viewModel = CreateRoutineViewModel(
            workoutRepository: workoutRepository,
            authRepository: authRepository,
            routineId: routineId
        )
        self._viewModel = StateObject(wrappedValue: viewModel)
        
        self.createRoutineManager = createRoutineManager
        self.onBack = onBack
        self.onRoutineCreated = onRoutineCreated
        self.onAddExercise = onAddExercise
        self.onNavigateToSubscription = onNavigateToSubscription
        
    }
    
    var body: some View {
        ZStack {
            MaterialColors.background
                .ignoresSafeArea()
                .onAppear {
                    print("🏗️ CreateRoutineView: View appeared. Current exercises: \(viewModel.selectedExercises.count)")
                    print("🏗️ CreateRoutineView: Exercise details: \(viewModel.selectedExercises.map { $0.name })")
                    
                    // Set up the manager to call our addExercise function
                    print("🏗️ CreateRoutineView: Setting up addExercise function in manager")
                    createRoutineManager.setAddExerciseFunction { exercise in
                        print("🎯 CreateRoutineView: addExercise closure called for: \(exercise.name)")
                        viewModel.addExercise(exercise)
                        
                        // Note: UI feedback will be handled separately since this is just for the data
                    }
                }
            
            VStack(spacing: 0) {
                // Top navigation bar
                topNavigationBar
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Spacer()
                } else {
                    // Main content
                    ScrollView {
                        VStack(spacing: MaterialSpacing.sectionSpacing) {
                            // Routine name input
                            routineNameSection
                            
                            // Exercise list or empty state
                            exerciseSection
                        }
                        .padding(.horizontal, MaterialSpacing.screenHorizontal)
                        .padding(.top, MaterialSpacing.lg)
                    }
                    
                    // Add exercise button
                    addExerciseButton
                }
            }
            
            // Exercise Added Feedback Overlay
            if showExerciseAddedFeedback {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        
                        Text("Added \(addedExerciseName)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.black.opacity(0.8))
                    )
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .sheet(isPresented: $viewModel.showUpgradeDialog) {
            PremiumUpgradeSheet(
                onDismiss: { viewModel.hideUpgradeDialog() },
                onUpgrade: {
                    viewModel.hideUpgradeDialog()
                    onNavigateToSubscription()
                }
            )
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Top Navigation Bar
    
    private var topNavigationBar: some View {
        HStack {
            // Back button (iOS style)
            IOSBackButton(action: onBack)
            
            Spacer()
            
            // Title and subtitle
            VStack(spacing: MaterialSpacing.xs) {
                Text(routineId != nil ? "Edit Routine" : "Create Routine")
                    .font(MaterialTypography.headline6)
                    .foregroundColor(MaterialColors.onBackground)
                
                // Show routine limit status for free users (only when creating new routine)
                if routineId == nil && !viewModel.isPremium && !viewModel.routineLimitStatus.isEmpty {
                    Text(viewModel.routineLimitStatus)
                        .font(MaterialTypography.caption)
                        .foregroundColor(viewModel.routineCount >= 2 ? .red : .gray)
                }
            }
            
            Spacer()
            
            // Save button
            Button(action: saveRoutine) {
                Text("Save")
                    .font(MaterialTypography.button)
                    .foregroundColor(canSave ? MaterialColors.primary : .gray)
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, MaterialSpacing.screenHorizontal)
        .padding(.vertical, MaterialSpacing.sm)
    }
    
    // MARK: - Routine Name Section
    
    private var routineNameSection: some View {
        VStack(alignment: .leading, spacing: MaterialSpacing.sm) {
            TextField("Routine title", text: $viewModel.routineName)
                .font(MaterialTypography.body1)
                .foregroundColor(MaterialColors.onSurface)
                .padding(MaterialSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                        .stroke(MaterialColors.outline, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .fill(MaterialColors.surface)
                        )
                )
        }
    }
    
    
    // MARK: - Exercise Section
    
    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: MaterialSpacing.lg) {
            Text("Exercises (\(viewModel.selectedExercises.count))")
                .font(MaterialTypography.subtitle1)
                .foregroundColor(MaterialColors.onSurface)
            
            if viewModel.selectedExercises.isEmpty {
                emptyExerciseState
            } else {
                exerciseList
            }
        }
    }
    
    private var emptyExerciseState: some View {
        VStack(spacing: MaterialSpacing.lg) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(MaterialColors.onSurface.opacity(0.5))
            
            Text("Get started by adding an exercise to your routine.")
                .font(MaterialTypography.body1)
                .foregroundColor(MaterialColors.onSurface.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var exerciseList: some View {
        LazyVStack(spacing: MaterialSpacing.sm) {
            ForEach(viewModel.selectedExercises) { exercise in
                SelectedExerciseItem(
                    exercise: exercise,
                    onRemove: { viewModel.removeExercise(exercise) }
                )
            }
        }
    }
    
    // MARK: - Add Exercise Button
    
    private var addExerciseButton: some View {
        Button(action: onAddExercise) {
            HStack(spacing: MaterialSpacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Add exercise")
                    .font(MaterialTypography.button)
            }
            .foregroundColor(MaterialColors.onSurface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MaterialSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: MaterialCornerRadius.extraLarge)
                    .stroke(MaterialColors.outline, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: MaterialCornerRadius.extraLarge)
                            .fill(MaterialColors.surface)
                    )
            )
        }
        .padding(.horizontal, MaterialSpacing.screenHorizontal)
        .padding(.bottom, MaterialSpacing.lg)
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        !viewModel.routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.selectedExercises.isEmpty &&
        !viewModel.isLoading
    }
    
    // MARK: - Actions
    
    private func saveRoutine() {
        Task {
            let success = await viewModel.saveRoutine()
            if success {
                dismiss()
                onRoutineCreated()
            }
        }
    }
}

// MARK: - Selected Exercise Item

struct SelectedExerciseItem: View {
    let exercise: Exercise
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MaterialSpacing.xs) {
                Text(exercise.name)
                    .font(MaterialTypography.subtitle1)
                    .foregroundColor(MaterialColors.onSurface)
                
                Text("\(exercise.muscleGroup) | \(exercise.equipment)")
                    .font(MaterialTypography.body2)
                    .foregroundColor(MaterialColors.onSurface.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MaterialColors.onSurface.opacity(0.7))
            }
        }
        .padding(MaterialSpacing.cardPadding)
        .materialCard()
    }
}

// MARK: - Premium Upgrade Sheet

struct PremiumUpgradeSheet: View {
    let onDismiss: () -> Void
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: MaterialSpacing.sectionSpacing) {
            // Header
            VStack(spacing: MaterialSpacing.lg) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                
                Text("Ready for More Routines?")
                    .font(MaterialTypography.headline5)
                    .foregroundColor(MaterialColors.onSurface)
                    .multilineTextAlignment(.center)
                
                Text("You've reached the free limit of 3 workout routines. Upgrade to Premium to create unlimited routines and unlock all features!")
                    .font(MaterialTypography.body1)
                    .foregroundColor(MaterialColors.onSurface.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: MaterialSpacing.lg) {
                Button(action: onUpgrade) {
                    Text("Upgrade to Premium")
                        .font(MaterialTypography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaterialSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .fill(MaterialColors.primary)
                        )
                }
                .buttonStyle(.materialPrimary)
                
                Button(action: onDismiss) {
                    Text("Maybe Later")
                        .font(MaterialTypography.button)
                        .foregroundColor(MaterialColors.onSurface)
                }
            }
        }
        .padding(MaterialSpacing.sectionSpacing)
        .presentationDetents([.medium])
    }
}

// Preview removed due to dependency injection requirements