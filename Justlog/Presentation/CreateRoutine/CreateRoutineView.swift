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
    
    private let routineId: String?
    
    
    init(
        workoutRepository: WorkoutRepository,
        authRepository: AuthRepository,
        subscriptionRepository: SubscriptionRepository,
        routineId: String? = nil,
        existingViewModel: CreateRoutineViewModel? = nil,
        onBack: @escaping () -> Void,
        onRoutineCreated: @escaping () -> Void,
        onAddExercise: @escaping () -> Void,
        onNavigateToSubscription: @escaping () -> Void
    ) {
        self.routineId = routineId
        
        // IMPORTANT: Always use existing ViewModel if provided to avoid creating duplicates
        if let existing = existingViewModel {
            print("🔄 CreateRoutineView: Using existing ViewModel: \(Unmanaged.passUnretained(existing).toOpaque())")
            print("🔄 CreateRoutineView: Existing ViewModel has name: '\(existing.routineName)', exercises: \(existing.selectedExercises.count)")
            self._viewModel = StateObject(wrappedValue: existing)
        } else {
            print("✨ CreateRoutineView: Creating new ViewModel for routineId: \(routineId ?? "new") - THIS SHOULD RARELY HAPPEN")
            let viewModel = CreateRoutineViewModel(
                workoutRepository: workoutRepository,
                authRepository: authRepository,
                subscriptionRepository: subscriptionRepository,
                routineId: routineId
            )
            self._viewModel = StateObject(wrappedValue: viewModel)
        }
        
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
                    print("🏗️ CreateRoutineView: View onAppear called")
                    print("🏗️ ViewModel instance: \(Unmanaged.passUnretained(viewModel).toOpaque())")
                    print("🏗️ Current routineName: '\(viewModel.routineName)'")
                    print("🏗️ Current exercises count: \(viewModel.selectedExercises.count)")
                    print("🏗️ Exercise details: \(viewModel.selectedExercises.map { $0.name })")
                    // Check for pending exercises when view appears (e.g., returning from exercise selection)
                    viewModel.onAppear()
                }
                .onChange(of: viewModel.lastAddedExercise) { exercise in
                    // Show feedback when a new exercise is added
                    print("🔄 onChange lastAddedExercise triggered: \(exercise?.name ?? "nil")")
                    if let exercise = exercise {
                        print("🔄 Showing feedback for: \(exercise.name)")
                        addedExerciseName = exercise.name
                        showExerciseAddedFeedback = true
                        
                        // Hide feedback after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showExerciseAddedFeedback = false
                        }
                    }
                }
                .onChange(of: viewModel.selectedExercises) { exercises in
                    print("🔄 onChange selectedExercises triggered: \(exercises.count) exercises")
                    print("🔄 Exercise names: \(exercises.map { $0.name })")
                }
                .onChange(of: viewModel.routineName) { name in
                    print("🔄 onChange routineName triggered: '\(name)' (instance: \(Unmanaged.passUnretained(viewModel).toOpaque()))")
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
        .sheet(isPresented: $viewModel.showPremiumBenefits) {
            PremiumUpgradeDialog(
                onDismiss: { viewModel.hidePremiumBenefits() },
                onUpgrade: {
                    viewModel.hidePremiumBenefits()
                    onNavigateToSubscription()
                },
                title: "Ready for More Routines?",
                message: "You've created 3 amazing routines! Ready to unlock unlimited routines and premium features?"
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
                .onChange(of: viewModel.routineName) { newValue in
                    print("🏷️ TextField onChange: '\(newValue)'")
                }
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