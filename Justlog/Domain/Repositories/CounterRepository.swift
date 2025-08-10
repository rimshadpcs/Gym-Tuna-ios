import Foundation
import Combine

protocol CounterRepository {
    func getCounters(userId: String) -> AnyPublisher<[Counter], Error>
    func createCounter(_ counter: Counter) async throws
    func updateCounter(_ counter: Counter) async throws
    func deleteCounter(_ counterId: String) async throws
    func incrementCounter(_ counterId: String, by amount: Int) async throws
    func decrementCounter(_ counterId: String, by amount: Int) async throws
    func addCounterEntry(_ entry: CounterEntry) async throws
    func getCounterStats(_ counterId: String) async throws -> CounterStats
    
    // MARK: - Cleanup
    func onCleared()
    func clearCache()
}