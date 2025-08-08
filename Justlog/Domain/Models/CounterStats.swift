import Foundation

struct CounterStats: Codable, Equatable {
    let yesterday: Int
    let today: Int
    let thisWeek: Int
    let thisMonth: Int
    let thisYear: Int
    let allTime: Int
    
    init(
        yesterday: Int = 0,
        today: Int = 0,
        thisWeek: Int = 0,
        thisMonth: Int = 0,
        thisYear: Int = 0,
        allTime: Int = 0
    ) {
        self.yesterday = yesterday
        self.today = today
        self.thisWeek = thisWeek
        self.thisMonth = thisMonth
        self.thisYear = thisYear
        self.allTime = allTime
    }
}