//
//  WorkoutViewModel.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class WorkoutViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var exercises: [WorkoutExercise] = []
    @Published var currentExerciseIndex: Int = 0
    @Published var workoutDuration: String = "0s"
    @Published var isWorkoutPaused: Bool = false
    @Published var showFinishDialog: Bool = false
    @Published var routineName: String?
    @Published var totalVolume: Double = 0.0
    @Published var totalSets: Int = 0
    @Published var workoutState: ActiveWorkoutState = .initial
    @Published var weightUnit: WeightUnit = .kg
    @Published var distanceUnit: DistanceUnit = .mi
    
    // Loading and progress states
    @Published var isLoadingRoutine: Bool = false
    @Published var exerciseLoadingProgress: Float = 0.0
    
    // Reorder and selection states
    @Published var isReorderMode: Bool = false
    @Published var isReplacingExercise: Bool = false
    @Published var exerciseToReplace: WorkoutExercise? = nil
    
    // Rest timer states
    @Published var isRestTimerRunning: Bool = false
    @Published var restTimerRemaining: Int = 0
    @Published var restTimerTotal: Int = 0
    @Published var isRestTimerPaused: Bool = false
    
    // Save as routine states
    @Published var showSaveAsRoutineDialog: Bool = false
    @Published var showUpdateRoutineDialog: Bool = false
    @Published var routineCount: Int = 0
    @Published var isPremium: Bool = false
    
    // MARK: - Private Properties
    private let workoutSessionManager: WorkoutSessionManager
    private let workoutHistoryRepository: WorkoutHistoryRepository
    private let authRepository: AuthRepository
    private let workoutRepository: WorkoutRepository
    private let subscriptionRepository: SubscriptionRepository
    private let userPreferences: UserPreferences
    private var cancellables = Set<AnyCancellable>()
    private let restTimerManager = RestTimerManager()
    
    // Workout state
    private var startMs = Int64(Date().timeIntervalSince1970 * 1000)
    private var isWorkoutActive = true
    private var currentRoutineId: String?
    private var originalRoutineName: String?
    private var isRoutineModified = false
    private var isInitialized = false
    
    // MARK: - Input Parameters
    private let routineIdParam: String?
    private let routineNameParam: String
    
    // MARK: - Initialization
    init(
        routineId: String?,
        routineName: String,
        exercises: [WorkoutExercise] = [],
        workoutSessionManager: WorkoutSessionManager,
        workoutHistoryRepository: WorkoutHistoryRepository
    ) {
        self.routineIdParam = routineId
        self.routineNameParam = routineName
        self.workoutSessionManager = workoutSessionManager
        self.workoutHistoryRepository = workoutHistoryRepository
        self.routineName = routineName
        
        // Initialize dependencies (these would normally be injected)
        let googleSignInHelper = GoogleSignInHelper()
        self.userPreferences = UserPreferences.shared
        self.authRepository = AuthRepositoryImpl(
            userPreferences: self.userPreferences, 
            googleSignInHelper: googleSignInHelper
        )
        self.workoutRepository = WorkoutRepositoryImpl(authRepository: self.authRepository)
        self.subscriptionRepository = SubscriptionRepositoryImpl()
        
        setupObservers()
        startTimer()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Observe workout session manager
        workoutSessionManager.$workoutDuration
            .receive(on: DispatchQueue.main)
            .assign(to: \.workoutDuration, on: self)
            .store(in: &cancellables)
        
        workoutSessionManager.$isActive
            .receive(on: DispatchQueue.main)
            .map { !$0 }
            .assign(to: \.isWorkoutPaused, on: self)
            .store(in: &cancellables)
        
        // Observe rest timer
        restTimerManager.$timerState
            .map { state in
                switch state {
                case .active: return true
                default: return false
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRestTimerRunning, on: self)
            .store(in: &cancellables)
        
        restTimerManager.$timerState
            .map { state in
                switch state {
                case .active(let remaining, _), .paused(let remaining, _):
                    return Int(remaining)
                default:
                    return 0
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.restTimerRemaining, on: self)
            .store(in: &cancellables)
        
        restTimerManager.$timerState
            .map { state in
                switch state {
                case .active(_, let total), .paused(_, let total):
                    return Int(total)
                default:
                    return 0
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.restTimerTotal, on: self)
            .store(in: &cancellables)
        
        restTimerManager.$timerState
            .map { state in
                switch state {
                case .paused: return true
                default: return false
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isRestTimerPaused, on: self)
            .store(in: &cancellables)
        
        // Observe user preferences
        userPreferences.$weightUnit
            .receive(on: DispatchQueue.main)
            .assign(to: \.weightUnit, on: self)
            .store(in: &cancellables)
        
        userPreferences.$distanceUnit
            .receive(on: DispatchQueue.main)
            .assign(to: \.distanceUnit, on: self)
            .store(in: &cancellables)
        
        loadSubscriptionAndRoutineData()
    }
    
    private func loadSubscriptionAndRoutineData() {
        Task {
            do {
                // Load subscription status
                do {
                    let subscriptionStream = try await subscriptionRepository.getUserSubscription()
                    do {
                        for try await subscription in subscriptionStream.values {
                            isPremium = subscription.tier == .premium && subscription.isActive
                            break
                        }
                    } catch {
                        print("Error iterating subscription stream: \(error)")
                        isPremium = false
                    }
                } catch {
                    print("Error loading subscription: \(error)")
                    isPremium = false
                }
                
                // Load routine count
                if let userId = try await authRepository.getCurrentUser()?.id {
                    routineCount = try await workoutRepository.getWorkoutCount(userId: userId)
                }
            } catch {
                print("Error loading subscription data: \(error)")
            }
        }
    }
    
    // MARK: - Initialization Methods
    
    func initializeFromRoutine(_ routineId: String) {
        guard !isInitialized else { return }
        
        print("🚀 STARTING initializeFromRoutine with routineId: \(routineId)")
        isLoadingRoutine = true
        
        Task {
            do {
                // Load routine
                guard let routine = try await workoutRepository.getWorkoutById(routineId) else {
                    workoutState = .error("Routine not found")
                    return
                }
                
                currentRoutineId = routineId
                originalRoutineName = routine.name
                routineName = routine.name
                
                // Create basic workout exercises with DEFAULT values pre-populated (matching Android)
                let basicWorkoutExercises = routine.exercises.map { workoutExercise in
                    WorkoutExercise(
                        exercise: workoutExercise.exercise,
                        sets: (0..<workoutExercise.exercise.defaultSets).map { idx in
                            ExerciseSet(
                                setNumber: idx + 1,
                                weight: workoutExercise.exercise.usesWeight && !workoutExercise.exercise.isBodyweight ? 0.0 : 0.0,
                                reps: workoutExercise.exercise.defaultReps,
                                distance: workoutExercise.exercise.tracksDistance ? 0.0 : 0.0,
                                time: workoutExercise.exercise.isTimeBased ? 0 : 0,
                                isCompleted: false
                            )
                        },
                        notes: "",
                        isSuperset: workoutExercise.exercise.isSuperset,
                        isDropset: workoutExercise.exercise.isDropset
                    )
                }
                
                // Show exercises immediately
                exercises = basicWorkoutExercises
                isLoadingRoutine = false
                isInitialized = true
                
                // Start session
                workoutSessionManager.startWorkout(
                    routineId: routineId,
                    routineName: routine.name,
                    exercises: basicWorkoutExercises
                )
                
                // Load historical data in background
                await loadHistoricalDataInBackground(routine.exercises.map { $0.exercise })
                
            } catch {
                print("❌ Error initializing routine: \(error)")
                isLoadingRoutine = false
                workoutState = .error(error.localizedDescription)
            }
        }
    }
    
    func initializeQuickWorkout(_ workoutName: String) {
        guard !isInitialized else { return }
        
        print("🚀 STARTING initializeQuickWorkout with workoutName: \(workoutName)")
        
        currentRoutineId = nil
        originalRoutineName = workoutName
        routineName = workoutName
        exercises = []
        
        // Check for pending exercises from ExerciseChannel on quick workout start
        if ExerciseChannel.shared.hasPendingExercise() {
            if let pendingExercise = ExerciseChannel.shared.consumeExercise() {
                print("🎁 Quick workout: Adding pending exercise from channel: \(pendingExercise.name)")
                // Don't call addExercise directly here as it would update session before initialization
                // Instead, we'll check for it after initialization
            }
        }
        
        // Start session for quick workout
        workoutSessionManager.startWorkout(
            routineId: nil,
            routineName: workoutName,
            exercises: []
        )
        
        isInitialized = true
        print("✅ Quick workout initialized: \(workoutName)")
        
        // Now check again for pending exercises after initialization
        checkForPendingExercises()
    }
    
    func checkForPendingExercises() {
        if ExerciseChannel.shared.hasPendingExercise() {
            if let pendingExercise = ExerciseChannel.shared.consumeExercise() {
                print("🎁 WorkoutViewModel: Processing pending exercise after initialization: \(pendingExercise.name)")
                addExercise(pendingExercise)
            }
        }
    }
    
    func initializeFromSession() {
        guard !isInitialized else { return }
        
        guard let sessionState = workoutSessionManager.getWorkoutState() else {
            print("❌ No session state found for resume")
            return
        }
        
        print("🏋️ RESUMING FROM SESSION: \(sessionState.routineName)")
        
        currentRoutineId = sessionState.routineId
        originalRoutineName = sessionState.routineName
        routineName = sessionState.routineName
        exercises = sessionState.exercises
        
        // Sync timers
        startMs = Int64(sessionState.startTime.timeIntervalSince1970 * 1000)
        isWorkoutActive = false
        
        calculateStats()
        isInitialized = true
        
        // Sync with SessionManager timing
        Task {
            for await duration in workoutSessionManager.$workoutDuration.values {
                workoutDuration = duration
            }
        }
    }
    
    private func loadHistoricalDataInBackground(_ exercises: [Exercise]) async {
        print("🔄 PHASE 2: Loading historical data in background")
        
        let totalExercises = exercises.count
        var processedExercises = 0
        
        // Capture current exercises before entering TaskGroup
        let currentExercises = self.exercises
        
        let updatedExercises = await withTaskGroup(of: WorkoutExercise?.self, returning: [WorkoutExercise].self) { group in
            for (index, exercise) in exercises.enumerated() {
                group.addTask {
                    // Load historical data for this exercise
                    let historicalData = await self.findPreviousAndBestSets(
                        exerciseId: exercise.id,
                        isTimeBasedPure: exercise.isTimeBased && !exercise.usesWeight && !exercise.tracksDistance
                    )
                    let notes = await self.lastNotesFor(exerciseId: exercise.id) ?? ""
                    
                    // Find existing exercise in current list
                    guard let existingExercise = currentExercises.first(where: { $0.exercise.id == exercise.id }) else {
                        // Return a basic WorkoutExercise if not found
                        return WorkoutExercise(
                            exercise: exercise,
                            sets: [],
                            notes: "",
                            isSuperset: false,
                            isDropset: false
                        )
                    }
                    
                    // Update with historical data and pre-populated values
                    let updatedSets = existingExercise.sets.map { set in
                        let (previousSet, bestSet) = historicalData[set.setNumber] ?? (nil, nil)
                        
                        // Pre-populate with actual values from previous workout
                        let actualWeight = (exercise.usesWeight && previousSet?.weight ?? 0 > 0) ? (previousSet?.weight ?? set.weight) : set.weight
                        let actualReps = (!exercise.isTimeBased && previousSet?.reps ?? 0 > 0) ? (previousSet?.reps ?? set.reps) : set.reps
                        let actualDistance = (exercise.tracksDistance && previousSet?.distance ?? 0 > 0) ? (previousSet?.distance ?? set.distance) : set.distance
                        let previousTime: Int = Int(previousSet?.time ?? 0)
                        let actualTime: Int = (exercise.isTimeBased && previousTime > 0) ? previousTime : set.time
                        
                        return set.copy(
                            weight: actualWeight,
                            reps: actualReps,
                            distance: actualDistance,
                            time: actualTime,
                            previousReps: previousSet?.reps,
                            previousWeight: previousSet?.weight,
                            previousDistance: previousSet?.distance,
                            previousTime: previousSet?.time != nil ? Int(previousSet!.time) : nil,
                            bestReps: bestSet?.reps,
                            bestWeight: bestSet?.weight,
                            bestDistance: bestSet?.distance,
                            bestTime: bestSet?.time != nil ? Int(bestSet!.time) : nil
                        )
                    }
                    
                    return existingExercise.copy(sets: updatedSets,notes: notes )
                }
                
                processedExercises += 1
                await MainActor.run {
                    exerciseLoadingProgress = Float(processedExercises) / Float(totalExercises)
                }
            }
            
            var results: [WorkoutExercise] = []
            for await result in group {
                if let exercise = result {
                    results.append(exercise)
                }
            }
            return results
        }
        
        // Update exercises with historical data
        await MainActor.run {
            self.exercises = updatedExercises
        }
        workoutSessionManager.updateSession(
            routineId: currentRoutineId,
            routineName: routineName ?? "",
            exercises: updatedExercises
        )
        
        print("✅ PHASE 2 COMPLETE - Historical data loaded and values pre-populated")
    }
    
    // MARK: - Exercise Management
    
    func addExercise(_ exercise: Exercise) {
        let exerciseWithId = exercise.id.isEmpty ? 
            exercise.copy(id: exercise.name.camelCaseId()) : exercise
        
        print("🚀 WorkoutViewModel.addExercise → \(exerciseWithId.name) (id='\(exerciseWithId.id)')")
        print("🔍 Current exercises count before adding: \(exercises.count)")
        print("🔍 Current exercises: \(exercises.map { $0.exercise.name })")
        
        // Check for pending exercises from ExerciseChannel (similar to CreateRoutineViewModel)
        if ExerciseChannel.shared.hasPendingExercise() {
            if let pendingExercise = ExerciseChannel.shared.consumeExercise() {
                print("🎁 WorkoutViewModel: Found pending exercise from ExerciseChannel: \(pendingExercise.name)")
                // Use the pending exercise instead of the parameter
                return addExercise(pendingExercise)
            }
        }
        
        // Simple duplicate guard
        if exercises.contains(where: { $0.exercise.id == exerciseWithId.id }) {
            print("✋ Already in list, skipping")
            return
        }
        
        // Build default sets
        let newSets = (0..<exerciseWithId.defaultSets).map { idx in
            let zeroReps = exerciseWithId.isTimeBased && !exerciseWithId.usesWeight && !exerciseWithId.tracksDistance
            return ExerciseSet(
                setNumber: idx + 1,
                weight: (exerciseWithId.usesWeight && !exerciseWithId.isBodyweight) ? 0.0 : 0.0,
                reps: zeroReps ? 0 : exerciseWithId.defaultReps,
                distance: exerciseWithId.tracksDistance ? 0.0 : 0.0,
                time: exerciseWithId.isTimeBased ? 0 : 0,
                isCompleted: false
            )
        }
        
        print("🔧 Creating \(newSets.count) sets for exercise")
        
        // Create new WorkoutExercise
        let newWorkoutExercise = WorkoutExercise(
            exercise: exerciseWithId,
            sets: newSets,
            notes: "",
            isSuperset: exerciseWithId.isSuperset,
            isDropset: exerciseWithId.isDropset
        )
        
        // Append & publish
        exercises.append(newWorkoutExercise)
        
        print("✅ Exercise appended. New count: \(exercises.count)")
        print("✅ All exercises now: \(exercises.map { $0.exercise.name })")
        print("🔄 exercises.isEmpty = \(exercises.isEmpty)")
        
        // House-keeping
        isRoutineModified = currentRoutineId != nil
        workoutSessionManager.updateCurrentExercise(exerciseWithId.name)
        updateSessionExercises()
        calculateStats()
        
        print("🔄 Session updated and stats calculated")
        print("📊 Total volume: \(totalVolume), Total sets: \(totalSets)")
    }
    
    func addSet(_ workoutExercise: WorkoutExercise) {
        guard let index = exercises.firstIndex(where: { $0.exercise.id == workoutExercise.exercise.id }) else { return }
        
        let sets = exercises[index].sets
        let prevReps = sets.last?.reps ?? workoutExercise.exercise.defaultReps
        
        let newSet = ExerciseSet(
            setNumber: sets.count + 1,
            weight: (workoutExercise.exercise.usesWeight && !workoutExercise.exercise.isBodyweight) ? 0.0 : 0.0,
            reps: prevReps,
            distance: workoutExercise.exercise.tracksDistance ? 0.0 : 0.0,
            time: workoutExercise.exercise.isTimeBased ? 0 : 0,
            isCompleted: false,
            previousReps: prevReps
        )
        
        exercises[index] = exercises[index].copy(sets: sets + [newSet])
        updateSessionExercises()
    }
    
    func deleteSet(_ workoutExercise: WorkoutExercise, _ setNumber: Int) {
        guard let exerciseIndex = exercises.firstIndex(where: { $0.exercise.id == workoutExercise.exercise.id }) else { return }
        
        let newSets = exercises[exerciseIndex].sets
            .filter { $0.setNumber != setNumber }
            .enumerated()
            .map { index, set in set.copy(setNumber: index + 1) }
        
        exercises[exerciseIndex] = exercises[exerciseIndex].copy(sets: newSets)
        calculateStats()
        updateSessionExercises()
    }
    
    func removeExercise(_ workoutExercise: WorkoutExercise) {
        guard let index = exercises.firstIndex(where: { $0.exercise.id == workoutExercise.exercise.id }) else { return }
        
        exercises.remove(at: index)
        calculateStats()
        updateSessionExercises()
        isRoutineModified = currentRoutineId != nil
        
        print("Removed \(workoutExercise.exercise.name) from workout")
    }
    
    // MARK: - Set Updates
    
    func updateWeight(_ workoutExercise: WorkoutExercise, _ set: ExerciseSet, _ weight: Double) {
        mutateSet(workoutExercise, set) { currentSet in
            let bestWeight = currentSet.isCompleted ? max(currentSet.bestWeight ?? 0.0, weight) : currentSet.bestWeight
            return currentSet.copy(weight: weight, bestWeight: bestWeight)
        }
    }
    
    func updateReps(_ workoutExercise: WorkoutExercise, _ set: ExerciseSet, _ reps: Int) {
        mutateSet(workoutExercise, set) { currentSet in
            let bestReps = currentSet.isCompleted ? max(currentSet.bestReps ?? 0, reps) : currentSet.bestReps
            return currentSet.copy(reps: reps, bestReps: bestReps)
        }
    }
    
    func updateDistance(_ workoutExercise: WorkoutExercise, _ set: ExerciseSet, _ distance: Double) {
        mutateSet(workoutExercise, set) { currentSet in
            let bestDistance = currentSet.isCompleted ? max(currentSet.bestDistance ?? 0.0, distance) : currentSet.bestDistance
            return currentSet.copy(distance: distance, bestDistance: bestDistance)
        }
    }
    
    func updateTime(_ workoutExercise: WorkoutExercise, _ set: ExerciseSet, _ time: Int) {
        mutateSet(workoutExercise, set) { currentSet in
            let bestTime = currentSet.isCompleted ? 
                (currentSet.bestTime == nil ? time : min(currentSet.bestTime!, time)) : 
                currentSet.bestTime
            return currentSet.copy(time: time, bestTime: bestTime)
        }
    }
    
    func setCompleted(_ workoutExercise: WorkoutExercise, _ set: ExerciseSet, _ completed: Bool) {
        mutateSet(workoutExercise, set) { currentSet in
            let bestReps = completed ? max(currentSet.bestReps ?? 0, currentSet.reps) : currentSet.bestReps
            let bestWeight = completed ? max(currentSet.bestWeight ?? 0.0, currentSet.weight) : currentSet.bestWeight
            let bestDistance = completed ? max(currentSet.bestDistance ?? 0.0, currentSet.distance) : currentSet.bestDistance
            let bestTime = completed && currentSet.time > 0 ? 
                (currentSet.bestTime == nil ? currentSet.time : min(currentSet.bestTime!, currentSet.time)) : 
                currentSet.bestTime
            
            return currentSet.copy(
                isCompleted: completed,
                bestReps: bestReps,
                bestWeight: bestWeight,
                bestDistance: bestDistance,
                bestTime: bestTime
            )
        }
    }
    
    func updateNotes(_ workoutExercise: WorkoutExercise, _ notes: String) {
        guard let index = exercises.firstIndex(where: { $0.exercise.id == workoutExercise.exercise.id }) else { return }
        exercises[index] = exercises[index].copy(notes: notes)
        updateSessionExercises()
    }
    
    // MARK: - Exercise Organization
    
    func arrangeExercise(_ workoutExercise: WorkoutExercise) {
        print("arrangeExercise called for \(workoutExercise.exercise.name) - toggling reorder mode")
        isReorderMode = true
        print("Entered reorder mode - use up/down arrows to reorder exercises")
    }
    
    func reorderExercises(fromIndex: Int, toIndex: Int) {
        print("reorderExercises called: fromIndex=\(fromIndex), toIndex=\(toIndex)")
        
        guard fromIndex != toIndex,
              fromIndex >= 0, fromIndex < exercises.count,
              toIndex >= 0, toIndex < exercises.count else { return }
        
        let exerciseToMove = exercises[fromIndex]
        exercises.remove(at: fromIndex)
        exercises.insert(exerciseToMove, at: toIndex)
        
        updateSessionExercises()
        isRoutineModified = currentRoutineId != nil
        
        print("Successfully moved \(exerciseToMove.exercise.name) from index \(fromIndex) to \(toIndex)")
    }
    
    func exitReorderMode() {
        isReorderMode = false
        print("Exited reorder mode")
    }
    
    func addToSuperset(_ workoutExercise: WorkoutExercise) {
        guard let index = exercises.firstIndex(where: { $0.exercise.id == workoutExercise.exercise.id }) else { return }
        
        exercises[index] = exercises[index].copy(isSuperset: !exercises[index].isSuperset)
        updateSessionExercises()
        isRoutineModified = currentRoutineId != nil
        
        let status = exercises[index].isSuperset ? "added to" : "removed from"
        print("\(workoutExercise.exercise.name) \(status) superset")
    }
    
    func toggleDropset(_ workoutExercise: WorkoutExercise) {
        print("🔴 toggleDropset called for \(workoutExercise.exercise.name)")
        
        guard let index = exercises.firstIndex(where: { $0.exercise.id == workoutExercise.exercise.id }) else { return }
        
        exercises[index] = exercises[index].copy(isDropset: !exercises[index].isDropset)
        updateSessionExercises()
        isRoutineModified = currentRoutineId != nil
        
        let status = exercises[index].isDropset ? "added to" : "removed from"
        print("🔴 \(workoutExercise.exercise.name) \(status) dropset")
    }
    
    func replaceExercise(_ workoutExercise: WorkoutExercise) {
        print("replaceExercise called for \(workoutExercise.exercise.name)")
        
        guard let currentExercise = exercises.first(where: { $0.exercise.id == workoutExercise.exercise.id }) else { return }
        
        exerciseToReplace = currentExercise
        isReplacingExercise = true
        print("Exercise replacement mode activated for: \(currentExercise.exercise.name)")
    }
    
    func confirmReplaceExercise(_ newExercise: Exercise) {
        guard let exerciseToReplace = exerciseToReplace,
              let index = exercises.firstIndex(where: { $0.exercise.id == exerciseToReplace.exercise.id }) else { return }
        
        // Reset replacement state
        self.exerciseToReplace = nil
        isReplacingExercise = false
        
        // Create new WorkoutExercise with the new exercise but keep existing sets structure
        let newWorkoutExercise = WorkoutExercise(
            exercise: newExercise,
            sets: exerciseToReplace.sets.map { set in
                set.copy(
                    weight: (newExercise.usesWeight && !newExercise.isBodyweight) ? 0.0 : 0.0,
                    reps: newExercise.defaultReps,
                    distance: newExercise.tracksDistance ? 0.0 : 0.0,
                    time: newExercise.isTimeBased ? 0 : 0,
                    isCompleted: false,
                    previousReps: nil, previousWeight: nil, previousDistance: nil, previousTime: nil,
                    bestReps: nil, bestWeight: nil, bestDistance: nil, bestTime: nil
                )
            },
            notes: exerciseToReplace.notes,
            isSuperset: exerciseToReplace.isSuperset,
            isDropset: exerciseToReplace.isDropset
        )
        
        exercises[index] = newWorkoutExercise
        calculateStats()
        updateSessionExercises()
        isRoutineModified = currentRoutineId != nil
        
        print("Successfully replaced \(exerciseToReplace.exercise.name) with \(newExercise.name)")
    }
    
    // MARK: - Rest Timer
    
    func startRestTimer(_ duration: Int) {
        restTimerManager.startTimer(duration: TimeInterval(duration))
    }
    
    func stopRestTimer() {
        restTimerManager.stopTimer()
    }
    
    func pauseResumeRestTimer() {
        restTimerManager.pauseResumeTimer()
    }
    
    // MARK: - Workout Control
    
    func pauseWorkout() {
        workoutSessionManager.pauseWorkout()
    }
    
    func resumeWorkout() {
        workoutSessionManager.resumeWorkout()
    }
    
    func finishWorkout(forceFinish: Bool = false, onSuccess: @escaping () -> Void) {
        Task {
            do {
                workoutState = .loading
                
                // Check completion status
                let completionStatus = getWorkoutCompletionStatus()
                
                if completionStatus.completedSets == 0 {
                    workoutState = .error("No completed sets found. Complete at least one set to finish the workout.")
                    return
                }
                
                // If not forced and incomplete, let UI handle dialog
                if !forceFinish && !completionStatus.isFullyCompleted {
                    workoutState = .initial
                    return
                }
                
                // Continue with finish logic
                guard let uid = try await authRepository.getCurrentUser()?.id else {
                    throw NSError(domain: "WorkoutViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                let routineColour = currentRoutineId != nil ? 
                    (try await workoutRepository.getWorkoutById(currentRoutineId!))?.colorHex ?? "#6B9CD6" : 
                    "#6B9CD6"
                
                let nameForHistory = originalRoutineName ?? generateWorkoutName()
                
                let doneExercises = exercises.filter { ex in ex.sets.contains { $0.isCompleted } }
                
                let completedExercises = doneExercises.map { wEx in
                    CompletedExercise(
                        exerciseId: wEx.exercise.id,
                        name: wEx.exercise.name,
                        notes: wEx.notes,
                        muscleGroup: wEx.exercise.muscleGroup,
                        equipment: wEx.exercise.equipment,
                        sets: wEx.sets.filter { $0.isCompleted }.map { set in
                            CompletedSet(
                                setNumber: set.setNumber,
                                weight: set.weight,
                                reps: set.reps,
                                distance: set.distance,
                                time: Double(set.time)
                            )
                        }
                    )
                }
                
                let history = WorkoutHistory(
                    id: UUID().uuidString,
                    name: nameForHistory,
                    startTime: Date(timeIntervalSince1970: Double(startMs) / 1000),
                    endTime: Date(),
                    exercises: completedExercises,
                    totalVolume: totalVolume,
                    totalSets: totalSets,
                    colorHex: routineColour,
                    routineId: currentRoutineId,
                    userId: uid,
                    exerciseIds: completedExercises.map { $0.exerciseId }
                )
                
                try await workoutHistoryRepository.saveWorkoutHistory(history)
                
                // Notify that workout is completed so calendar can refresh
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("WorkoutCompleted"), object: nil)
                }
                
                print("✅ Workout history saved successfully to Firebase")
                print("🎉 WORKOUT FINISHED SUCCESSFULLY!")
                print("   📝 Name: \(history.name)")
                print("   ⏱️ Duration: \(history.formattedDuration)")
                print("   💪 Completed Sets: \(history.totalSets)")
                print("   🏋️ Volume: \(String(format: "%.1f", history.totalVolume)) kg")
                print("   🎯 Exercises: \(history.exercises.count)")
                
                // Analytics: Log workout completed
                let workoutDurationMinutes = Int((history.endTime.timeIntervalSince1970 - history.startTime.timeIntervalSince1970) / 60)
                print("📊 Workout completed - Duration: \(workoutDurationMinutes) mins, Sets: \(history.totalSets), Exercises: \(completedExercises.count), Volume: \(history.totalVolume), Routine-based: \(currentRoutineId != nil)")
                
                // Update routine last performed
                if let routineId = currentRoutineId {
                    try await workoutRepository.updateWorkoutLastPerformed(routineId: routineId, lastPerformed: history.endTime)
                    if isRoutineModified {
                        showUpdateRoutineDialog = true
                        workoutState = .success
                        return
                    }
                }
                
                workoutSessionManager.discardWorkout()
                isWorkoutActive = false
                workoutState = .success
                
                await MainActor.run {
                    print("🚀 Calling success callback - workout should be dismissed now")
                    onSuccess()
                }
                
            } catch {
                print("finishWorkout error: \(error)")
                workoutState = .error(error.localizedDescription)
            }
        }
    }
    
    func discardWorkout() {
        print("🔥 Discarding workout")
        
        // Track workout abandonment analytics before clearing data
        if isWorkoutActive {
            let workoutDuration = Int((Date().timeIntervalSince1970 * 1000 - Double(startMs)) / 60000)
            let completedSetsCount = exercises.flatMap { $0.sets }.count { $0.isCompleted }
            let totalPlannedSets = exercises.flatMap { $0.sets }.count
            let isRoutineBased = currentRoutineId != nil
            
            print("📊 Workout abandoned - Duration: \(workoutDuration) mins, Completed: \(completedSetsCount)/\(totalPlannedSets) sets, Routine-based: \(isRoutineBased)")
        }
        
        // Stop the timer
        isWorkoutActive = false
        
        // Clear workout data
        exercises = []
        workoutState = .initial
        totalVolume = 0.0
        totalSets = 0
        
        // Reset workout session manager
        workoutSessionManager.discardWorkout()
        
        // Reset flags
        isInitialized = false
        currentRoutineId = nil
        originalRoutineName = nil
        isRoutineModified = false
        
        print("🔥 Workout discarded successfully")
    }
    
    func getWorkoutCompletionStatus() -> WorkoutCompletionStatus {
        let allExercises = exercises
        var completedExercisesList: [ExerciseCompletionInfo] = []
        var incompleteExercisesList: [ExerciseCompletionInfo] = []
        
        var totalSetsCount = 0
        var completedSetsCount = 0
        
        // Process each exercise to build comprehensive completion info
        allExercises.forEach { exercise in
            let exerciseTotalSets = exercise.sets.count
            let exerciseCompletedSets = exercise.sets.count { $0.isCompleted }
            
            totalSetsCount += exerciseTotalSets
            completedSetsCount += exerciseCompletedSets
            
            let exerciseInfo = ExerciseCompletionInfo(
                exerciseName: exercise.exercise.name,
                totalSets: exerciseTotalSets,
                completedSets: exerciseCompletedSets,
                isFullyCompleted: exerciseCompletedSets == exerciseTotalSets && exerciseCompletedSets > 0
            )
            
            if exerciseInfo.isFullyCompleted {
                completedExercisesList.append(exerciseInfo)
            } else {
                incompleteExercisesList.append(exerciseInfo)
            }
        }
        
        return WorkoutCompletionStatus(
            totalExercises: allExercises.count,
            completedExercises: completedExercisesList,
            incompleteExercises: incompleteExercisesList,
            totalSets: totalSetsCount,
            completedSets: completedSetsCount,
            isFullyCompleted: incompleteExercisesList.isEmpty && completedSetsCount > 0
        )
    }
    
    // MARK: - Save as Routine
    
    func showSaveRoutineDialog() {
        if !exercises.isEmpty {
            showSaveAsRoutineDialog = true
        }
    }
    
    func hideSaveAsRoutineDialog() {
        showSaveAsRoutineDialog = false
    }
    
    func saveAsRoutine(
        routineName: String,
        onSuccess: @escaping () -> Void,
        onUpgradeRequired: @escaping () -> Void,
        onError: @escaping (String) -> Void
    ) {
        guard !routineName.isEmpty else {
            onError("Please enter a routine name")
            return
        }
        
        guard !exercises.isEmpty else {
            onError("Cannot save empty workout as routine")
            return
        }
        
        Task {
            do {
                // Check subscription limits
                if !canCreateNewRoutine() {
                    await MainActor.run { onUpgradeRequired() }
                    return
                }
                
                guard let userId = try await authRepository.getCurrentUser()?.id else {
                    await MainActor.run { onError("User not authenticated") }
                    return
                }
                
                // Generate proper workout ID and assign color similar to Android
                let workoutId = UUID().uuidString
                let colorHex = RoutineColors.byIndex(routineCount)
                
                let workout = Workout(
                    id: workoutId,
                    name: routineName,
                    userId: userId,
                    exercises: exercises,
                    createdAt: Date(),
                    colorHex: colorHex
                )
                
                try await workoutRepository.createWorkout(workout)
                
                // Update routine count
                await MainActor.run {
                    routineCount += 1
                    showSaveAsRoutineDialog = false
                    onSuccess()
                }
                
                print("Successfully saved workout as routine: \(routineName)")
                
            } catch {
                print("Error saving workout as routine: \(error)")
                await MainActor.run { onError("Failed to save routine: \(error.localizedDescription)") }
            }
        }
    }
    
    private func canCreateNewRoutine() -> Bool {
        return isPremium || routineCount < 3
    }
    
    // MARK: - Helper Methods
    
    private func mutateSet(
        _ workoutExercise: WorkoutExercise,
        _ targetSet: ExerciseSet,
        _ transform: (ExerciseSet) -> ExerciseSet
    ) {
        guard let exerciseIndex = exercises.firstIndex(where: { $0.exercise.id == workoutExercise.exercise.id }) else { return }
        guard let setIndex = exercises[exerciseIndex].sets.firstIndex(where: { $0.setNumber == targetSet.setNumber }) else { return }
        
        let updatedSet = transform(exercises[exerciseIndex].sets[setIndex])
        var updatedSets = exercises[exerciseIndex].sets
        updatedSets[setIndex] = updatedSet
        
        exercises[exerciseIndex] = exercises[exerciseIndex].copy(sets: updatedSets)
        calculateStats()
        updateSessionExercises()
    }
    
    private func calculateStats() {
        var volume = 0.0
        var setCount = 0
        
        exercises.forEach { workoutExercise in
            workoutExercise.sets.filter { $0.isCompleted }.forEach { set in
                volume += set.weight * Double(set.reps)
                setCount += 1
            }
        }
        
        totalVolume = volume
        totalSets = setCount
    }
    
    private func updateSessionExercises() {
        guard isInitialized else { return }
        
        workoutSessionManager.updateSession(
            routineId: currentRoutineId,
            routineName: routineName ?? "",
            exercises: exercises
        )
    }
    
    private func startTimer() {
        Task {
            while isWorkoutActive {
                let elapsedSeconds = (Date().timeIntervalSince1970 * 1000 - Double(startMs)) / 1000
                let seconds = Int(elapsedSeconds)
                
                await MainActor.run {
                    workoutDuration = formatDuration(seconds)
                }
                
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        if seconds >= 3600 {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            let remainingSeconds = seconds % 60
            return "\(hours)h \(minutes)m \(remainingSeconds)s"
        } else if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    private func generateWorkoutName() -> String {
        let groups = exercises.map { $0.exercise.muscleGroup }.uniqued()
        switch groups.count {
        case 0: return "Quick Workout"
        case 1: return "\(groups[0]) Workout"
        default: return "\(groups[0]) & \(groups[1]) Workout"
        }
    }
    
    // Historical data methods (simplified for now)
    private func findPreviousAndBestSets(exerciseId: String, isTimeBasedPure: Bool) async -> [Int: (CompletedSet?, CompletedSet?)] {
        guard let uid = try? await authRepository.getCurrentUser()?.id else { 
            print("❌ No authenticated user for historical data lookup")
            return [:] 
        }
        
        print("🔍 Loading historical data for exercise: \(exerciseId)")
        
        do {
            // Query workout history to find previous and best sets
            let historyPublisher = workoutHistoryRepository.getWorkoutHistory(userId: uid)
            
            // Convert publisher to async/await
            let workoutHistory = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[WorkoutHistory], Error>) in
                var cancellable: AnyCancellable?
                cancellable = historyPublisher
                    .first()
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            case .finished:
                                break
                            }
                            cancellable?.cancel()
                        },
                        receiveValue: { workouts in
                            continuation.resume(returning: workouts)
                            cancellable?.cancel()
                        }
                    )
            }
            
            print("📚 Loaded \(workoutHistory.count) workout history entries")
            
            var result: [Int: (CompletedSet?, CompletedSet?)] = [:]
            var allSets: [CompletedSet] = []
            var mostRecentSets: [CompletedSet] = []
            
            // Collect all sets for this exercise from history
            for workout in workoutHistory.prefix(15) { // Look at last 15 workouts
                for exercise in workout.exercises {
                    if exercise.exerciseId == exerciseId || exercise.name.lowercased() == exerciseId.lowercased() {
                        if mostRecentSets.isEmpty {
                            mostRecentSets = exercise.sets // First matching workout = most recent
                        }
                        allSets.append(contentsOf: exercise.sets)
                    }
                }
            }
            
            if allSets.isEmpty {
                print("📭 No historical data found for exercise: \(exerciseId)")
                return result
            }
            
            print("📊 Found \(allSets.count) historical sets for analysis")
            
            // Group sets by position and find best for each position
            let groupedSets = Dictionary(grouping: allSets) { $0.setNumber }
            let previousGrouped = Dictionary(grouping: mostRecentSets) { $0.setNumber }
            
            let maxPosition = max(groupedSets.keys.max() ?? 0, previousGrouped.keys.max() ?? 0)
            
            for position in 1...maxPosition {
                let previousSet = previousGrouped[position]?.first
                
                // Find best set for this position using scoring logic
                var bestSet: CompletedSet?
                if let setsAtPosition = groupedSets[position] {
                    bestSet = findBestSet(in: setsAtPosition, isTimeBasedPure: isTimeBasedPure)
                }
                
                result[position] = (previousSet, bestSet)
            }
            
            print("✅ Historical data loaded for \(result.count) set positions")
            return result
            
        } catch {
            print("❌ Error loading historical data: \(error)")
            return [:]
        }
    }
    
    private func findBestSet(in sets: [CompletedSet], isTimeBasedPure: Bool) -> CompletedSet? {
        guard !sets.isEmpty else { return nil }
        
        // Priority scoring like in Kotlin:
        // 1. Weight x distance (if both > 0)
        // 2. Weight x reps (if weight > 0) 
        // 3. Pure distance
        // 4. Pure time (for time-based exercises, lower is better for some like plank, higher for others)
        // 5. Pure reps
        
        let weightDistanceSets = sets.filter { $0.weight > 0 && $0.distance > 0 }
        if !weightDistanceSets.isEmpty {
            return weightDistanceSets.max { $0.weight * $0.distance < $1.weight * $1.distance }
        }
        
        let weightSets = sets.filter { $0.weight > 0 }
        if !weightSets.isEmpty {
            return weightSets.max { $0.weight * Double($0.reps) < $1.weight * Double($1.reps) }
        }
        
        let distanceSets = sets.filter { $0.distance > 0 }
        if !distanceSets.isEmpty {
            return distanceSets.max { $0.distance < $1.distance }
        }
        
        let timeSets = sets.filter { $0.time > 0 }
        if !timeSets.isEmpty {
            // For time-based exercises, higher time is generally better (like plank hold)
            return timeSets.max { $0.time < $1.time }
        }
        
        // Fallback to reps
        return sets.max { $0.reps < $1.reps }
    }
    
    private func lastNotesFor(exerciseId: String) async -> String? {
        guard let uid = try? await authRepository.getCurrentUser()?.id else { return nil }
        
        do {
            let historyPublisher = workoutHistoryRepository.getWorkoutHistory(userId: uid)
            
            let workoutHistory = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[WorkoutHistory], Error>) in
                var cancellable: AnyCancellable?
                cancellable = historyPublisher
                    .first()
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            case .finished:
                                break
                            }
                            cancellable?.cancel()
                        },
                        receiveValue: { workouts in
                            continuation.resume(returning: workouts)
                            cancellable?.cancel()
                        }
                    )
            }
            
            // Find the most recent workout containing this exercise
            for workout in workoutHistory {
                for exercise in workout.exercises {
                    if exercise.exerciseId == exerciseId || exercise.name.lowercased() == exerciseId.lowercased() {
                        return exercise.notes.isEmpty ? nil : exercise.notes
                    }
                }
            }
            
            return nil
            
        } catch {
            print("❌ Error loading last notes: \(error)")
            return nil
        }
    }
}

