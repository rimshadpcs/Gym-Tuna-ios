import Foundation

struct RoutineSummary: Codable, Identifiable, Equatable {
    let id: String
    let routineId: String
    let name: String
    let colorHex: String
    let timesDone: Int
    let lastPerformed: Date
    
    init(
        id: String = UUID().uuidString,
        routineId: String,
        name: String,
        colorHex: String,
        timesDone: Int,
        lastPerformed: Date
    ) {
        self.id = id
        self.routineId = routineId
        self.name = name
        self.colorHex = colorHex
        self.timesDone = timesDone
        self.lastPerformed = lastPerformed
    }
}