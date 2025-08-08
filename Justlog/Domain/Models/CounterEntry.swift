import Foundation

struct CounterEntry: Codable, Identifiable, Equatable {
    let id: String
    let counterId: String
    let count: Int
    let date: String
    let timestamp: Int64
    
    init(
        id: String = UUID().uuidString,
        counterId: String,
        count: Int,
        date: String,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.counterId = counterId
        self.count = count
        self.date = date
        self.timestamp = timestamp
    }
}