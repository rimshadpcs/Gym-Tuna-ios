//
//  CreateRoutineViewModel.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation
import Combine

@MainActor
class CreateRoutineViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var routineName: String = "" {
        didSet {
            if oldValue != routineName {
                print("🏷️ routineName changed from '\(oldValue)' to '\(routineName)' (instance: \(Unmanaged.passUnretained(self).toOpaque()))")
                if routineName.isEmpty && !oldValue.isEmpty {
                    print("⚠️ WARNING: routineName was CLEARED! Previous value: '\(oldValue)'")
                    print("⚠️ Stack trace:")
                    Thread.callStackSymbols.prefix(10).forEach { print("  \($0)") }
                }
            }
        }
    }
    @Published var selectedExercises: [Exercise] = [] {
        didSet {
            if oldValue.count != selectedExercises.count {
                print("📋 selectedExercises changed from \(oldValue.count) to \(selectedExercises.count) exercises")
                print("📋 New exercise names: \(selectedExercises.map { $0.name })")
            }
        }
    }
    @Published var showPremiumBenefits: Bool = false
    @Published var routineCount: Int = 0
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedColorHex: String = RoutineColors.colorOptions[0].hex
    @Published var lastAddedExercise: Exercise? = nil
    
    // MARK: - Private Properties
    private let workoutRepository: WorkoutRepository
    private let authRepository: AuthRepository
    private let subscriptionRepository: SubscriptionRepository
    private var cancellables = Set<AnyCancellable>()
    
    // Routine being edited (nil for new routine)
    private var routineId: String?
    
    // MARK: - Initialization
    
    init(workoutRepository: WorkoutRepository, authRepository: AuthRepository, subscriptionRepository: SubscriptionRepository, routineId: String? = nil) {
        print("🏗️ CreateRoutineViewModel: INIT called for routineId: \(routineId ?? "new")")
        self.workoutRepository = workoutRepository
        self.authRepository = authRepository
        self.subscriptionRepository = subscriptionRepository
        self.routineId = routineId
        
        print("🏗️ CreateRoutineViewModel: Instance memory address: \(Unmanaged.passUnretained(self).toOpaque())")
        
        Task {
            await loadInitialData()
            
            // Only initialize routine if we're editing an existing routine
            if let routineId = routineId {
                print("📝 Editing existing routine: \(routineId)")
                print("📝 Current routineName before initialization: '\(self.routineName)'")
                await initializeRoutine(routineId)
                print("📝 Current routineName after initialization: '\(self.routineName)'")
            } else {
                print("✨ Creating new routine")
                print("✨ Current routineName: '\(self.routineName)'")
                print("✨ selectedExercises count: \(self.selectedExercises.count)")
            }
        }
        
        // Initial check for pending exercises
        checkForPendingExercise()
    }
    
    // MARK: - Public Methods
    
    func loadInitialData() async {
        await loadSubscriptionStatus()
        await loadRoutineCount()
    }
    
    func initializeRoutine(_ routineId: String) async {
        isLoading = true
        
        do {
            guard let user = await authRepository.getCurrentUser() else {
                errorMessage = "User not authenticated"
                return
            }
            
            // Get the specific routine
            let workoutsPublisher = try await workoutRepository.getWorkouts(userId: user.id)
            
            // Subscribe to get the first value
            var cancellable: AnyCancellable?
            cancellable = workoutsPublisher
                .sink(
                    receiveCompletion: { _ in
                        cancellable?.cancel()
                    },
                    receiveValue: { [weak self] workouts in
                        if let routine = workouts.first(where: { $0.id == routineId }) {
                            print("📝 initializeRoutine: Loading existing routine '\(routine.name)'")
                            print("📝 Before setting - routineName: '\(self?.routineName ?? "nil")'")
                            self?.routineName = routine.name
                            print("📝 After setting - routineName: '\(self?.routineName ?? "nil")'")
                            self?.selectedExercises = routine.exercises.map { $0.exercise }
                            print("📝 Loaded \(routine.exercises.count) exercises: \(routine.exercises.map { $0.exercise.name })")
                            self?.selectedColorHex = routine.colorHex ?? RoutineColors.colorOptions[0].hex
                        } else {
                            print("⚠️ initializeRoutine: No routine found with ID \(routineId)")
                        }
                        cancellable?.cancel()
                    }
                )
            
        } catch {
            print("Error loading routine: \(error)")
            errorMessage = "Failed to load routine"
        }
        
        isLoading = false
    }
    
    func setRoutineName(_ name: String) {
        print("🏷️ setRoutineName called with: '\(name)' (instance: \(Unmanaged.passUnretained(self).toOpaque()))")
        print("🏷️ Previous name was: '\(routineName)'")
        routineName = name
        print("🏷️ Name set to: '\(routineName)'")
    }
    
    func addExercise(_ exercise: Exercise) {
        print("➕ CreateRoutineViewModel: Attempting to add exercise: \(exercise.name)")
        print("🔍 Current exercises: \(selectedExercises.map { $0.name })")
        print("🔍 Exercise ID to add: '\(exercise.id)'")
        print("🔍 Existing exercise IDs: \(selectedExercises.map { $0.id })")
        
        // Check for duplicates by ID
        let isDuplicate = selectedExercises.contains { existingExercise in
            let isMatch = existingExercise.id == exercise.id
            if isMatch {
                print("🔍 Found duplicate: '\(existingExercise.id)' == '\(exercise.id)'")
            }
            return isMatch
        }
        
        if !isDuplicate {
            selectedExercises.append(exercise)
            lastAddedExercise = exercise
            print("✅ CreateRoutineViewModel: Exercise added. Total count: \(selectedExercises.count)")
            print("✅ Updated exercise list: \(selectedExercises.map { $0.name })")
        } else {
            print("⚠️ CreateRoutineViewModel: Exercise already exists, skipping")
        }
    }
    
    func removeExercise(_ exercise: Exercise) {
        selectedExercises.removeAll { $0.id == exercise.id }
    }
    
    
    func saveRoutine() async -> Bool {
        guard !routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !selectedExercises.isEmpty else {
            errorMessage = "Please enter a routine name and add at least one exercise"
            return false
        }
        
        // Check subscription limits for new routines (not when editing)
        if routineId == nil {
            let canCreate = await canCreateNewRoutine()
            if !canCreate {
                showPremiumBenefits = true
                return false
            }
        }
        
        do {
            isLoading = true
            
            guard let user = await authRepository.getCurrentUser() else {
                errorMessage = "User not authenticated"
                return false
            }
            
            // Use selected color for new routines, auto-assign if none selected
            let finalColorHex: String
            if routineId == nil {
                // For new routines, use selected color or auto-assign
                if selectedColorHex == RoutineColors.colorOptions[0].hex {
                    finalColorHex = RoutineColors.byIndex(routineCount)
                } else {
                    finalColorHex = selectedColorHex
                }
            } else {
                // For existing routines, keep current color
                finalColorHex = selectedColorHex
            }
                
            let workout = Workout(
                id: routineId ?? UUID().uuidString,
                name: routineName.trimmingCharacters(in: .whitespacesAndNewlines),
                userId: user.id,
                exercises: selectedExercises.enumerated().map { index, exercise in
                    WorkoutExercise(exercise: exercise, sets: [], order: index)
                },
                createdAt: Date(),
                colorHex: finalColorHex
            )
            
            if routineId != nil {
                // Update existing routine
                try await workoutRepository.updateWorkout(workout)
                print("Updated existing routine: \(routineName)")
            } else {
                // Create new routine
                try await workoutRepository.createWorkout(workout)
                print("Created new routine: \(routineName)")
                
                // Analytics: Log routine created
                AnalyticsManager.shared.logRoutineCreated(
                    routineName: routineName,
                    exerciseCount: selectedExercises.count
                )
                
                // Update routine count after successful creation
                routineCount += 1
            }
            
            return true
            
        } catch {
            print("Error saving routine: \(error)")
            errorMessage = "Failed to save routine"
            return false
        }
    }
    
    func showPremiumBenefitsAction() {
        showPremiumBenefits = true
    }
    
    func hidePremiumBenefits() {
        showPremiumBenefits = false
    }
    
    func checkForPendingExercise() {
        print("🔍 checkForPendingExercise called")
        let hasPending = ExerciseChannel.shared.hasPendingExercise()
        print("🔍 Has pending exercise: \(hasPending)")
        
        if hasPending {
            let result = ExerciseChannel.shared.consumeExercise()
            if let exercise = result.exercise {
                print("📥 CreateRoutineViewModel: Processing pending exercise from channel: \(exercise.name) - isReplacement: \(result.isReplacement)")
                print("📥 Exercise ID: '\(exercise.id)'")
                print("📥 Before adding - current exercises count: \(selectedExercises.count)")
                
                // Note: CreateRoutineViewModel doesn't handle replacements, only additions
                if !result.isReplacement {
                    addExercise(exercise)
                    print("📥 After adding - current exercises count: \(selectedExercises.count)")
                } else {
                    print("⚠️ CreateRoutineViewModel: Ignoring replacement request (not supported in routine creation)")
                }
            } else {
                print("⚠️ hasPendingExercise was true but consumeExercise returned nil")
            }
        } else {
            print("🔍 No pending exercises found")
        }
    }
    
    func onAppear() {
        print("👀 CreateRoutineViewModel: View appeared (instance: \(Unmanaged.passUnretained(self).toOpaque()))")
        print("👀 Current state - routineName: '\(routineName)', selectedExercises: \(selectedExercises.count)")
        print("👀 Exercise names: \(selectedExercises.map { $0.name })")
        print("👀 Checking for pending exercises...")
        checkForPendingExercise()
    }
    
    func refreshSubscriptionStatus() async {
        await loadSubscriptionStatus()
        await loadRoutineCount()
    }
    
    // MARK: - Private Methods
    
    private func loadSubscriptionStatus() async {
        do {
            let subscriptionPublisher = try await subscriptionRepository.getUserSubscription()
            subscriptionPublisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] subscription in
                        self?.isPremium = subscription.tier == .premium && subscription.isActive
                        print("Subscription loaded - isPremium: \(subscription.tier == .premium && subscription.isActive)")
                    }
                )
                .store(in: &cancellables)
        } catch {
            print("Error loading subscription: \(error)")
            isPremium = false
        }
    }
    
    private func loadRoutineCount() async {
        do {
            guard let user = await authRepository.getCurrentUser() else { return }
            
            let count = try await workoutRepository.getWorkoutCount(userId: user.id)
            routineCount = count
            print("Routine count loaded: \(routineCount)")
        } catch {
            print("Error loading routine count: \(error)")
            routineCount = 0
        }
    }
    
    
    private func canCreateNewRoutine() async -> Bool {
        // Premium users can create unlimited routines
        if isPremium {
            print("Premium user - unlimited routines allowed")
            return true
        }
        
        // Free users are limited to 3 routines
        let canCreate = routineCount < 3
        print("Free user - can create routine: \(canCreate) (current: \(routineCount)/3)")
        return canCreate
    }
}