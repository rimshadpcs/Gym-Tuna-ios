// Utils/DateExtensions.swift
import Foundation

extension Date {
    // Convert to milliseconds since epoch (matching Kotlin Long timestamps)
    var millisecondsSince1970: Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
    
    // Create Date from milliseconds since epoch
    init(millisecondsSince1970: Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(millisecondsSince1970) / 1000.0)
    }
}
