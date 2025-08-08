import Foundation
import Combine

@MainActor
class HistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentMonth: Date = Calendar.current.startOfMonth(for: Date())
    @Published var calendarDays: [MonthlyCalendarDay] = []
    @Published var monthWorkouts: [WorkoutHistory] = []
    @Published var routines: [RoutineSummary] = []
    @Published var weightUnit: WeightUnit = .kg
    @Published var isLoading = false
    
    // MARK: - Private Properties
    private let historyRepository: WorkoutHistoryRepository
    private let authRepository: AuthRepository
    private let userPreferences: UserPreferences
    private var cancellables = Set<AnyCancellable>()
    private var userId: String?
    
    // MARK: - Initialization
    init(
        historyRepository: WorkoutHistoryRepository,
        authRepository: AuthRepository,
        userPreferences: UserPreferences
    ) {
        self.historyRepository = historyRepository
        self.authRepository = authRepository
        self.userPreferences = userPreferences
        
        setupBindings()
        
        Task {
            await loadUserId()
            await loadMonthlyHistory()
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Listen to weight unit changes
        userPreferences.$weightUnit
            .receive(on: DispatchQueue.main)
            .sink { [weak self] unit in
                self?.weightUnit = unit
            }
            .store(in: &cancellables)
        
        // Listen to month changes and reload data
        $currentMonth
            .sink { [weak self] _ in
                Task {
                    await self?.loadMonthlyHistory()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadUserId() async {
        if let user = await authRepository.getCurrentUser() {
            userId = user.id
        }
    }
    
    private func loadMonthlyHistory() async {
        guard let userId = userId else { return }
        
        isLoading = true
        
        historyRepository.getMonthlyHistory(
            userId: userId,
            monthStart: currentMonth,
            timeZone: TimeZone.current
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Error loading monthly history: \(error)")
                }
            },
            receiveValue: { [weak self] workouts in
                self?.monthWorkouts = workouts.sorted { $0.startTime > $1.startTime }
                self?.generateCalendarDays(from: workouts)
                self?.generateRoutineSummaries(from: workouts)
                self?.isLoading = false
            }
        )
        .store(in: &cancellables)
    }
    
    private func generateCalendarDays(from workouts: [WorkoutHistory]) {
        let calendar = Calendar.current
        let startOfMonth = currentMonth
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
        
        // Group workouts by date
        let workoutsByDate = Dictionary(grouping: workouts) { workout in
            return calendar.startOfDay(for: workout.startTime)
        }
        
        // Generate calendar days
        var days: [MonthlyCalendarDay] = []
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                let dayStart = calendar.startOfDay(for: date)
                let colorHex = workoutsByDate[dayStart]?.first?.colorHex
                
                days.append(MonthlyCalendarDay(
                    date: date,
                    colorHex: colorHex
                ))
            }
        }
        
        calendarDays = days
    }
    
    private func generateRoutineSummaries(from workouts: [WorkoutHistory]) {
        let routineWorkouts = workouts.filter { $0.routineId != nil }
        let groupedByRoutine = Dictionary(grouping: routineWorkouts) { $0.routineId! }
        
        routines = groupedByRoutine.compactMap { (routineId, workoutList) in
            guard let latest = workoutList.max(by: { $0.endTime < $1.endTime }) else { return nil }
            
            return RoutineSummary(
                routineId: routineId,
                name: latest.name,
                colorHex: latest.colorHex,
                timesDone: workoutList.count,
                lastPerformed: latest.endTime
            )
        }.sorted { $0.lastPerformed > $1.lastPerformed }
    }
    
    // MARK: - Public Methods
    func pageNext() {
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = nextMonth
        }
    }
    
    func pagePrev() {
        let calendar = Calendar.current
        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = prevMonth
        }
    }
}

// MARK: - Calendar Extension
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}