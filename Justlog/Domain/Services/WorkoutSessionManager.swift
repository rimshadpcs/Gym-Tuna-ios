//
//  WorkoutSessionManager.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class WorkoutSessionManager: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = WorkoutSessionManager()
    
    // MARK: - Published Properties
    @Published private(set) var workoutDuration: String = "0s"
    @Published private(set) var currentExercise: String? = nil
    @Published private(set) var isActive: Bool = false
    @Published private(set) var workoutState: WorkoutSessionState? = nil
    @Published private(set) var isRoutineWorkout: Bool = false
    @Published private(set) var isQuickWorkout: Bool = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private var timerCancellable: AnyCancellable?
    private var workoutStartTime: Date = Date()
    private var totalPausedDuration: TimeInterval = 0
    private var lastPauseTime: Date? = nil
    
    // MARK: - Constants
    private enum Keys {
        static let workoutState = "workout_state"
        static let startTime = "start_time"
        static let totalPausedDuration = "total_paused_duration"
        static let lastPauseTime = "last_pause_time"
        static let isActive = "is_active"
        static let currentExercise = "current_exercise"
    }
    
    // MARK: - Initialization
    init() {
        print("🏋️ WorkoutSessionManager initializing...")
        restoreSession()
    }
    
    // MARK: - Public Methods
    
    func startWorkout(routineId: String?, routineName: String, exercises: [WorkoutExercise]) {
        let workoutType = routineId != nil ? "routine" : "quick"
        print("🏋️ Starting \(workoutType) workout session: \(routineName)")
        
        let currentTime = Date()
        
        let sessionState = WorkoutSessionState(
            routineId: routineId,
            routineName: routineName,
            exercises: exercises,
            startTime: currentTime,
            isActive: true,
            currentExercise: exercises.first?.exercise.name,
            pausedAt: nil,
            completedSets: 0
        )
        
        workoutStartTime = currentTime
        totalPausedDuration = 0
        lastPauseTime = nil
        
        workoutState = sessionState
        isActive = true
        isRoutineWorkout = routineId != nil
        isQuickWorkout = routineId == nil
        currentExercise = exercises.first?.exercise.name
        
        saveSession(sessionState)
        startTimer()
        
        print("🏋️ \(workoutType.capitalized) workout started: \(sessionState.routineName) with \(exercises.count) exercises")
    }
    
    func startRoutineWorkout(routineId: String, routineName: String, exercises: [WorkoutExercise]) {
        print("🏋️ Starting routine workout: \(routineName) (ID: \(routineId))")
        startWorkout(routineId: routineId, routineName: routineName, exercises: exercises)
    }
    
    func startQuickWorkout(workoutName: String, exercises: [WorkoutExercise] = []) {
        print("🏋️ Starting quick workout: \(workoutName)")
        startWorkout(routineId: nil, routineName: workoutName, exercises: exercises)
    }
    
    func resumeWorkout() {
        print("🏋️ Resuming workout")
        
        guard let state = workoutState else { return }
        
        // Calculate total paused time up to this point
        if let pauseTime = lastPauseTime {
            let pauseDuration = Date().timeIntervalSince(pauseTime)
            totalPausedDuration += pauseDuration
            lastPauseTime = nil
            print("🏋️ Added pause duration: \(pauseDuration)s, total paused: \(totalPausedDuration)s")
        }
        
        let resumedState = WorkoutSessionState(
            routineId: state.routineId,
            routineName: state.routineName,
            exercises: state.exercises,
            startTime: state.startTime,
            isActive: true,
            currentExercise: state.currentExercise,
            pausedAt: nil,
            completedSets: state.completedSets
        )
        
        workoutState = resumedState
        isActive = true
        
        saveSession(resumedState)
        startTimer()
    }
    
    func pauseWorkout() {
        print("🏋️ Pausing workout")
        
        let pauseTime = Date()
        lastPauseTime = pauseTime
        
        guard let state = workoutState else { return }
        
        let pausedState = WorkoutSessionState(
            routineId: state.routineId,
            routineName: state.routineName,
            exercises: state.exercises,
            startTime: state.startTime,
            isActive: false,
            currentExercise: state.currentExercise,
            pausedAt: pauseTime,
            completedSets: state.completedSets
        )
        
        workoutState = pausedState
        isActive = false
        
        saveSession(pausedState)
        stopTimer()
    }
    
    func finishWorkout() {
        print("🏋️ Finishing workout")
        clearSession()
    }
    
    func discardWorkout() {
        print("🏋️ Discarding workout")
        print("🏋️ Discarding workout - current state: \(workoutState?.routineName ?? "nil")")
        clearSession()
    }
    
    // Public method to force clear session (for debugging)
    func forceResetSession() {
        print("🔧 Force resetting workout session")
        clearSession()
    }
    
    func updateCurrentExercise(_ exerciseName: String) {
        currentExercise = exerciseName
        
        guard let state = workoutState else { return }
        
        let updatedState = WorkoutSessionState(
            routineId: state.routineId,
            routineName: state.routineName,
            exercises: state.exercises,
            startTime: state.startTime,
            isActive: state.isActive,
            currentExercise: exerciseName,
            pausedAt: state.pausedAt,
            completedSets: state.completedSets
        )
        
        workoutState = updatedState
        saveSession(updatedState)
    }
    
    func addCompletedSet() {
        guard let state = workoutState else { return }
        
        let updatedState = WorkoutSessionState(
            routineId: state.routineId,
            routineName: state.routineName,
            exercises: state.exercises,
            startTime: state.startTime,
            isActive: state.isActive,
            currentExercise: state.currentExercise,
            pausedAt: state.pausedAt,
            completedSets: state.completedSets + 1
        )
        
        workoutState = updatedState
        saveSession(updatedState)
    }
    
    func updateSession(routineId: String?, routineName: String, exercises: [WorkoutExercise]) {
        guard let currentState = workoutState else { 
            print("⚠️ Cannot update session - no active workout state")
            return 
        }
        
        let updatedState = WorkoutSessionState(
            routineId: routineId,
            routineName: routineName,
            exercises: exercises,
            startTime: currentState.startTime,
            isActive: currentState.isActive,
            currentExercise: currentState.currentExercise,
            pausedAt: currentState.pausedAt,
            completedSets: currentState.completedSets
        )
        
        workoutState = updatedState
        isRoutineWorkout = routineId != nil
        isQuickWorkout = routineId == nil
        
        saveSession(updatedState)
        
        let workoutType = routineId != nil ? "routine" : "quick"
        print("🔄 \(workoutType.capitalized) session updated:")
        print("   - routineId: \(routineId ?? "nil")")
        print("   - routineName: \(routineName)")
        print("   - exercises: \(exercises.count)")
    }
    
    // MARK: - Public Getters
    
    func isWorkoutActive() -> Bool {
        return isActive
    }
    
    func getRoutineName() -> String {
        return workoutState?.routineName ?? "Workout"
    }
    
    func getCurrentExerciseName() -> String {
        return currentExercise ?? "Ready to start"
    }
    
    func getCurrentDuration() -> String {
        return workoutDuration
    }
    
    func getWorkoutState() -> WorkoutSessionState? {
        let state = workoutState
        let workoutType = state?.routineId != nil ? "routine" : "quick"
        print("🔍 getWorkoutState() called, returning: \(state?.routineName ?? "nil") (\(workoutType))")
        return state
    }
    
    func hasActiveWorkout() -> Bool {
        let hasWorkout = workoutState != nil
        let workoutType = hasWorkout ? (workoutState?.routineId != nil ? "routine" : "quick") : "none"
        print("🔍 hasActiveWorkout() called, returning: \(hasWorkout) (type: \(workoutType))")
        return hasWorkout
    }
    
    func getWorkoutType() -> String? {
        guard let state = workoutState else { return nil }
        return state.routineId != nil ? "routine" : "quick"
    }
    
    func isCurrentlyRoutineWorkout() -> Bool {
        return isRoutineWorkout
    }
    
    func isCurrentlyQuickWorkout() -> Bool {
        return isQuickWorkout
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        stopTimer() // Cancel existing timer
        
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateDuration()
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func updateDuration() {
        guard isActive else { return }
        
        let currentTime = Date()
        let elapsed = currentTime.timeIntervalSince(workoutStartTime) - totalPausedDuration
        workoutDuration = formatDuration(elapsed)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let seconds = Int(interval)
        
        switch seconds {
        case 3600...:
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            let secs = seconds % 60
            return String(format: "%dh %dm %ds", hours, minutes, secs)
        case 60...:
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "%dm %ds", minutes, secs)
        default:
            return "\(seconds)s"
        }
    }
    
    private func saveSession(_ state: WorkoutSessionState) {
        do {
            print("💾 SAVING SESSION:")
            print("   - routineId: \(state.routineId ?? "nil")")
            print("   - routineName: \(state.routineName)")
            print("   - exercises: \(state.exercises.count)")
            print("   - startTime: \(state.startTime)")
            print("   - isActive: \(state.isActive)")
            
            let data = try JSONEncoder().encode(state)
            userDefaults.set(data, forKey: Keys.workoutState)
            userDefaults.set(workoutStartTime.timeIntervalSince1970, forKey: Keys.startTime)
            userDefaults.set(totalPausedDuration, forKey: Keys.totalPausedDuration)
            
            if let pauseTime = lastPauseTime {
                userDefaults.set(pauseTime.timeIntervalSince1970, forKey: Keys.lastPauseTime)
            } else {
                userDefaults.removeObject(forKey: Keys.lastPauseTime)
            }
            
            userDefaults.set(state.isActive, forKey: Keys.isActive)
            userDefaults.set(state.currentExercise, forKey: Keys.currentExercise)
            
            print("✅ Session saved successfully")
            
        } catch {
            print("❌ Error saving session: \(error)")
        }
    }
    
    private func restoreSession() {
        do {
            guard let data = userDefaults.data(forKey: Keys.workoutState) else {
                print("🔄 No saved session found")
                return
            }
            
            print("🔄 RESTORING SESSION:")
            print("   - data exists: \(data.count) bytes")
            
            let state = try JSONDecoder().decode(WorkoutSessionState.self, from: data)
            
            let workoutType = state.routineId != nil ? "routine" : "quick"
            print("   - restored \(workoutType) workout")
            print("   - restored routineId: \(state.routineId ?? "nil")")
            print("   - restored routineName: \(state.routineName)")
            print("   - restored exercises: \(state.exercises.count)")
            print("   - restored startTime: \(state.startTime)")
            
            workoutStartTime = Date(timeIntervalSince1970: userDefaults.double(forKey: Keys.startTime))
            totalPausedDuration = userDefaults.double(forKey: Keys.totalPausedDuration)
            
            if userDefaults.object(forKey: Keys.lastPauseTime) != nil {
                lastPauseTime = Date(timeIntervalSince1970: userDefaults.double(forKey: Keys.lastPauseTime))
            }
            
            let wasActive = userDefaults.bool(forKey: Keys.isActive)
            
            workoutState = state
            isActive = wasActive
            isRoutineWorkout = state.routineId != nil
            isQuickWorkout = state.routineId == nil
            currentExercise = state.currentExercise
            
            // Calculate current duration
            let currentTime = Date()
            let elapsed: TimeInterval
            
            if wasActive {
                // If was active, continue timing
                elapsed = currentTime.timeIntervalSince(workoutStartTime) - totalPausedDuration
            } else {
                // If was paused, calculate time up to last pause
                if let pauseTime = lastPauseTime {
                    elapsed = pauseTime.timeIntervalSince(workoutStartTime) - totalPausedDuration
                } else {
                    elapsed = currentTime.timeIntervalSince(workoutStartTime) - totalPausedDuration
                }
            }
            
            workoutDuration = formatDuration(elapsed)
            
            // If workout was active, resume timer
            if wasActive {
                startTimer()
            }
            
            print("✅ Session restored successfully:")
            print("   - \(state.routineName) with \(state.exercises.count) exercises")
            print("   - elapsed: \(formatDuration(elapsed))")
            
        } catch {
            print("❌ Error restoring session: \(error)")
            clearSession()
        }
    }
    
    private func clearSession() {
        print("🧹 WorkoutSessionManager: Starting clearSession()")
        print("🧹 WorkoutSessionManager: Before clear - workoutState: \(workoutState?.routineName ?? "nil")")
        
        stopTimer()
        
        workoutState = nil
        isActive = false
        isRoutineWorkout = false
        isQuickWorkout = false
        currentExercise = nil
        workoutDuration = "0s"
        
        // Reset timing variables
        workoutStartTime = Date()
        totalPausedDuration = 0
        lastPauseTime = nil
        
        // Clear UserDefaults
        userDefaults.removeObject(forKey: Keys.workoutState)
        userDefaults.removeObject(forKey: Keys.startTime)
        userDefaults.removeObject(forKey: Keys.totalPausedDuration)
        userDefaults.removeObject(forKey: Keys.lastPauseTime)
        userDefaults.removeObject(forKey: Keys.isActive)
        userDefaults.removeObject(forKey: Keys.currentExercise)
        
        print("🧹 WorkoutSessionManager: Session cleared - workoutState is now: \(workoutState?.routineName ?? "nil")")
        print("🧹 WorkoutSessionManager: Published workoutState should trigger UI update")
    }
}