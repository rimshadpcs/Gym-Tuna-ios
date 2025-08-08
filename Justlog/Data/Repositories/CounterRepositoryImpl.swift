import Foundation
import Combine

class CounterRepositoryImpl: CounterRepository {
    
    // MARK: - Mock Implementation
    // TODO: Replace with actual Firebase implementation
    
    private var counters: [Counter] = []
    private var entries: [CounterEntry] = []
    private let countersSubject = CurrentValueSubject<[Counter], Error>([])
    
    func getCounters(userId: String) -> AnyPublisher<[Counter], Error> {
        // Mock data for development
        if counters.isEmpty {
            let mockCounters = [
                Counter(name: "Pull-ups", userId: userId, currentCount: 132, todayCount: 0),
                Counter(name: "Push-ups", userId: userId, currentCount: 89, todayCount: 12),
                Counter(name: "Squats", userId: userId, currentCount: 300, todayCount: 50)
            ]
            counters = mockCounters
            countersSubject.send(mockCounters)
        }
        
        return countersSubject.eraseToAnyPublisher()
    }
    
    func createCounter(_ counter: Counter) async throws {
        counters.append(counter)
        countersSubject.send(counters)
    }
    
    func updateCounter(_ counter: Counter) async throws {
        if let index = counters.firstIndex(where: { $0.id == counter.id }) {
            counters[index] = counter
            countersSubject.send(counters)
        }
    }
    
    func deleteCounter(_ counterId: String) async throws {
        counters.removeAll { $0.id == counterId }
        entries.removeAll { $0.counterId == counterId }
        countersSubject.send(counters)
    }
    
    func incrementCounter(_ counterId: String, by amount: Int) async throws {
        if let index = counters.firstIndex(where: { $0.id == counterId }) {
            let counter = counters[index]
            let currentDate = getCurrentDateString()
            
            // Check if daily reset is needed
            let newTodayCount = counter.lastResetDate != currentDate ? amount : counter.todayCount + amount
            
            let updatedCounter = Counter(
                id: counter.id,
                name: counter.name,
                userId: counter.userId,
                currentCount: counter.currentCount + amount,
                todayCount: newTodayCount,
                createdAt: counter.createdAt,
                lastResetDate: currentDate
            )
            
            counters[index] = updatedCounter
            countersSubject.send(counters)
        }
    }
    
    func decrementCounter(_ counterId: String, by amount: Int) async throws {
        if let index = counters.firstIndex(where: { $0.id == counterId }) {
            let counter = counters[index]
            let currentDate = getCurrentDateString()
            
            let newTodayCount = max(0, counter.todayCount - amount)
            let newCurrentCount = max(0, counter.currentCount - amount)
            
            let updatedCounter = Counter(
                id: counter.id,
                name: counter.name,
                userId: counter.userId,
                currentCount: newCurrentCount,
                todayCount: newTodayCount,
                createdAt: counter.createdAt,
                lastResetDate: currentDate
            )
            
            counters[index] = updatedCounter
            countersSubject.send(counters)
        }
    }
    
    func addCounterEntry(_ entry: CounterEntry) async throws {
        entries.append(entry)
    }
    
    func getCounterStats(_ counterId: String) async throws -> CounterStats {
        // Mock stats implementation
        let counter = counters.first { $0.id == counterId }
        let todayCount = counter?.todayCount ?? 0
        let totalCount = counter?.currentCount ?? 0
        
        return CounterStats(
            yesterday: max(0, todayCount - 5),
            today: todayCount,
            thisWeek: min(totalCount, todayCount * 7),
            thisMonth: min(totalCount, todayCount * 30),
            thisYear: min(totalCount, todayCount * 365),
            allTime: totalCount
        )
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}