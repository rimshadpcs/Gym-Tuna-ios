//
//  HomeViewModel.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var workouts: [Workout] = []
    @Published var subscription = UserSubscription()
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedDate = Date()
    @Published var weekDates: [WeeklyCalendarDay] = []
    @Published var activeWorkout: Workout? = nil
    @Published var showConflictDialog = false
    @Published var conflictWorkout: Workout? = nil
    @Published var currentUser: User? = nil
    
    // MARK: - Private Properties
    private let workoutRepository: WorkoutRepository
    private let authRepository: AuthRepository
    private let workoutSessionManager: WorkoutSessionManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var filteredWorkouts: [Workout] {
        let isPremium = subscription.tier == .premium && subscription.isActive
        
        if isPremium {
            return workouts
        } else {
            // Free users: show max 3 routines
            return Array(workouts.prefix(3))
        }
    }
    
    var hiddenWorkoutCount: Int {
        let isPremium = subscription.tier == .premium && subscription.isActive
        return isPremium ? 0 : max(0, workouts.count - 3)
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon" 
        case 17..<21:
            return "Good evening"
        default:
            return "Good night"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Initialization
    init(
        workoutRepository: WorkoutRepository,
        authRepository: AuthRepository,
        workoutSessionManager: WorkoutSessionManager
    ) {
        self.workoutRepository = workoutRepository
        self.authRepository = authRepository
        self.workoutSessionManager = workoutSessionManager
        
        setupWeekDates()
        
        Task {
            await loadInitialData()
        }
        
        // Listen to workout session changes
        workoutSessionManager.$workoutState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionState in
                // For now, create a mock workout based on session state
                if let state = sessionState {
                    // Create a temporary workout object from session state
                    let workout = Workout(
                        id: state.routineId ?? UUID().uuidString,
                        name: state.routineName,
                        userId: "",
                        exercises: [],
                        createdAt: Date(),
                        colorHex: nil
                    )
                    self?.activeWorkout = workout
                } else {
                    self?.activeWorkout = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadInitialData() async {
        await loadCurrentUser()
        await loadSubscription()
        await loadWorkouts()
    }
    
    func refreshData() async {
        await loadWorkouts()
        await loadSubscription()
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        setupWeekDates()
    }
    
    func navigateToPreviousWeek() {
        let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
        selectDate(newDate)
    }
    
    func navigateToNextWeek() {
        let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
        selectDate(newDate)
    }
    
    func startRoutine(_ workout: Workout) {
        // Check if there's already an active workout
        if let active = activeWorkout, active.id != workout.id {
            conflictWorkout = workout
            showConflictDialog = true
            return
        }
        
        // Convert Exercise objects to WorkoutExercise objects
        let workoutExercises = workout.exercises.map { exercise in
            WorkoutExercise(
                exercise: exercise,
                sets: [] // Empty sets - will be populated during workout
            )
        }
        
        workoutSessionManager.startWorkout(
            routineId: workout.id,
            routineName: workout.name,
            exercises: workoutExercises
        )
    }
    
    func continueActiveWorkout() {
        // Already handled by workoutSessionManager publisher
    }
    
    func endActiveWorkout() {
        workoutSessionManager.discardWorkout()
    }
    
    func resolveConflict(replaceActive: Bool) {
        guard let conflictWorkout = conflictWorkout else { return }
        
        if replaceActive {
            workoutSessionManager.discardWorkout()
            startRoutine(conflictWorkout)
        }
        
        self.conflictWorkout = nil
        showConflictDialog = false
    }
    
    func dismissConflictDialog() {
        conflictWorkout = nil
        showConflictDialog = false
    }
    
    // MARK: - Private Methods
    private func loadCurrentUser() async {
        currentUser = await authRepository.getCurrentUser()
    }
    
    private func loadSubscription() async {
        do {
            let subscriptionPublisher = try await SubscriptionRepositoryImpl().getUserSubscription()
            subscriptionPublisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] subscription in
                        self?.subscription = subscription
                    }
                )
                .store(in: &cancellables)
        } catch {
            print("Error loading subscription: \(error)")
            subscription = UserSubscription()
        }
    }
    
    private func loadWorkouts() async {
        guard let user = currentUser else { return }
        
        isLoading = true
        
        do {
            let workoutsPublisher = try await workoutRepository.getWorkouts(userId: user.id)
            workoutsPublisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = "Failed to load workouts: \(error.localizedDescription)"
                        }
                    },
                    receiveValue: { [weak self] workouts in
                        // Sort workouts by creation date (newest first)
                        self?.workouts = workouts.sorted { $0.createdAt > $1.createdAt }
                        self?.isLoading = false
                    }
                )
                .store(in: &cancellables)
        } catch {
            isLoading = false
            errorMessage = "Failed to load workouts: \(error.localizedDescription)"
        }
    }
    
    private func setupWeekDates() {
        let calendar = Calendar.current
        let today = Date()
        
        weekDates = (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return nil }
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "E"
            let dayName = dayFormatter.string(from: date)
            
            let dayNumber = calendar.component(.day, from: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            
            return WeeklyCalendarDay(
                date: date,
                dayName: dayName,
                dayNumber: dayNumber,
                isToday: isToday,
                isSelected: isSelected,
                hasWorkout: false // TODO: Implement workout scheduling
            )
        }
    }
}

