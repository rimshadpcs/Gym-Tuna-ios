//
//  HomeViewModel.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//


// Presentation/Home/HomeViewModel.swift
import Foundation
import Combine
import os.log

@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var workoutState: WorkoutState = .initial
    @Published var currentWorkout: Workout?
    @Published var weeklyCalendar: [WeeklyCalendarDay] = []
    
    // MARK: - Private Properties
    private let workoutRepository: WorkoutRepository
    private let authRepository: AuthRepository
    private let workoutSessionManager: WorkoutSessionManager
    private var cancellables = Set<AnyCancellable>()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "JustLog", category: "HomeViewModel")
    
    // MARK: - Initialization
    init(
        workoutRepository: WorkoutRepository,
        authRepository: AuthRepository,
        workoutSessionManager: WorkoutSessionManager
    ) {
        self.workoutRepository = workoutRepository
        self.authRepository = authRepository
        self.workoutSessionManager = workoutSessionManager
        
        setupObservables()
        loadWorkouts()
    }
    
    // MARK: - Setup
    private func setupObservables() {
        // Setup weekly calendar observable
        Task {
            do {
                guard let userId = try await authRepository.getCurrentUser()?.id else {
                    throw WorkoutError.userNotAuthenticated
                }
                
                logger.debug("Starting to collect weekly calendar data")
                
                // Convert Combine publisher to AsyncSequence for SwiftUI
                for try await calendar in workoutRepository.getWeeklyCalendar().values {
                    logger.debug("Received calendar data: \(calendar.count) days")
                    self.weeklyCalendar = calendar
                    
                    for day in calendar {
                        logger.debug("Day \(day.date) colorHex=\(day.colorHex ?? "nil")")
                    }
                }
            } catch {
                logger.error("Error collecting calendar data: \(error.localizedDescription)")
                self.workoutState = .error(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Public Methods
    func loadWorkouts() {
        Task {
            do {
                self.workoutState = .loading
                
                guard let userId = try await authRepository.getCurrentUser()?.id else {
                    throw WorkoutError.userNotAuthenticated
                }
                
                // Subscribe to workout updates
                for try await workouts in try await workoutRepository.getWorkouts(userId: userId).values {
                    let sortedWorkouts = sortWorkoutsByLastPerformed(workouts)
                    
                    logger.debug("📋 Workouts sorted by last performed:")
                    for (index, workout) in sortedWorkouts.enumerated() {
                        let lastPerformed = workout.lastPerformed?.formatted(date: .abbreviated, time: .omitted) ?? "Never"
                        logger.debug("  \(index + 1). \(workout.name) - Last: \(lastPerformed)")
                    }
                    
                    self.workoutState = .success(sortedWorkouts)
                }
            } catch {
                logger.error("Error in loadWorkouts: \(error.localizedDescription)")
                self.workoutState = .error("Failed to load workouts: \(error.localizedDescription)")
            }
        }
    }
    
    func duplicateWorkout(_ workout: Workout) {
        Task {
            do {
                let newName = "\(workout.name) (Copy)"
                let newWorkout = Workout(
                    id: newName.lowercased().replacingOccurrences(of: " ", with: "_"),
                    name: newName,
                    userId: workout.userId,
                    exercises: workout.exercises,
                    createdAt: Date(),
                    colorHex: workout.colorHex,
                    lastPerformed: nil // Reset last performed for duplicate
                )
                
                try await workoutRepository.createWorkout(newWorkout)
                logger.debug("✅ Duplicated workout: \(newName)")
            } catch {
                logger.error("❌ Error duplicating workout: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteWorkout(_ workoutId: String) {
        Task {
            do {
                // Check if there's an active workout session for this routine
                let currentSession = workoutSessionManager.getWorkoutState()
                if currentSession?.routineId == workoutId {
                    // The routine being deleted is currently active, so discard the session
                    logger.debug("🏋️ Discarding active workout session for deleted routine: \(workoutId)")
                    workoutSessionManager.discardWorkout()
                }
                
                try await workoutRepository.deleteWorkout(workoutId)
                logger.debug("✅ Deleted workout: \(workoutId)")
            } catch {
                logger.error("❌ Error deleting workout: \(error.localizedDescription)")
            }
        }
    }
    
    func signOut() {
        Task {
            do {
                try await authRepository.signOut()
                self.workoutState = .initial
                self.currentWorkout = nil
            } catch {
                logger.error("Error signing out: \(error.localizedDescription)")
                self.workoutState = .error("Sign out failed: \(error.localizedDescription)")
            }
        }
    }
    
    func retryLoadWorkouts() {
        loadWorkouts()
    }
    
    // MARK: - Private Methods
    
    /**
     * Sort workouts by last performed date:
     * - Workouts never performed come first (top priority)
     * - Then workouts performed longest ago
     * - Most recently performed workouts go to bottom
     */
    private func sortWorkoutsByLastPerformed(_ workouts: [Workout]) -> [Workout] {
        return workouts.sorted { workout1, workout2 in
            // Primary sort: nil lastPerformed (never done) should come first
            switch (workout1.lastPerformed, workout2.lastPerformed) {
            case (nil, nil):
                return false // Equal
            case (nil, _):
                return true // workout1 comes first (never performed)
            case (_, nil):
                return false // workout2 comes first (never performed)
            case let (date1?, date2?):
                return date1 < date2 // Earlier dates come first
            }
        }
    }
}

// MARK: - Error Types
enum WorkoutError: LocalizedError {
    case userNotAuthenticated
    case networkError
    case dataCorruption
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .networkError:
            return "Network connection error"
        case .dataCorruption:
            return "Data corruption detected"
        }
    }
}

// MARK: - Publisher Extensions for Async/Await
extension Publisher {
    var values: AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream { continuation in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                },
                receiveValue: { value in
                    continuation.yield(value)
                }
            )
            
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}