import Foundation
import Combine

@MainActor
class CounterViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var allCounters: [Counter] = []
    @Published var counters: [Counter] = []
    @Published var hiddenCountersCount: Int = 0
    @Published var subscription = UserSubscription()
    @Published var isLoading = false
    @Published var counterStats: [String: CounterStats] = [:]
    @Published var errorMessage: String? = nil
    @Published var showPremiumBenefits = false
    
    // MARK: - Private Properties
    private let counterRepository: CounterRepository
    private let subscriptionRepository: SubscriptionRepository
    private let authRepository: AuthRepository
    private var cancellables = Set<AnyCancellable>()
    
    // Track pending changes for UI feedback
    private var activelyUpdatingCounters = Set<String>()
    private var pendingChanges: [String: Int] = [:]
    private var updateTasks: [String: Task<Void, Never>] = [:]
    
    // MARK: - Initialization
    init(
        counterRepository: CounterRepository,
        subscriptionRepository: SubscriptionRepository,
        authRepository: AuthRepository
    ) {
        self.counterRepository = counterRepository
        self.subscriptionRepository = subscriptionRepository
        self.authRepository = authRepository
        
        Task {
            await loadCounters()
            await loadSubscription()
        }
    }
    
    // MARK: - Public Methods
    func loadCounters() async {
        guard let user = await authRepository.getCurrentUser() else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        
        counterRepository.getCounters(userId: user.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = "Failed to load counters: \(error.localizedDescription)"
                    }
                    self.isLoading = false
                },
                receiveValue: { [weak self] firebaseCounters in
                    let processedCounters = firebaseCounters.map { firebaseCounter in
                        if self?.activelyUpdatingCounters.contains(firebaseCounter.id) == true {
                            // Keep local optimistic version
                            return self?.allCounters.first { $0.id == firebaseCounter.id } ?? firebaseCounter
                        } else {
                            // Check for daily reset
                            let currentDate = self?.getCurrentDateString() ?? ""
                            if firebaseCounter.lastResetDate != currentDate && firebaseCounter.todayCount > 0 {
                                return Counter(
                                    id: firebaseCounter.id,
                                    name: firebaseCounter.name,
                                    userId: firebaseCounter.userId,
                                    currentCount: firebaseCounter.currentCount,
                                    todayCount: 0,
                                    createdAt: firebaseCounter.createdAt,
                                    lastResetDate: currentDate
                                )
                            }
                            return firebaseCounter
                        }
                    }
                    
                    self?.allCounters = processedCounters
                    self?.filterCountersBasedOnSubscription()
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadSubscription() async {
        do {
            let subscriptionPublisher = try await subscriptionRepository.getUserSubscription()
            subscriptionPublisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] subscription in
                        let previousSubscription = self?.subscription
                        self?.subscription = subscription
                        
                        // Filter counters when subscription changes
                        if previousSubscription?.tier != subscription.tier ||
                           previousSubscription?.isActive != subscription.isActive {
                            self?.filterCountersBasedOnSubscription()
                        }
                    }
                )
                .store(in: &cancellables)
        } catch {
            print("Error loading subscription: \\(error)")
            subscription = UserSubscription()
        }
    }
    
    private func filterCountersBasedOnSubscription() {
        let isPremium = subscription.tier == .premium && subscription.isActive
        
        if isPremium {
            // Premium users see all counters
            counters = allCounters
            hiddenCountersCount = 0
        } else {
            // Free users see only the first counter
            counters = Array(allCounters.prefix(1))
            hiddenCountersCount = max(0, allCounters.count - 1)
        }
    }
    
    func createCounter(_ name: String) {
        Task {
            guard let user = await authRepository.getCurrentUser() else {
                errorMessage = "User not authenticated"
                return
            }
            
            // Check subscription limits
            if !canCreateNewCounter() {
                showPremiumBenefits = true
                return
            }
            
            isLoading = true
            
            do {
                let counter = Counter(name: name, userId: user.id)
                try await counterRepository.createCounter(counter)
                isLoading = false
            } catch {
                errorMessage = "Failed to create counter: \\(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func incrementCounter(_ counterId: String) {
        // Immediate UI update
        updateCounterOptimistically(counterId, change: 1)
        updateStatsOptimistically(counterId, change: 1)
        
        activelyUpdatingCounters.insert(counterId)
        let currentPending = pendingChanges[counterId] ?? 0
        pendingChanges[counterId] = currentPending + 1
        
        // Debounced sync
        updateTasks[counterId]?.cancel()
        updateTasks[counterId] = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await syncPendingChanges(counterId)
        }
    }
    
    func decrementCounter(_ counterId: String) {
        guard let counter = allCounters.first(where: { $0.id == counterId }),
              counter.todayCount > 0 else {
            return
        }
        
        // Immediate UI update
        updateCounterOptimistically(counterId, change: -1)
        updateStatsOptimistically(counterId, change: -1)
        
        activelyUpdatingCounters.insert(counterId)
        let currentPending = pendingChanges[counterId] ?? 0
        pendingChanges[counterId] = currentPending - 1
        
        // Debounced sync
        updateTasks[counterId]?.cancel()
        updateTasks[counterId] = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await syncPendingChanges(counterId)
        }
    }
    
    func updateCounterTodayCount(_ counterId: String, newTodayCount: Int) {
        Task {
            guard let currentCounter = allCounters.first(where: { $0.id == counterId }) else {
                return
            }
            
            updateTasks[counterId]?.cancel()
            updateTasks.removeValue(forKey: counterId)
            pendingChanges.removeValue(forKey: counterId)
            
            let todayDifference = newTodayCount - currentCounter.todayCount
            let newTotalCount = currentCounter.currentCount + todayDifference
            
            if todayDifference == 0 {
                activelyUpdatingCounters.remove(counterId)
                return
            }
            
            activelyUpdatingCounters.insert(counterId)
            
            // Update UI immediately
            let currentDate = getCurrentDateString()
            let updatedCounter = Counter(
                id: currentCounter.id,
                name: currentCounter.name,
                userId: currentCounter.userId,
                currentCount: max(0, newTotalCount),
                todayCount: max(0, newTodayCount),
                createdAt: currentCounter.createdAt,
                lastResetDate: currentDate
            )
            
            updateCounterInArrays(updatedCounter)
            updateStatsOptimistically(counterId, change: todayDifference)
            
            // Sync to backend
            do {
                try await counterRepository.updateCounter(updatedCounter)
                
                if todayDifference != 0 {
                    let entry = CounterEntry(
                        counterId: counterId,
                        count: todayDifference,
                        date: currentDate
                    )
                    try await counterRepository.addCounterEntry(entry)
                }
                
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                activelyUpdatingCounters.remove(counterId)
            } catch {
                errorMessage = "Failed to update counter: \\(error.localizedDescription)"
                activelyUpdatingCounters.remove(counterId)
            }
        }
    }
    
    func updateCounter(_ counter: Counter) {
        Task {
            do {
                updateCounterInArrays(counter)
                try await counterRepository.updateCounter(counter)
            } catch {
                errorMessage = "Failed to update counter: \\(error.localizedDescription)"
            }
        }
    }
    
    func deleteCounter(_ counterId: String) {
        Task {
            do {
                updateTasks[counterId]?.cancel()
                updateTasks.removeValue(forKey: counterId)
                pendingChanges.removeValue(forKey: counterId)
                activelyUpdatingCounters.remove(counterId)
                
                // Remove from arrays
                allCounters.removeAll { $0.id == counterId }
                counters.removeAll { $0.id == counterId }
                filterCountersBasedOnSubscription()
                
                try await counterRepository.deleteCounter(counterId)
            } catch {
                errorMessage = "Failed to delete counter: \\(error.localizedDescription)"
            }
        }
    }
    
    func loadCounterStats(_ counterId: String) {
        Task {
            do {
                let stats = try await counterRepository.getCounterStats(counterId)
                counterStats[counterId] = stats
            } catch {
                errorMessage = "Failed to load stats: \\(error.localizedDescription)"
            }
        }
    }
    
    func hasPendingChanges(_ counterId: String) -> Bool {
        return activelyUpdatingCounters.contains(counterId)
    }
    
    func resetPremiumBenefitsNavigation() {
        showPremiumBenefits = false
    }
    
    // MARK: - Private Methods
    private func updateCounterOptimistically(_ counterId: String, change: Int) {
        guard let index = allCounters.firstIndex(where: { $0.id == counterId }) else { return }
        
        let currentCounter = allCounters[index]
        let currentDate = getCurrentDateString()
        
        // Check if we need to reset today's count
        let shouldResetToday = currentCounter.lastResetDate != currentDate
        let newTodayCount = if shouldResetToday {
            max(0, change) // Start fresh or don't go negative
        } else {
            max(0, currentCounter.todayCount + change)
        }
        
        let updatedCounter = Counter(
            id: currentCounter.id,
            name: currentCounter.name,
            userId: currentCounter.userId,
            currentCount: max(0, currentCounter.currentCount + change),
            todayCount: newTodayCount,
            createdAt: currentCounter.createdAt,
            lastResetDate: currentDate
        )
        
        updateCounterInArrays(updatedCounter)
    }
    
    private func updateCounterInArrays(_ counter: Counter) {
        // Update all counters
        if let allIndex = allCounters.firstIndex(where: { $0.id == counter.id }) {
            allCounters[allIndex] = counter
        }
        
        // Update visible counters
        if let visibleIndex = counters.firstIndex(where: { $0.id == counter.id }) {
            counters[visibleIndex] = counter
        }
    }
    
    private func syncPendingChanges(_ counterId: String) async {
        guard let totalChange = pendingChanges[counterId], totalChange != 0 else {
            activelyUpdatingCounters.remove(counterId)
            pendingChanges.removeValue(forKey: counterId)
            updateTasks.removeValue(forKey: counterId)
            return
        }
        
        do {
            if totalChange > 0 {
                try await counterRepository.incrementCounter(counterId, by: totalChange)
            } else {
                try await counterRepository.decrementCounter(counterId, by: -totalChange)
            }
            
            pendingChanges.removeValue(forKey: counterId)
            updateTasks.removeValue(forKey: counterId)
            
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            activelyUpdatingCounters.remove(counterId)
        } catch {
            errorMessage = "Failed to sync changes: \\(error.localizedDescription)"
            pendingChanges.removeValue(forKey: counterId)
            updateTasks.removeValue(forKey: counterId)
            activelyUpdatingCounters.remove(counterId)
        }
    }
    
    private func updateStatsOptimistically(_ counterId: String, change: Int) {
        if let currentStats = counterStats[counterId] {
            let updatedStats = CounterStats(
                yesterday: currentStats.yesterday,
                today: max(0, currentStats.today + change),
                thisWeek: max(0, currentStats.thisWeek + change),
                thisMonth: max(0, currentStats.thisMonth + change),
                thisYear: max(0, currentStats.thisYear + change),
                allTime: max(0, currentStats.allTime + change)
            )
            counterStats[counterId] = updatedStats
        }
    }
    
    private func canCreateNewCounter() -> Bool {
        let isPremium = subscription.tier == .premium && subscription.isActive
        if isPremium {
            return true
        }
        
        // Free users limited to 1 counter
        return allCounters.count < 1
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}