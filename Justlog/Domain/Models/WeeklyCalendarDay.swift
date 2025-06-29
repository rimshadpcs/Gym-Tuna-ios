//
//  WeeklyCalendarDay.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//


import Foundation

struct WeeklyCalendarDay: Codable, Equatable {
    let date: Date
    let routineId: String?
    let isCompleted: Bool
    let colorHex: String?
    
    init(
        date: Date,
        routineId: String? = nil,
        isCompleted: Bool = false,
        colorHex: String? = nil
    ) {
        self.date = date
        self.routineId = routineId
        self.isCompleted = isCompleted
        self.colorHex = colorHex
    }
}