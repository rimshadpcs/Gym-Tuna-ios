//
//  WorkoutScreen.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import SwiftUI

struct WorkoutScreen: View {
    @Environment(\.themeManager) private var themeManager
    @StateObject private var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    let routineId: String?
    let routineName: String
    let onBack: () -> Void
    let onFinish: () -> Void
    let onAddExercise: () -> Void
    let onReplaceExercise: () -> Void
    let onNavigateToSubscription: () -> Void
    
    // State for UI controls
    @State private var initialized = false
    @State private var currentActiveSetIndex: (Int, Int)? = nil // Exercise index, Set index
    @State private var showFinishDialog = false
    @State private var showQuickWorkoutFinishDialog = false
    @State private var showDiscardConfirmationDialog = false
    @State private var workoutCompletionStatus: WorkoutCompletionStatus? = nil
    @State private var showErrorDialog: String? = nil
    @State private var exerciseExpandStates: [String: Bool] = [:]
    @State private var showExerciseAddedFeedback = false
    @State private var addedExerciseName = ""
    
    init(
        routineId: String? = nil,
        routineName: String,
        onBack: @escaping () -> Void,
        onFinish: @escaping () -> Void,
        onAddExercise: @escaping () -> Void,
        onReplaceExercise: @escaping () -> Void,
        onNavigateToSubscription: @escaping () -> Void
    ) {
        self.routineId = routineId
        self.routineName = routineName
        self.onBack = onBack
        self.onFinish = onFinish
        self.onAddExercise = onAddExercise
        self.onReplaceExercise = onReplaceExercise
        self.onNavigateToSubscription = onNavigateToSubscription
        
        // Initialize WorkoutViewModel with dependencies
        self._viewModel = StateObject(wrappedValue: WorkoutViewModel(
            routineId: routineId,
            routineName: routineName,
            exercises: [],
            workoutSessionManager: WorkoutSessionManager.shared,
            workoutHistoryRepository: WorkoutHistoryRepositoryImpl()
        ))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
            if viewModel.isLoadingRoutine {
                loadingView
            } else {
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Exercise loading progress
                    if viewModel.exerciseLoadingProgress > 0 && viewModel.exerciseLoadingProgress < 1 {
                        ProgressView(value: viewModel.exerciseLoadingProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    
                    
                    // Reorder mode banner
                    if viewModel.isReorderMode {
                        reorderModeBanner
                    }
                    
                    // Workout stats card
                    CompactWorkoutStatsCard(
                        duration: viewModel.workoutDuration,
                        volume: formatVolumeWithUnit(viewModel.totalVolume, viewModel.weightUnit),
                        sets: viewModel.totalSets,
                        isActive: true
                    )
                    
                    // Exercise list or empty state
                    if viewModel.exercises.isEmpty {
                        emptyStateView
                            .onAppear { print("🔴 SHOWING EMPTY STATE - exercises.count: \(viewModel.exercises.count)") }
                    } else {
                        exercisesList
                            .onAppear { print("🟢 SHOWING EXERCISES LIST - exercises.count: \(viewModel.exercises.count)") }
                    }
                    
                    // Bottom buttons
                    bottomButtonsView
                }
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
        .background(themeManager?.colors.background ?? LightThemeColors.background)
        .navigationBarHidden(true)
        .onAppear {
            // Initialize workout FIRST
            initializeWorkout()
            
            // THEN check for pending exercises from ExerciseChannel (similar to Kotlin LaunchedEffect)
            // Use async dispatch to ensure initialization completes first
            DispatchQueue.main.async {
                if ExerciseChannel.shared.hasPendingExercise() {
                    if let exercise = ExerciseChannel.shared.consumeExercise() {
                        print("🏋️ WorkoutScreen: Adding exercise from ExerciseChannel: \(exercise.name)")
                        print("🏋️ WorkoutScreen: Current exercises count before: \(viewModel.exercises.count)")
                        
                        viewModel.addExercise(exercise)
                        
                        print("🏋️ WorkoutScreen: Exercises count after: \(viewModel.exercises.count)")
                        
                        // Show feedback
                        addedExerciseName = exercise.name
                        withAnimation {
                            showExerciseAddedFeedback = true
                        }
                        
                        // Hide feedback after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showExerciseAddedFeedback = false
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showFinishDialog) {
            if let status = workoutCompletionStatus {
                FinishWorkoutBottomSheet(
                    completionStatus: status,
                    isLoading: viewModel.workoutState == .loading,
                    onConfirm: {
                        viewModel.finishWorkout(forceFinish: false) {
                            showFinishDialog = false
                            onFinish()
                        }
                    },
                    onForceFinish: {
                        viewModel.finishWorkout(forceFinish: true) {
                            showFinishDialog = false
                            onFinish()
                        }
                    },
                    onDismiss: {
                        showFinishDialog = false
                        workoutCompletionStatus = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showQuickWorkoutFinishDialog) {
            if let status = workoutCompletionStatus {
                QuickWorkoutFinishBottomSheet(
                    completionStatus: status,
                    routineCount: viewModel.routineCount,
                    isPremium: viewModel.isPremium,
                    onJustFinish: {
                        showQuickWorkoutFinishDialog = false
                        showFinishDialog = true
                    },
                    onSaveAndFinish: { routineName in
                        viewModel.saveAsRoutine(
                            routineName: routineName,
                            onSuccess: {
                                showQuickWorkoutFinishDialog = false
                                showFinishDialog = true
                            },
                            onUpgradeRequired: {
                                showQuickWorkoutFinishDialog = false
                                onNavigateToSubscription()
                            },
                            onError: { errorMessage in
                                showQuickWorkoutFinishDialog = false
                                showErrorDialog = errorMessage
                            }
                        )
                    },
                    onDismiss: {
                        showQuickWorkoutFinishDialog = false
                        workoutCompletionStatus = nil
                    }
                )
            }
        }
        .alert("Error", isPresented: .constant(showErrorDialog != nil)) {
            Button("OK") {
                showErrorDialog = nil
            }
        } message: {
            if let errorMessage = showErrorDialog {
                Text(errorMessage)
            }
        }
        .alert("Discard Workout", isPresented: $showDiscardConfirmationDialog) {
            Button("Cancel", role: .cancel) {
                showDiscardConfirmationDialog = false
            }
            Button("Discard", role: .destructive) {
                viewModel.discardWorkout()
                showDiscardConfirmationDialog = false
                onBack()
            }
        } message: {
            Text("Are you sure you want to discard this workout? All progress will be lost.")
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.blue)
                
                Text("Loading routine...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var headerView: some View {
        HStack {
            // Back button and title
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Text(viewModel.routineName ?? routineName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(.leading, 8)
            }
            
            Spacer()
            
            // Timer and finish button
            HStack(spacing: 16) {
                Text(viewModel.workoutDuration)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Button(action: handleFinishButtonTap) {
                    if viewModel.workoutState == .loading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.primary)
                    } else {
                        Text("Finish")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                )
                .disabled(viewModel.workoutState == .loading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    
    private var reorderModeBanner: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text("Use arrows to reorder exercises")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button("Done") {
                viewModel.exitReorderMode()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.blue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(.gray)
                .opacity(0.6)
            
            VStack(spacing: 8) {
                Text("Get started")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Add an exercise to start your workout")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }
    
    private var exercisesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.exercises.enumerated()), id: \.element.exercise.id) { exerciseIndex, exercise in
                    let allSetsCompleted = !exercise.sets.isEmpty && exercise.sets.allSatisfy { $0.isCompleted }
                    let isExpanded = exerciseExpandStates[exercise.exercise.id] ?? true
                    
                    ExerciseCard(
                        workoutExercise: exercise,
                        weightUnit: viewModel.weightUnit,
                        distanceUnit: viewModel.distanceUnit,
                        exerciseIndex: exerciseIndex,
                        totalExercises: viewModel.exercises.count,
                        isReorderMode: viewModel.isReorderMode,
                        allSetsCompleted: allSetsCompleted,
                        isExpanded: isExpanded,
                        viewModel: viewModel,
                        onExpandedChange: { expanded in
                            exerciseExpandStates[exercise.exercise.id] = expanded
                        },
                        onAddSet: {
                            viewModel.addSet(exercise)
                        },
                        onSetCompleted: { set, isCompleted in
                            handleSetCompleted(exerciseIndex: exerciseIndex, set: set, isCompleted: isCompleted)
                        },
                        onUpdateWeight: { set, weight in
                            viewModel.updateWeight(exercise, set, weight)
                        },
                        onUpdateReps: { set, reps in
                            viewModel.updateReps(exercise, set, reps)
                        },
                        onUpdateDistance: { set, distance in
                            viewModel.updateDistance(exercise, set, distance)
                        },
                        onUpdateTime: { set, time in
                            viewModel.updateTime(exercise, set, time)
                        },
                        onUpdateNotes: { notes in
                            viewModel.updateNotes(exercise, notes)
                        },
                        onDeleteSet: { workoutExercise, setNumber in
                            viewModel.deleteSet(workoutExercise, setNumber)
                        },
                        onArrangeExercise: { workoutExercise in
                            viewModel.arrangeExercise(workoutExercise)
                        },
                        onReplaceExercise: { workoutExercise in
                            viewModel.replaceExercise(workoutExercise)
                            onReplaceExercise()
                        },
                        onAddToSuperset: { workoutExercise in
                            viewModel.addToSuperset(workoutExercise)
                        },
                        onToggleDropset: { workoutExercise in
                            viewModel.toggleDropset(workoutExercise)
                        },
                        onRemoveExercise: { workoutExercise in
                            viewModel.removeExercise(workoutExercise)
                        }
                    )
                    .padding(.horizontal, 0) // Remove extra padding to use full width
                }
            }
            .padding(.horizontal, 4) // Further reduced for maximum width utilization
            .padding(.top, 8)
            .padding(.bottom, 120) // Space for bottom buttons
        }
    }
    
    private var bottomButtonsView: some View {
        VStack(spacing: 12) {
            // Add Exercise Button
            Button(action: onAddExercise) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                    Text("Add Exercise")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                    )
            )
            
            // Discard Workout Button
            Button(action: {
                showDiscardConfirmationDialog = true
            }) {
                Text("Discard Workout")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(themeManager?.colors.background ?? LightThemeColors.background)
    }
    
    // MARK: - Helper Methods
    
    private func initializeWorkout() {
        if !initialized {
            let sessionState = WorkoutSessionManager.shared.getWorkoutState()
            
            switch true {
            case sessionState != nil && routineId == nil:
                viewModel.initializeFromSession()
            case sessionState != nil && routineId != nil && sessionState?.routineId == routineId:
                viewModel.initializeFromSession()
            case routineId != nil:
                viewModel.initializeFromRoutine(routineId!)
            case sessionState != nil:
                viewModel.initializeFromSession()
            default:
                viewModel.initializeQuickWorkout(routineName)
            }
            initialized = true
        }
    }
    
    private func handleFinishButtonTap() {
        workoutCompletionStatus = viewModel.getWorkoutCompletionStatus()
        
        // Check if this is a routine-based workout or quick workout
        let hasRoutineId = routineId != nil || (viewModel.routineName?.contains("Quick") == false)
        
        if hasRoutineId {
            // This is a routine-based workout - don't ask to save as routine
            showFinishDialog = true
        } else {
            // This is a quick workout - ask if they want to save as routine
            showQuickWorkoutFinishDialog = true
        }
    }
    
    private func handleSetCompleted(exerciseIndex: Int, set: ExerciseSet, isCompleted: Bool) {
        // Update the actual set
        viewModel.setCompleted(viewModel.exercises[exerciseIndex], set, isCompleted)
        
        // Find next incomplete set for auto-advance
        if isCompleted {
            currentActiveSetIndex = findNextIncompleteSet()
        }
    }
    
    private func findNextIncompleteSet() -> (Int, Int)? {
        for (exerciseIndex, exercise) in viewModel.exercises.enumerated() {
            for (setIndex, set) in exercise.sets.enumerated() {
                if !set.isCompleted {
                    return (exerciseIndex, setIndex)
                }
            }
        }
        return nil
    }
    
}

// MARK: - Supporting Data Types

// MARK: - Bottom Sheets and Dialogs

struct FinishWorkoutBottomSheet: View {
    @Environment(\.themeManager) private var themeManager
    
    let completionStatus: WorkoutCompletionStatus
    let isLoading: Bool
    let onConfirm: () -> Void
    let onForceFinish: () -> Void
    let onDismiss: () -> Void
    
    private var colors: ThemeColorScheme {
        themeManager?.colors ?? ThemeColorScheme(
            primary: LightThemeColors.primary,
            onPrimary: LightThemeColors.onPrimary,
            secondary: LightThemeColors.secondary,
            onSecondary: LightThemeColors.onSecondary,
            background: LightThemeColors.background,
            onBackground: LightThemeColors.onBackground,
            surface: LightThemeColors.surface,
            onSurface: LightThemeColors.onSurface,
            outline: LightThemeColors.outline,
            primaryContainer: LightThemeColors.primaryContainer,
            onPrimaryContainer: LightThemeColors.onPrimaryContainer,
            surfaceVariant: LightThemeColors.surfaceVariant,
            onSurfaceVariant: LightThemeColors.onSurfaceVariant,
            error: LightThemeColors.error,
            shadow: LightThemeColors.shadow
        )
    }
    
    var body: some View {
        VStack(spacing: MaterialSpacing.xl) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill((colors.onSurfaceVariant ?? colors.onSurface).opacity(0.4))
                .frame(width: 36, height: 5)
            
            VStack(spacing: MaterialSpacing.lg) {
                // Header with icon
                VStack(spacing: MaterialSpacing.md) {
                    // Success/Warning Icon
                    ZStack {
                        Circle()
                            .fill(completionStatus.isFullyCompleted ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: completionStatus.isFullyCompleted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(completionStatus.isFullyCompleted ? .green : .orange)
                    }
                    
                    Text(completionStatus.isFullyCompleted ? "Workout Complete!" : "Finish Workout?")
                        .font(MaterialTypography.headline6)
                        .foregroundColor(colors.onSurface)
                        .multilineTextAlignment(.center)
                }
                
                // Completion details
                VStack(spacing: MaterialSpacing.sm) {
                    // Progress summary
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sets Completed")
                                .font(MaterialTypography.caption)
                                .foregroundColor(colors.onSurfaceVariant)
                            Text("\(completionStatus.completedSets) of \(completionStatus.totalSets)")
                                .font(MaterialTypography.subtitle2)
                                .foregroundColor(colors.onSurface)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Exercises")
                                .font(MaterialTypography.caption)
                                .foregroundColor(colors.onSurfaceVariant)
                            Text("\(completionStatus.completedExercises.count) of \(completionStatus.totalExercises)")
                                .font(MaterialTypography.subtitle2)
                                .foregroundColor(colors.onSurface)
                        }
                    }
                    .padding(MaterialSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill((colors.surfaceVariant ?? colors.surface).opacity(0.5))
                    )
                    
                    // Warning message for incomplete workout
                    if !completionStatus.isFullyCompleted {
                        HStack(spacing: MaterialSpacing.sm) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                                .font(.system(size: 16))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Incomplete Workout")
                                    .font(MaterialTypography.subtitle2)
                                    .foregroundColor(colors.onSurface)
                                
                                if completionStatus.incompleteExercises.count == 1 {
                                    Text("1 exercise with incomplete sets")
                                        .font(MaterialTypography.body2)
                                        .foregroundColor(colors.onSurfaceVariant)
                                } else {
                                    Text("\(completionStatus.incompleteExercises.count) exercises with incomplete sets")
                                        .font(MaterialTypography.body2)
                                        .foregroundColor(colors.onSurfaceVariant)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(MaterialSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                
                // Action buttons
                VStack(spacing: MaterialSpacing.md) {
                    // Primary action button
                    Button(action: {
                        if completionStatus.isFullyCompleted {
                            onConfirm()
                        } else {
                            onForceFinish()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(colors.onPrimary)
                            } else {
                                Image(systemName: completionStatus.isFullyCompleted ? "checkmark" : "flag.fill")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(completionStatus.isFullyCompleted ? "Finish Workout" : "Finish Anyway")
                                .font(MaterialTypography.button)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(colors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaterialSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colors.primary)
                        )
                    }
                    .disabled(isLoading)
                    
                    // Cancel button
                    Button("Cancel") {
                        onDismiss()
                    }
                    .font(MaterialTypography.button)
                    .fontWeight(.medium)
                    .foregroundColor(colors.onSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MaterialSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colors.outline, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colors.surface)
                            )
                    )
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(MaterialSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colors.surface)
        )
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.hidden)
    }
}

struct QuickWorkoutFinishBottomSheet: View {
    @Environment(\.themeManager) private var themeManager
    
    let completionStatus: WorkoutCompletionStatus
    let routineCount: Int
    let isPremium: Bool
    let onJustFinish: () -> Void
    let onSaveAndFinish: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var routineName = ""
    
    private var colors: ThemeColorScheme {
        themeManager?.colors ?? ThemeColorScheme(
            primary: LightThemeColors.primary,
            onPrimary: LightThemeColors.onPrimary,
            secondary: LightThemeColors.secondary,
            onSecondary: LightThemeColors.onSecondary,
            background: LightThemeColors.background,
            onBackground: LightThemeColors.onBackground,
            surface: LightThemeColors.surface,
            onSurface: LightThemeColors.onSurface,
            outline: LightThemeColors.outline,
            primaryContainer: LightThemeColors.primaryContainer,
            onPrimaryContainer: LightThemeColors.onPrimaryContainer,
            surfaceVariant: LightThemeColors.surfaceVariant,
            onSurfaceVariant: LightThemeColors.onSurfaceVariant,
            error: LightThemeColors.error,
            shadow: LightThemeColors.shadow
        )
    }
    
    private var canSaveAsRoutine: Bool {
        isPremium || routineCount < 3
    }
    
    var body: some View {
        VStack(spacing: MaterialSpacing.xl) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill((colors.onSurfaceVariant ?? colors.onSurface).opacity(0.4))
                .frame(width: 36, height: 5)
            
            VStack(spacing: MaterialSpacing.lg) {
                // Header with icon
                VStack(spacing: MaterialSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "folder.fill.badge.plus")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Save as Routine?")
                        .font(MaterialTypography.headline6)
                        .foregroundColor(colors.onSurface)
                        .multilineTextAlignment(.center)
                    
                    Text("Great workout! Save this as a routine for future sessions.")
                        .font(MaterialTypography.body2)
                        .foregroundColor(colors.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                
                // Routine name input or upgrade message
                if canSaveAsRoutine {
                    VStack(spacing: MaterialSpacing.sm) {
                        HStack {
                            Text("Routine Name")
                                .font(MaterialTypography.subtitle2)
                                .foregroundColor(colors.onSurface)
                            Spacer()
                        }
                        
                        TextField("Enter routine name", text: $routineName)
                            .font(MaterialTypography.body1)
                            .padding(MaterialSpacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colors.outline, lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colors.surface)
                                    )
                            )
                            .foregroundColor(colors.onSurface)
                    }
                } else {
                    VStack(spacing: MaterialSpacing.sm) {
                        HStack(spacing: MaterialSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 16))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Routine Limit Reached")
                                    .font(MaterialTypography.subtitle2)
                                    .foregroundColor(colors.onSurface)
                                
                                Text("You have \(routineCount)/3 routines. Upgrade to Premium for unlimited routines.")
                                    .font(MaterialTypography.body2)
                                    .foregroundColor(colors.onSurfaceVariant)
                            }
                            
                            Spacer()
                        }
                        .padding(MaterialSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                
                // Action buttons
                VStack(spacing: MaterialSpacing.md) {
                    if canSaveAsRoutine {
                        // Save & Finish button
                        Button(action: {
                            onSaveAndFinish(routineName)
                        }) {
                            HStack {
                                Image(systemName: "folder.fill.badge.plus")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Save & Finish")
                                    .font(MaterialTypography.button)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(colors.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MaterialSpacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colors.primary)
                            )
                        }
                        .disabled(routineName.isEmpty)
                    }
                    
                    // Just Finish button
                    Button("Just Finish") {
                        onJustFinish()
                    }
                    .font(MaterialTypography.button)
                    .fontWeight(.medium)
                    .foregroundColor(colors.onSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MaterialSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colors.outline, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colors.surface)
                            )
                    )
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(MaterialSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colors.surface)
        )
        .presentationDetents([.height(canSaveAsRoutine ? 450 : 400)])
        .presentationDragIndicator(.hidden)
    }
}