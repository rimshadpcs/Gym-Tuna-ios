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
                
                // Create basic workout exercises
                let basicWorkoutExercises = routine.exercises.map { exercise in
                    WorkoutExercise(
                        exercise: exercise,
                        sets: (0..<exercise.defaultSets).map { idx in
                            ExerciseSet(
                                setNumber: idx + 1,
                                weight: exercise.usesWeight && !exercise.isBodyweight ? 0.0 : 0.0,
                                reps: exercise.defaultReps,
                                distance: exercise.tracksDistance ? 0.0 : 0.0,
                                time: exercise.isTimeBased ? 0 : 0,
                                isCompleted: false
                            )
                        },
                        notes: "",
                        isSuperset: exercise.isSuperset,
                        isDropset: exercise.isDropset
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
                await loadHistoricalDataInBackground(routine.exercises)
                
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
        
        // Start session for quick workout
        workoutSessionManager.startWorkout(
            routineId: nil,
            routineName: workoutName,
            exercises: []
        )
        
        isInitialized = true
        print("✅ Quick workout initialized: \(workoutName)")
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
        
        print("addExercise → \(exerciseWithId.name) (id='\(exerciseWithId.id)')")
        
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
        
        // Append & publish
        exercises.append(WorkoutExercise(
            exercise: exerciseWithId,
            sets: newSets,
            notes: "",
            isSuperset: exerciseWithId.isSuperset,
            isDropset: exerciseWithId.isDropset
        ))
        
        // House-keeping
        isRoutineModified = currentRoutineId != nil
        workoutSessionManager.updateCurrentExercise(exerciseWithId.name)
        updateSessionExercises()
        
        print("✅ Added. Exercise count = \(exercises.count)")
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
        let completedExercises = allExercises.filter { exercise in
            let exerciseCompletedSets = exercise.sets.count { $0.isCompleted }
            return exerciseCompletedSets == exercise.sets.count && exerciseCompletedSets > 0
        }.map { exercise in
            ExerciseCompletionInfo(
                exerciseName: exercise.exercise.name,
                totalSets: exercise.sets.count,
                completedSets: exercise.sets.count { $0.isCompleted },
                isFullyCompleted: true
            )
        }
        
        let incompleteExercises = allExercises.filter { exercise in
            let exerciseCompletedSets = exercise.sets.count { $0.isCompleted }
            return exerciseCompletedSets < exercise.sets.count
        }.map { exercise in
            ExerciseCompletionInfo(
                exerciseName: exercise.exercise.name,
                totalSets: exercise.sets.count,
                completedSets: exercise.sets.count { $0.isCompleted },
                isFullyCompleted: false
            )
        }
        
        let totalSets = allExercises.flatMap { $0.sets }.count
        let completedSets = allExercises.flatMap { $0.sets }.count { $0.isCompleted }
        
        return WorkoutCompletionStatus(
            totalExercises: allExercises.count,
            completedExercises: completedExercises,
            incompleteExercises: incompleteExercises,
            totalSets: totalSets,
            completedSets: completedSets,
            isFullyCompleted: incompleteExercises.isEmpty && completedSets > 0
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
                
                // Convert WorkoutExercises to Exercises
                let exercisesList = exercises.map { workoutExercise in
                    Exercise(
                        id: workoutExercise.exercise.id,
                        name: workoutExercise.exercise.name,
                        muscleGroup: workoutExercise.exercise.muscleGroup,
                        equipment: workoutExercise.exercise.equipment,
                        defaultReps: workoutExercise.exercise.defaultReps,
                        defaultSets: workoutExercise.exercise.defaultSets,
                        isBodyweight: workoutExercise.exercise.isBodyweight,
                        usesWeight: workoutExercise.exercise.usesWeight,
                        tracksDistance: workoutExercise.exercise.tracksDistance,
                        isTimeBased: workoutExercise.exercise.isTimeBased,
                        description: workoutExercise.exercise.description
                    )
                }
                
                let workout = Workout(
                    id: routineName.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression),
                    name: routineName,
                    userId: userId,
                    exercises: exercisesList,
                    createdAt: Date()
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
        // Implementation would query historical workout data
        // For now, return empty data
        return [:]
    }
    
    private func lastNotesFor(exerciseId: String) async -> String? {
        // Implementation would query last notes for exercise
        return nil
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
