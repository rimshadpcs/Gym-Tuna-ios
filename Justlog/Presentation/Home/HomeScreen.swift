//
//  HomeScreen.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//


// Presentation/Home/HomeScreen.swift
import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel: HomeViewModel
    @ObservedObject private var workoutSessionManager: WorkoutSessionManager
    
    // Navigation actions
    let onSignOut: () -> Void
    let onStartEmptyWorkout: () -> Void
    let onStartRoutine: (String) -> Void
    let onEditRoutine: (String) -> Void
    let onNewRoutine: () -> Void
    let onNavigateToSearch: () -> Void
    let onNavigateToSettings: () -> Void
    let onNavigateToHistory: () -> Void
    let onNavigateToWorkout: (String?, String?) -> Void
    let onNavigateToCounter: () -> Void
    let onNavigateToRoutinePreview: (String) -> Void
    
    // State for conflict dialog
    @State private var showWorkoutConflictDialog = false
    @State private var pendingRoutineId: String?
    @State private var pendingRoutineName: String?
    
    // Computed property for active workout
    private var hasActiveWorkout: Bool {
        workoutSessionManager.getWorkoutState() != nil
    }
    
    init(
        viewModel: HomeViewModel,
        workoutSessionManager: WorkoutSessionManager,
        onSignOut: @escaping () -> Void,
        onStartEmptyWorkout: @escaping () -> Void,
        onStartRoutine: @escaping (String) -> Void,
        onEditRoutine: @escaping (String) -> Void,
        onNewRoutine: @escaping () -> Void,
        onNavigateToSearch: @escaping () -> Void,
        onNavigateToSettings: @escaping () -> Void,
        onNavigateToHistory: @escaping () -> Void,
        onNavigateToWorkout: @escaping (String?, String?) -> Void,
        onNavigateToCounter: @escaping () -> Void,
        onNavigateToRoutinePreview: @escaping (String) -> Void = { _ in }
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.workoutSessionManager = workoutSessionManager
        self.onSignOut = onSignOut
        self.onStartEmptyWorkout = onStartEmptyWorkout
        self.onStartRoutine = onStartRoutine
        self.onEditRoutine = onEditRoutine
        self.onNewRoutine = onNewRoutine
        self.onNavigateToSearch = onNavigateToSearch
        self.onNavigateToSettings = onNavigateToSettings
        self.onNavigateToHistory = onNavigateToHistory
        self.onNavigateToWorkout = onNavigateToWorkout
        self.onNavigateToCounter = onNavigateToCounter
        self.onNavigateToRoutinePreview = onNavigateToRoutinePreview
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar (Material Design spacing)
                TopBarView(onSettingsClick: onNavigateToSettings)
                    .padding(.horizontal, MaterialSpacing.screenHorizontal)
                    .padding(.top, MaterialSpacing.lg)
                
                // Main Content
                ScrollView {
                    LazyVStack(spacing: MaterialSpacing.sectionSpacing) {
                        // Weekly Calendar
                        WeeklyCalendarStrip(
                            weeklyCalendar: viewModel.weeklyCalendar,
                            onHistoryClick: onNavigateToHistory
                        )
                        
                        // Quick Actions
                        QuickActionsSection(
                            onStartEmptyWorkout: handleQuickStart,
                            onNewRoutine: onNewRoutine,
                            onNavigateToCounter: onNavigateToCounter
                        )
                        
                        // My Routines Section
                        VStack(spacing: MaterialSpacing.lg) {
                            // Header
                            HStack {
                                Text("My Routines")
                                    .font(MaterialTypography.headline6)
                                    .foregroundColor(MaterialColors.onBackground)
                                
                                Spacer()
                            }
                            .padding(.horizontal, MaterialSpacing.screenHorizontal)
                            
                            // Workouts List
                            WorkoutsList(
                                workoutState: viewModel.workoutState,
                                onStartWorkout: handleWorkoutStart,
                                onRoutineNameClick: onNavigateToRoutinePreview,
                                onDuplicateWorkout: viewModel.duplicateWorkout,
                                onEditWorkout: { workout in onEditRoutine(workout.id) },
                                onDeleteWorkout: { workout in viewModel.deleteWorkout(workout.id) }
                            )
                        }
                    }
                    .padding(.bottom, hasActiveWorkout ? 100 : MaterialSpacing.lg)
                }
            }
            
            // Bottom Workout Banner
            if hasActiveWorkout {
                VStack {
                    Spacer()
                    BottomWorkoutBanner(
                        workoutSessionManager: workoutSessionManager,
                        onResumeClick: handleResumeWorkout,
                        onDiscardClick: handleDiscardWorkout
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: hasActiveWorkout)
            }
        }
        .sheet(isPresented: $showWorkoutConflictDialog) {
            if let currentSession = workoutSessionManager.getWorkoutState(),
               let pendingName = pendingRoutineName {
                ConflictWorkoutDialog(
                    currentWorkoutName: currentSession.routineName,
                    newWorkoutName: pendingName,
                    onResumeCurrentWorkout: handleResumeCurrentWorkout,
                    onDiscardAndStartNew: handleDiscardAndStartNew,
                    onCancel: handleCancelConflict
                )
            }
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleQuickStart() {
        let currentSession = workoutSessionManager.getWorkoutState()
        if currentSession != nil {
            pendingRoutineId = nil
            pendingRoutineName = "Quick Workout"
            showWorkoutConflictDialog = true
        } else {
            onNavigateToWorkout(nil, "Quick Workout")
        }
    }
    
    private func handleWorkoutStart(_ workoutId: String) {
        guard let workout = getWorkoutById(workoutId) else { return }
        
        let currentSession = workoutSessionManager.getWorkoutState()
        if currentSession != nil {
            pendingRoutineId = workoutId
            pendingRoutineName = workout.name
            showWorkoutConflictDialog = true
        } else {
            onStartRoutine(workoutId)
        }
    }
    
    private func handleResumeWorkout() {
        let sessionState = workoutSessionManager.getWorkoutState()
        
        if let sessionState = sessionState {
            print("🏋️ Session found: \(sessionState.routineName)")
            print("🏋️ Calling onNavigateToWorkout(nil, \(sessionState.routineName))")
            onNavigateToWorkout(nil, sessionState.routineName)
        } else {
            print("❌ No session found for resume!")
        }
    }
    
    private func handleDiscardWorkout() {
        print("🏋️ Discard clicked")
        workoutSessionManager.discardWorkout()
    }
    
    private func handleResumeCurrentWorkout() {
        showWorkoutConflictDialog = false
        pendingRoutineId = nil
        pendingRoutineName = nil
        
        if let currentSession = workoutSessionManager.getWorkoutState() {
            onNavigateToWorkout(nil, currentSession.routineName)
        }
    }
    
    private func handleDiscardAndStartNew() {
        showWorkoutConflictDialog = false
        workoutSessionManager.discardWorkout()
        
        if let routineId = pendingRoutineId {
            onStartRoutine(routineId)
        }
        
        pendingRoutineId = nil
        pendingRoutineName = nil
    }
    
    private func handleCancelConflict() {
        showWorkoutConflictDialog = false
        pendingRoutineId = nil
        pendingRoutineName = nil
    }
    
    // MARK: - Helper Methods
    
    private func getWorkoutById(_ workoutId: String) -> Workout? {
        guard case let .success(workouts) = viewModel.workoutState else { return nil }
        return workouts.first { $0.id == workoutId }
    }
}