// MARK: - Workout State

enum ActiveWorkoutState: Equatable {
    case initial
    case loading
    case success
    case error(String)
}

// MARK: - Extensions

extension String {
    func camelCaseId() -> String {
        return self.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension ExerciseSet {
    func copy(
        setNumber: Int? = nil,
        weight: Double? = nil,
        reps: Int? = nil,
        distance: Double? = nil,
        time: Int? = nil,
        isCompleted: Bool? = nil,
        previousReps: Int?? = nil,
        previousWeight: Double?? = nil,
        previousDistance: Double?? = nil,
        previousTime: Int?? = nil,
        bestReps: Int?? = nil,
        bestWeight: Double?? = nil,
        bestDistance: Double?? = nil,
        bestTime: Int?? = nil
    ) -> ExerciseSet {
        return ExerciseSet(
            setNumber: setNumber ?? self.setNumber,
            weight: weight ?? self.weight,
            reps: reps ?? self.reps,
            distance: distance ?? self.distance,
            time: time ?? self.time,
            isCompleted: isCompleted ?? self.isCompleted,
            previousReps: previousReps ?? self.previousReps,
            previousWeight: previousWeight ?? self.previousWeight,
            previousDistance: previousDistance ?? self.previousDistance,
            previousTime: previousTime ?? self.previousTime,
            bestReps: bestReps ?? self.bestReps,
            bestWeight: bestWeight ?? self.bestWeight,
            bestDistance: bestDistance ?? self.bestDistance,
            bestTime: bestTime ?? self.bestTime
        )
    }
}

extension WorkoutExercise {
    func copy(
        exercise: Exercise? = nil,
        sets: [ExerciseSet]? = nil,
        notes: String? = nil,
        isSuperset: Bool? = nil,
        isDropset: Bool? = nil
    ) -> WorkoutExercise {
        return WorkoutExercise(
            exercise: exercise ?? self.exercise,
            sets: sets ?? self.sets,
            notes: notes ?? self.notes,
            isSuperset: isSuperset ?? self.isSuperset,
            isDropset: isDropset ?? self.isDropset
        )
    }
}

extension Exercise {
    func copy(
        id: String? = nil,
        name: String? = nil,
        equipment: String? = nil,
        muscleGroup: String? = nil,
        defaultReps: Int? = nil,
        defaultSets: Int? = nil,
        isBodyweight: Bool? = nil,
        usesWeight: Bool? = nil,
        tracksDistance: Bool? = nil,
        isTimeBased: Bool? = nil,
        description: String? = nil
    ) -> Exercise {
        return Exercise(
            id: id ?? self.id,
            name: name ?? self.name,
            muscleGroup: muscleGroup ?? self.muscleGroup,
            equipment: equipment ?? self.equipment,
            defaultReps: defaultReps ?? self.defaultReps,
            defaultSets: defaultSets ?? self.defaultSets,
            isBodyweight: isBodyweight ?? self.isBodyweight,
            usesWeight: usesWeight ?? self.usesWeight,
            tracksDistance: tracksDistance ?? self.tracksDistance,
            isTimeBased: isTimeBased ?? self.isTimeBased,
            description: description ?? self.description
        )
    }
}
