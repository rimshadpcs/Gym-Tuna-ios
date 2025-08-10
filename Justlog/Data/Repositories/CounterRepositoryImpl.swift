import Foundation
import Combine

class CounterRepositoryImpl: CounterRepository {
    
    // MARK: - Persistent Mock Implementation
    // Using UserDefaults for development - will be replaced with Firebase later
    
    private var counters: [Counter] = []
    private var entries: [CounterEntry] = []
    private let countersSubject = CurrentValueSubject<[Counter], Error>([])
    private let userDefaults = UserDefaults.standard
    private let countersKey = "saved_counters"
    private let hasEverSavedKey = "has_ever_saved_counters"
    
    init() {
        loadCountersFromStorage()
    }
    
    func getCounters(userId: String) -> AnyPublisher<[Counter], Error> {
        print("\n🔄 getCounters() called for userId: \(userId)")
        
        // Load from persistent storage
        loadCountersFromStorage()
        print("📊 After loading from storage: \(counters.count) counters")
        print("📋 Counter names: \(counters.map { $0.name })")
        
        // Only create initial mock data if we've never saved anything before
        let hasEverSaved = userDefaults.bool(forKey: hasEverSavedKey)
        if counters.isEmpty && !hasEverSaved {
            print("🆕 First time - creating initial mock data")
            let mockCounters = [
                Counter(name: "Pull-ups", userId: userId, currentCount: 132, todayCount: 0),
                Counter(name: "Push-ups", userId: userId, currentCount: 89, todayCount: 12),
                Counter(name: "Squats", userId: userId, currentCount: 300, todayCount: 50)
            ]
            counters = mockCounters
            saveCountersToStorage()
        } else if counters.isEmpty && hasEverSaved {
            print("🗑️ User deleted all counters - staying empty")
        }
        
        // Check for daily reset on all counters
        let currentDate = getCurrentDateString()
        let resetCounters = counters.map { counter in
            if counter.lastResetDate != currentDate && counter.todayCount > 0 {
                print("🔄 Daily Reset: \(counter.name) - Reset todayCount from \(counter.todayCount) to 0 (date changed from \(counter.lastResetDate) to \(currentDate))")
                // Reset today count for new day
                return Counter(
                    id: counter.id,
                    name: counter.name,
                    userId: counter.userId,
                    currentCount: counter.currentCount,
                    todayCount: 0, // Reset to 0 for new day
                    createdAt: counter.createdAt,
                    lastResetDate: currentDate
                )
            } else {
                print("📊 Daily Check: \(counter.name) - No reset needed (lastReset: \(counter.lastResetDate), current: \(currentDate), todayCount: \(counter.todayCount))")
            }
            return counter
        }
        
        counters = resetCounters
        saveCountersToStorage() // Save after daily reset
        countersSubject.send(resetCounters)
        
        return countersSubject.eraseToAnyPublisher()
    }
    
    func createCounter(_ counter: Counter) async throws {
        counters.append(counter)
        saveCountersToStorage()
        countersSubject.send(counters)
        print("✅ Counter created and saved: \(counter.name)")
    }
    
    func updateCounter(_ counter: Counter) async throws {
        if let index = counters.firstIndex(where: { $0.id == counter.id }) {
            counters[index] = counter
            saveCountersToStorage()
            countersSubject.send(counters)
            print("✅ Counter updated and saved: \(counter.name)")
        }
    }
    
    func deleteCounter(_ counterId: String) async throws {
        let counterName = counters.first { $0.id == counterId }?.name ?? "Unknown"
        let beforeCount = counters.count
        
        print("🗑️ DELETING Counter: \(counterName) (ID: \(counterId))")
        print("🔢 Counters before deletion: \(beforeCount)")
        print("📋 Counter IDs before: \(counters.map { $0.id })")
        
        counters.removeAll { $0.id == counterId }
        entries.removeAll { $0.counterId == counterId }
        
        let afterCount = counters.count
        print("🔢 Counters after deletion: \(afterCount)")
        print("📋 Counter IDs after: \(counters.map { $0.id })")
        
        saveCountersToStorage()
        countersSubject.send(counters)
        print("✅ Counter deletion complete: \(counterName)")
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
            saveCountersToStorage()
            countersSubject.send(counters)
        }
    }
    
    func decrementCounter(_ counterId: String, by amount: Int) async throws {
        if let index = counters.firstIndex(where: { $0.id == counterId }) {
            let counter = counters[index]
            let currentDate = getCurrentDateString()
            
            // Check if daily reset is needed (same logic as increment)
            let shouldReset = counter.lastResetDate != currentDate
            let adjustedTodayCount = shouldReset ? 0 : counter.todayCount
            
            let newTodayCount = max(0, adjustedTodayCount - amount)
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
            saveCountersToStorage()
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
    
    // MARK: - Persistence Methods
    
    private func saveCountersToStorage() {
        do {
            let data = try JSONEncoder().encode(counters)
            userDefaults.set(data, forKey: countersKey)
            userDefaults.set(true, forKey: hasEverSavedKey) // Mark that we've saved before
            print("💾 SAVE: Saved \(counters.count) counters to UserDefaults")
            print("💾 SAVE: Counter names: \(counters.map { $0.name })")
        } catch {
            print("❌ Failed to save counters: \(error)")
        }
    }
    
    private func loadCountersFromStorage() {
        guard let data = userDefaults.data(forKey: countersKey) else {
            print("📂 LOAD: No saved counters found in UserDefaults")
            counters = []
            return
        }
        
        do {
            let loadedCounters = try JSONDecoder().decode([Counter].self, from: data)
            counters = loadedCounters
            print("📂 LOAD: Loaded \(counters.count) counters from UserDefaults")
            print("📂 LOAD: Counter names: \(counters.map { $0.name })")
        } catch {
            print("❌ Failed to load counters: \(error)")
            counters = []
        }
    }
    
    // MARK: - Cleanup
    
    func onCleared() {
        clearCache()
    }
    
    func clearCache() {
        print("🧹 Clearing counter repository cache and UserDefaults")
        counters = []
        entries = []
        countersSubject.send([])
        
        // Clear UserDefaults
        userDefaults.removeObject(forKey: countersKey)
        userDefaults.removeObject(forKey: hasEverSavedKey)
    }
}