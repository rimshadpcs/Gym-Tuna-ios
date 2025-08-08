//
//  WeeklyCalendarDay.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//


import Foundation

struct WeeklyCalendarDay: Codable, Equatable {
    let date: Date
    let dayName: String
    let dayNumber: Int
    let isToday: Bool
    let isSelected: Bool
    let hasWorkout: Bool
    let routineId: String?
    let isCompleted: Bool
    let colorHex: String?
    
    init(
        date: Date,
        dayName: String,
        dayNumber: Int,
        isToday: Bool,
        isSelected: Bool,
        hasWorkout: Bool = false,
        routineId: String? = nil,
        isCompleted: Bool = false,
        colorHex: String? = nil
    ) {
        self.date = date
        self.dayName = dayName
        self.dayNumber = dayNumber
        self.isToday = isToday
        self.isSelected = isSelected
        self.hasWorkout = hasWorkout
        self.routineId = routineId
        self.isCompleted = isCompleted
        self.colorHex = colorHex
    }
}