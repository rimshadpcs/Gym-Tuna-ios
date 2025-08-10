//
//  CreateExerciseViewModel.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 09/08/2025.
//

import Foundation
import Combine
import os.log

@MainActor
class CreateExerciseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedMuscleGroup: String = ""
    @Published var selectedExerciseType: String = ""
    @Published var isSaving: Bool = false
    @Published var subscription: UserSubscription = UserSubscription()
    @Published var customExerciseCount: Int = 0
    @Published var exerciseLimitStatus: String = ""
    @Published var showPremiumBenefits: Bool = false
    
    // MARK: - Private Properties
    private let workoutRepository: WorkoutRepository
    private let authRepository: AuthRepository
    private let subscriptionRepository: SubscriptionRepository
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.justlog.app", category: "CreateExerciseViewModel")
    
    // MARK: - Initialization
    init(
        workoutRepository: WorkoutRepository,
        authRepository: AuthRepository,
        subscriptionRepository: SubscriptionRepository
    ) {
        self.workoutRepository = workoutRepository
        self.authRepository = authRepository
        self.subscriptionRepository = subscriptionRepository
        
        Task {
            await loadSubscriptionStatus()
            await loadCustomExerciseCount()
        }
    }
    
    // MARK: - Public Methods
    
    func setSelectedMuscleGroup(_ muscleGroup: String) {
        selectedMuscleGroup = muscleGroup
        logger.info("Selected muscle group: \(muscleGroup)")
    }
    
    func setSelectedExerciseType(_ exerciseType: String) {
        selectedExerciseType = exerciseType
        logger.info("Selected exercise type: \(exerciseType)")
    }
    
    func createExercise(
        name: String,
        onSuccess: @escaping (Exercise) -> Void,
        onError: @escaping (String) -> Void
    ) {
        Task {
            isSaving = true
            
            do {
                // Check premium limits first
                if !canCreateCustomExercise() {
                    logger.info("Custom exercise limit reached, showing premium benefits")
                    showPremiumBenefits = true
                    isSaving = false
                    return
                }
                
                // Check if user is authenticated
                guard let currentUser = try await authRepository.getCurrentUser() else {
                    logger.error("❌ User not authenticated in CreateExerciseViewModel")
                    throw RepositoryError.userNotAuthenticated
                }
                
                logger.info("👤 User authenticated: \(currentUser.id)")
                
                // Generate default values based on exercise type
                let defaults = getExerciseTypeDefaults(selectedExerciseType)
                
                // Extract main muscle group name (without parentheses)
                let muscleGroup = selectedMuscleGroup.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? selectedMuscleGroup
                
                // Create the exercise
                let exercise = Exercise(
                    id: UUID().uuidString,
                    name: name,
                    muscleGroup: muscleGroup,
                    equipment: getEquipmentFromExerciseType(selectedExerciseType),
                    defaultReps: defaults.defaultReps,
                    defaultSets: defaults.defaultSets,
                    isBodyweight: defaults.isBodyweight,
                    usesWeight: defaults.usesWeight,
                    tracksDistance: defaults.tracksDistance,
                    isTimeBased: defaults.isTimeBased,
                    description: "Custom exercise created by user"
                )
                
                try await workoutRepository.createCustomExercise(exercise)
                
                // Update count after successful creation
                customExerciseCount += 1
                updateExerciseLimitStatus()
                
                logger.info("Successfully created custom exercise: \(exercise.name)")
                onSuccess(exercise)
                
            } catch {
                let errorMsg = error.localizedDescription
                logger.error("❌ Error creating exercise: \(errorMsg)")
                logger.error("❌ Full error: \(error)")
                
                if errorMsg.contains("permission") || errorMsg.contains("denied") || errorMsg.contains("PERMISSION_DENIED") {
                    onError("Permission denied. Please check authentication and try again.")
                } else if errorMsg.contains("UNAUTHENTICATED") {
                    onError("Please sign in and try again.")
                } else {
                    onError("Failed to save exercise: \(errorMsg)")
                }
            }
            
            isSaving = false
        }
    }
    
    func refreshSubscriptionStatus() {
        Task {
            await loadSubscriptionStatus()
            await loadCustomExerciseCount()
        }
    }
    
    func resetPremiumBenefitsNavigation() {
        showPremiumBenefits = false
    }
    
    // MARK: - Private Methods
    
    private func loadSubscriptionStatus() async {
        do {
            let subscriptionPublisher = try await subscriptionRepository.getUserSubscription()
            subscriptionPublisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.logger.error("Error loading subscription: \(error.localizedDescription)")
                            self?.subscription = UserSubscription()
                        }
                    },
                    receiveValue: { [weak self] subscription in
                        self?.subscription = subscription
                        self?.updateExerciseLimitStatus()
                        self?.logger.info("Subscription loaded - isPremium: \(subscription.tier == .premium && subscription.isActive)")
                    }
                )
                .store(in: &cancellables)
        } catch {
            logger.error("Error getting subscription publisher: \(error.localizedDescription)")
            subscription = UserSubscription()
        }
    }
    
    private func loadCustomExerciseCount() async {
        do {
            guard let userId = try await authRepository.getCurrentUser()?.id else { return }
            let count = try await workoutRepository.getCustomExerciseCount(userId: userId)
            customExerciseCount = count
            updateExerciseLimitStatus()
            logger.info("Custom exercise count loaded: \(count)")
        } catch {
            logger.error("Error loading custom exercise count: \(error.localizedDescription)")
            customExerciseCount = 0
        }
    }
    
    private func updateExerciseLimitStatus() {
        let isPremium = subscription.tier == .premium && subscription.isActive
        
        if isPremium {
            exerciseLimitStatus = ""
            return
        }
        
        let count = self.customExerciseCount
        let maxFree = 10
        
        switch count {
        case 0:
            exerciseLimitStatus = "\(count)/\(maxFree) custom exercises used"
        case 1..<maxFree:
            exerciseLimitStatus = "\(count)/\(maxFree) custom exercises used"
        case maxFree - 1:
            exerciseLimitStatus = "⚠️ Last free custom exercise remaining!"
        default:
            exerciseLimitStatus = "Free limit reached (10/10)"
        }
    }
    
    private func canCreateCustomExercise() -> Bool {
        let isPremium = subscription.tier == .premium && subscription.isActive
        
        // Premium users can create unlimited exercises
        if isPremium {
            logger.info("Premium user - unlimited custom exercises allowed")
            return true
        }
        
        // Free users are limited to 10 custom exercises
        let canCreate = self.customExerciseCount < 10
        logger.info("Free user - can create exercise: \(canCreate) (current: \(self.customExerciseCount)/10)")
        return canCreate
    }
    
    private func getExerciseTypeDefaults(_ exerciseType: String) -> ExerciseTypeDefaults {
        switch exerciseType {
        case "Weighted Reps":
            return ExerciseTypeDefaults(defaultReps: 12, defaultSets: 3, isBodyweight: false, usesWeight: true)
        case "Bodyweight Reps":
            return ExerciseTypeDefaults(defaultReps: 12, defaultSets: 3, isBodyweight: true, usesWeight: false)
        case "Weighted Bodyweight":
            return ExerciseTypeDefaults(defaultReps: 12, defaultSets: 3, isBodyweight: true, usesWeight: true)
        case "Assisted Bodyweight":
            return ExerciseTypeDefaults(defaultReps: 10, defaultSets: 3, isBodyweight: true, usesWeight: true)
        case "Duration":
            return ExerciseTypeDefaults(defaultReps: 30, defaultSets: 3, isBodyweight: true, usesWeight: false, isTimeBased: true)
        case "Duration & Weight":
            return ExerciseTypeDefaults(defaultReps: 30, defaultSets: 3, isBodyweight: false, usesWeight: true, isTimeBased: true)
        case "Distance & Duration":
            return ExerciseTypeDefaults(defaultReps: 300, defaultSets: 1, isBodyweight: true, usesWeight: false, isTimeBased: true, tracksDistance: true)
        case "Weight & Distance":
            return ExerciseTypeDefaults(defaultReps: 0, defaultSets: 1, isBodyweight: false, usesWeight: true, tracksDistance: true)
        default:
            return ExerciseTypeDefaults(defaultReps: 10, defaultSets: 3, isBodyweight: false, usesWeight: true)
        }
    }
    
    private func getEquipmentFromExerciseType(_ exerciseType: String) -> String {
        switch exerciseType {
        case "Weighted Reps":
            return "Barbell/Dumbbell"
        case "Bodyweight Reps":
            return "Bodyweight"
        case "Weighted Bodyweight":
            return "Weight Vest/Belt"
        case "Assisted Bodyweight":
            return "Assisted Machine"
        case "Duration":
            return "None"
        case "Duration & Weight":
            return "Weights"
        case "Distance & Duration":
            return "Cardio Equipment"
        case "Weight & Distance":
            return "Weights"
        default:
            return "Other"
        }
    }
    
    // MARK: - Helper Structs
    
    struct ExerciseTypeDefaults {
        let defaultReps: Int
        let defaultSets: Int
        let isBodyweight: Bool
        let usesWeight: Bool
        let isTimeBased: Bool
        let tracksDistance: Bool
        
        init(
            defaultReps: Int,
            defaultSets: Int,
            isBodyweight: Bool,
            usesWeight: Bool,
            isTimeBased: Bool = false,
            tracksDistance: Bool = false
        ) {
            self.defaultReps = defaultReps
            self.defaultSets = defaultSets
            self.isBodyweight = isBodyweight
            self.usesWeight = usesWeight
            self.isTimeBased = isTimeBased
            self.tracksDistance = tracksDistance
        }
    }
}