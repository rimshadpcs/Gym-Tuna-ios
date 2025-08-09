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
    private let workoutHistoryRepository: WorkoutHistoryRepository
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
        workoutSessionManager: WorkoutSessionManager,
        workoutHistoryRepository: WorkoutHistoryRepository
    ) {
        self.workoutRepository = workoutRepository
        self.authRepository = authRepository
        self.workoutSessionManager = workoutSessionManager
        self.workoutHistoryRepository = workoutHistoryRepository
        
        setupWeekDates()
        
        Task {
            await loadInitialData()
        }
        
        // Listen for workout completion to refresh calendar
        NotificationCenter.default.addObserver(forName: NSNotification.Name("WorkoutCompleted"), object: nil, queue: .main) { _ in
            self.refreshWeeklyCalendar()
        }
        
        // Check current workout session state immediately
        if let currentState = workoutSessionManager.getWorkoutState() {
            let workoutId = currentState.routineId ?? "quick_workout"
            activeWorkout = Workout(
                id: workoutId,
                name: currentState.routineName,
                userId: "",
                exercises: [],
                createdAt: Date(),
                colorHex: nil
            )
        }
        
        // Listen to workout session changes
        workoutSessionManager.$workoutState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionState in
                guard let self = self else { return }
                
                if let state = sessionState {
                    let workoutId = state.routineId ?? "quick_workout"
                    self.activeWorkout = Workout(
                        id: workoutId,
                        name: state.routineName,
                        userId: "",
                        exercises: [],
                        createdAt: Date(),
                        colorHex: nil
                    )
                } else {
                    self.activeWorkout = nil
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
        
        // workout.exercises is already [WorkoutExercise]
        workoutSessionManager.startWorkout(
            routineId: workout.id,
            routineName: workout.name,
            exercises: workout.exercises
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
        Task {
            await loadWeekDatesWithWorkoutData()
        }
    }
    
    private func loadWeekDatesWithWorkoutData() async {
        let calendar = Calendar.current
        let today = Date()
        
        // Get current user ID
        guard let userId = await authRepository.getCurrentUser()?.id else {
            // Fallback to basic week dates without workout data
            await MainActor.run {
                weekDates = createBasicWeekDates(calendar: calendar, today: today)
            }
            return
        }
        
        // Load workout history for this user
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? today
        
        do {
            let workoutHistory = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[WorkoutHistory], Error>) in
                let cancellable = workoutHistoryRepository.getWorkoutHistory(userId: userId)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { history in
                            // Filter to only include workouts from this week
                            let weekWorkouts = history.filter { workout in
                                workout.endTime >= weekStart && workout.endTime <= weekEnd
                            }
                            continuation.resume(returning: weekWorkouts)
                        }
                    )
                
                // Store cancellable to prevent it from being deallocated
                self.cancellables.insert(cancellable)
            }
            
            await MainActor.run {
                weekDates = createWeekDatesWithWorkoutData(
                    calendar: calendar,
                    today: today,
                    workoutHistory: workoutHistory
                )
            }
        } catch {
            print("Failed to load workout history for weekly calendar: \(error)")
            await MainActor.run {
                weekDates = createBasicWeekDates(calendar: calendar, today: today)
            }
        }
    }
    
    private func createBasicWeekDates(calendar: Calendar, today: Date) -> [WeeklyCalendarDay] {
        return (-6...0).compactMap { dayOffset in
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
                hasWorkout: false,
                routineId: nil,
                isCompleted: false,
                colorHex: nil
            )
        }
    }
    
    private func createWeekDatesWithWorkoutData(
        calendar: Calendar,
        today: Date,
        workoutHistory: [WorkoutHistory]
    ) -> [WeeklyCalendarDay] {
        return (-6...0).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return nil }
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "E"
            let dayName = dayFormatter.string(from: date)
            
            let dayNumber = calendar.component(.day, from: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            
            // Find workout for this day
            let dayWorkout = workoutHistory.first { workout in
                calendar.isDate(workout.endTime, inSameDayAs: date)
            }
            
            return WeeklyCalendarDay(
                date: date,
                dayName: dayName,
                dayNumber: dayNumber,
                isToday: isToday,
                isSelected: isSelected,
                hasWorkout: dayWorkout != nil,
                routineId: dayWorkout?.routineId,
                isCompleted: dayWorkout != nil,
                colorHex: dayWorkout?.colorHex
            )
        }
    }
    
    // MARK: - Public Methods
    
    func refreshWeeklyCalendar() {
        Task {
            await loadWeekDatesWithWorkoutData()
        }
    }
}

