import Foundation

struct MonthlyCalendarDay: Codable, Identifiable, Equatable {
    let id: String
    let date: Date
    let colorHex: String?
    
    init(
        id: String = UUID().uuidString,
        date: Date,
        colorHex: String? = nil
    ) {
        self.id = id
        self.date = date
        self.colorHex = colorHex
    }
}