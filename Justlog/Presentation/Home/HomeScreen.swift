//
//  HomeScreen.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI

struct HomeScreen: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var workoutSessionManager: WorkoutSessionManager
    @Environment(\.themeManager) private var themeManager
    
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
        onNavigateToRoutinePreview: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
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
            (themeManager?.colors.background ?? LightThemeColors.background)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                TopBarView(
                    greeting: viewModel.greeting,
                    formattedDate: viewModel.formattedDate,
                    onSettingsClick: onNavigateToSettings
                )
                .padding(.horizontal, MaterialSpacing.screenHorizontal)
                .padding(.top, MaterialSpacing.md)
                
                // Main Content
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Weekly Calendar Strip
                        WeeklyCalendarStrip(
                            weekDates: viewModel.weekDates,
                            selectedDate: viewModel.selectedDate,
                            onDateSelected: viewModel.selectDate,
                            onHistoryClick: onNavigateToHistory
                        )
                        .padding(.horizontal, MaterialSpacing.screenHorizontal)
                        
                        // Quick Actions Section
                        QuickActionsSection(
                            onStartEmptyWorkout: onStartEmptyWorkout,
                            onNewRoutine: onNewRoutine,
                            onNavigateToCounter: onNavigateToCounter
                        )
                        .padding(.horizontal, MaterialSpacing.screenHorizontal)
                        
                        // My Routines Section
                        VStack(spacing: MaterialSpacing.lg) {
                            // Section Header
                            HStack {
                                Text("My Routines")
                                    .vagFont(size: 18, weight: .bold)
                                    .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                                
                                Spacer()
                            }
                            .padding(.horizontal, MaterialSpacing.screenHorizontal)
                            
                            // Workouts List
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .padding(.vertical, 40)
                            } else if viewModel.filteredWorkouts.isEmpty {
                                EmptyRoutinesState(onNewRoutine: onNewRoutine)
                                    .padding(.horizontal, MaterialSpacing.screenHorizontal)
                            } else {
                                LazyVStack(spacing: MaterialSpacing.sm) {
                                    ForEach(viewModel.filteredWorkouts) { workout in
                                        WorkoutItemView(
                                            workout: workout,
                                            onStartClick: { onStartRoutine(workout.id) },
                                            onRoutineNameClick: { onNavigateToRoutinePreview(workout.id) },
                                            onDuplicateClick: { viewModel.duplicateWorkout(workout.id) },
                                            onEditClick: { onEditRoutine(workout.id) },
                                            onDeleteClick: { viewModel.deleteWorkout(workout.id) }
                                        )
                                        .padding(.horizontal, MaterialSpacing.screenHorizontal)
                                    }
                                    
                                    // Hidden routines prompt for free users
                                    if viewModel.hiddenWorkoutCount > 0 {
                                        HiddenRoutinesPrompt(
                                            hiddenCount: viewModel.hiddenWorkoutCount,
                                            onUpgrade: {
                                                // TODO: Navigate to subscription
                                            }
                                        )
                                        .padding(.horizontal, MaterialSpacing.screenHorizontal)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, viewModel.activeWorkout != nil ? 100 : MaterialSpacing.lg)
                }
            }
            
            // Bottom Workout Banner
            if let activeWorkout = viewModel.activeWorkout {
                VStack {
                    Spacer()
                    BottomWorkoutBanner(
                        workout: activeWorkout,
                        onResumeClick: { onNavigateToWorkout(activeWorkout.id, activeWorkout.name) },
                        onDiscardClick: viewModel.endActiveWorkout
                    )
                    .id(activeWorkout.id) // Add ID to prevent unnecessary redraws
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.activeWorkout?.id)
        .alert("Workout Conflict", isPresented: $viewModel.showConflictDialog) {
            Button("Resume Current") {
                viewModel.resolveConflict(replaceActive: false)
                if let activeWorkout = viewModel.activeWorkout {
                    onNavigateToWorkout(activeWorkout.id, activeWorkout.name)
                }
            }
            
            Button("Start New", role: .destructive) {
                viewModel.resolveConflict(replaceActive: true)
                if let conflictWorkout = viewModel.conflictWorkout {
                    onNavigateToWorkout(conflictWorkout.id, conflictWorkout.name)
                }
            }
            
            Button("Cancel", role: .cancel) {
                viewModel.dismissConflictDialog()
            }
        } message: {
            if let activeWorkout = viewModel.activeWorkout,
               let conflictWorkout = viewModel.conflictWorkout {
                Text("You have an active workout '\(activeWorkout.name)'. What would you like to do?")
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            AnalyticsManager.shared.logScreenView(screenName: "Home")
        }
    }
    
    // MARK: - EmptyRoutinesState Component
    struct EmptyRoutinesState: View {
        @Environment(\.themeManager) private var themeManager
        let onNewRoutine: () -> Void
        
        var body: some View {
            VStack(spacing: MaterialSpacing.lg) {
                Image(systemName: "dumbbell")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.5) ?? LightThemeColors.onSurface.opacity(0.5))
                
                Text("No routines yet")
                    .vagFont(size: 18, weight: .medium)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                
                Text("Create your first workout routine to get started with your fitness journey.")
                    .vagFont(size: 14, weight: .regular)
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.7) ?? LightThemeColors.onSurface.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Button("Create Routine") {
                    onNewRoutine()
                }
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MaterialSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                        )
                )
                .buttonStyle(.plain)
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - HiddenRoutinesPrompt Component
    struct HiddenRoutinesPrompt: View {
        @Environment(\.themeManager) private var themeManager
        let hiddenCount: Int
        let onUpgrade: () -> Void
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .foregroundColor(themeManager?.colors.onSurface ?? .black)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text("You need to upgrade to use more routines")
                        .vagFont(size: 14, weight: .medium)
                        .foregroundColor(themeManager?.colors.onSurface ?? .black)
                }

                Spacer()

                Button(action: onUpgrade) {
                    Text("Upgrade")
                        .vagFont(size: 13, weight: .medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(themeManager?.colors.onSurface ?? .black)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager?.colors.surface ?? Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager?.colors.onSurface ?? .black, lineWidth: 1)
                    )
            )
        }

    }
}