// MARK: - WorkoutsList Component
struct WorkoutsList: View {
    let workoutState: WorkoutState
    let onStartWorkout: (String) -> Void
    let onRoutineNameClick: (String) -> Void
    let onDuplicateWorkout: (Workout) -> Void
    let onEditWorkout: (Workout) -> Void
    let onDeleteWorkout: (Workout) -> Void
    
    var body: some View {
        switch workoutState {
        case .success(let workouts):
            if workouts.isEmpty {
                EmptyRoutinesState()
            } else {
                LazyVStack(spacing: MaterialSpacing.sm) {
                    ForEach(workouts) { workout in
                        WorkoutItemView(
                            workout: workout,
                            onStartClick: { onStartWorkout(workout.id) },
                            onRoutineNameClick: { onRoutineNameClick(workout.id) },
                            onDuplicate: { onDuplicateWorkout(workout) },
                            onEdit: { onEditWorkout(workout) },
                            onDelete: { onDeleteWorkout(workout) }
                        )
                        .padding(.horizontal, MaterialSpacing.screenHorizontal)
                    }
                }
            }
            
        case .loading:
            VStack {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading workouts...")
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .frame(height: 200)
            
        case .error(let message):
            VStack(spacing: 16) {
                Text("Error loading workouts")
                    .foregroundColor(.red)
                
                Button("Retry") {
                    // Retry action would be passed from parent
                }
                .buttonStyle(.bordered)
            }
            .frame(height: 200)
            
        case .initial, .idle:
            EmptyView()
        }
    }
}

// MARK: - EmptyRoutinesState Component
struct EmptyRoutinesState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No routines yet")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Create a new routine to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
    }
}