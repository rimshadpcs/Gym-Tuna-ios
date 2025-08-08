import Foundation

struct Counter: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let userId: String
    let currentCount: Int
    let todayCount: Int
    let createdAt: Int64
    let lastResetDate: String
    
    init(
        id: String = UUID().uuidString,
        name: String,
        userId: String,
        currentCount: Int = 0,
        todayCount: Int = 0,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        lastResetDate: String = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: Date())
        }()
    ) {
        self.id = id
        self.name = name
        self.userId = userId
        self.currentCount = currentCount
        self.todayCount = todayCount
        self.createdAt = createdAt
        self.lastResetDate = lastResetDate
    }
}