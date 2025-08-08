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
        .background(themeManager?.colors.background ?? .white)
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
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 16)
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
                .foregroundColor(.primary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 1)
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
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
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
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
            
            VStack(spacing: 16) {
                Text("Finish Workout")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    Text("Completed \(completionStatus.completedSets)/\(completionStatus.totalSets) sets")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if !completionStatus.isFullyCompleted {
                        Text("Some sets are incomplete. Are you sure you want to finish?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    
                    Button(completionStatus.isFullyCompleted ? "Finish" : "Force Finish") {
                        if completionStatus.isFullyCompleted {
                            onConfirm()
                        } else {
                            onForceFinish()
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue)
                    )
                    .disabled(isLoading)
                }
            }
            
            Spacer()
        }
        .padding(24)
        .presentationDetents([.height(280)])
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
    
    private var canSaveAsRoutine: Bool {
        isPremium || routineCount < 3
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
            
            VStack(spacing: 16) {
                Text("Save as Routine?")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                if canSaveAsRoutine {
                    TextField("Enter routine name", text: $routineName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 16, weight: .regular))
                } else {
                    VStack(spacing: 8) {
                        Text("Routine limit reached")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                        
                        Text("Upgrade to premium to save unlimited routines")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                HStack(spacing: 12) {
                    Button("Just Finish") {
                        onJustFinish()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    
                    if canSaveAsRoutine {
                        Button("Save & Finish") {
                            onSaveAndFinish(routineName)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue)
                        )
                        .disabled(routineName.isEmpty)
                    }
                }
            }
            
            Spacer()
        }
        .padding(24)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.hidden)
    }
}