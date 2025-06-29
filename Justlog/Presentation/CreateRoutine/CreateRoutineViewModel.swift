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
    @Published var routineName: String = ""
    @Published var selectedExercises: [Exercise] = []
    @Published var showUpgradeDialog: Bool = false
    @Published var routineCount: Int = 0
    @Published var isPremium: Bool = false
    @Published var routineLimitStatus: String = ""
    private var selectedColorHex: String = RoutineColors.colorOptions[0].hex
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var lastAddedExercise: Exercise? = nil
    
    // MARK: - Private Properties
    private let workoutRepository: WorkoutRepository
    private let authRepository: AuthRepository
    private var cancellables = Set<AnyCancellable>()
    
    // Routine being edited (nil for new routine)
    private var routineId: String?
    
    // MARK: - Initialization
    
    init(workoutRepository: WorkoutRepository, authRepository: AuthRepository, routineId: String? = nil) {
        print("🏗️ CreateRoutineViewModel: Initializing ViewModel for routineId: \(routineId ?? "new")")
        self.workoutRepository = workoutRepository
        self.authRepository = authRepository
        self.routineId = routineId
        
        Task {
            await loadInitialData()
            
            if let routineId = routineId {
                await initializeRoutine(routineId)
            }
        }
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
                            self?.routineName = routine.name
                            self?.selectedExercises = routine.exercises
                            self?.selectedColorHex = routine.colorHex ?? RoutineColors.colorOptions[0].hex
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
        routineName = name
    }
    
    func addExercise(_ exercise: Exercise) {
        print("➕ CreateRoutineViewModel: Attempting to add exercise: \(exercise.name)")
        if !selectedExercises.contains(where: { $0.id == exercise.id }) {
            selectedExercises.append(exercise)
            lastAddedExercise = exercise
            print("✅ CreateRoutineViewModel: Exercise added. Total count: \(selectedExercises.count)")
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
                showUpgradeDialog = true
                return false
            }
        }
        
        do {
            isLoading = true
            
            guard let user = await authRepository.getCurrentUser() else {
                errorMessage = "User not authenticated"
                return false
            }
            
            // Auto-assign color based on routine count for new routines
            let autoColorHex = routineId == nil ? 
                RoutineColors.byIndex(routineCount) : 
                selectedColorHex
                
            let workout = Workout(
                id: routineId ?? UUID().uuidString,
                name: routineName.trimmingCharacters(in: .whitespacesAndNewlines),
                userId: user.id,
                exercises: selectedExercises,
                createdAt: Date(),
                colorHex: autoColorHex
            )
            
            if routineId != nil {
                // Update existing routine
                try await workoutRepository.updateWorkout(workout)
                print("Updated existing routine: \(routineName)")
            } else {
                // Create new routine
                try await workoutRepository.createWorkout(workout)
                print("Created new routine: \(routineName)")
                
                // Update routine count after successful creation
                routineCount += 1
                updateRoutineLimitStatus()
            }
            
            return true
            
        } catch {
            print("Error saving routine: \(error)")
            errorMessage = "Failed to save routine"
            return false
        }
    }
    
    func showUpgradeDialogAction() {
        showUpgradeDialog = true
    }
    
    func hideUpgradeDialog() {
        showUpgradeDialog = false
    }
    
    func refreshSubscriptionStatus() async {
        await loadSubscriptionStatus()
        await loadRoutineCount()
    }
    
    // MARK: - Private Methods
    
    private func loadSubscriptionStatus() async {
        do {
            // TODO: Implement subscription repository when available
            // For now, assume free tier
            isPremium = false
            print("Subscription loaded - isPremium: \(isPremium)")
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
            updateRoutineLimitStatus()
            print("Routine count loaded: \(routineCount)")
        } catch {
            print("Error loading routine count: \(error)")
            routineCount = 0
        }
    }
    
    private func updateRoutineLimitStatus() {
        if isPremium {
            routineLimitStatus = ""
            return
        }
        
        let maxFree = 3
        
        switch routineCount {
        case 0:
            routineLimitStatus = "\(routineCount)/\(maxFree) routines used"
        case 1..<maxFree:
            routineLimitStatus = "\(routineCount)/\(maxFree) routines used"
        case maxFree - 1:
            routineLimitStatus = "⚠️ Last free routine remaining!"
        default:
            routineLimitStatus = "Free limit reached (3/3)"
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