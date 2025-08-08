//
//  WeeklyCalendarStrip.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI
import Foundation

struct WeeklyCalendarStrip: View {
    @Environment(\.themeManager) private var themeManager
    let weekDates: [WeeklyCalendarDay]
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    let onHistoryClick: () -> Void
    
    private var isDarkTheme: Bool {
        switch themeManager?.currentTheme {
        case .dark:
            return true
        case .neutral, .light, .none:
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with "This Week" and History button - match screenshot exactly
            HStack {
                Text("This Week")
                    .vagFont(size: 18, weight: .semibold)
                    .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                
                Spacer()
                
                Button(action: onHistoryClick) {
                    HStack(spacing: 4) {
                        Text("History")
                            .vagFont(size: 12, weight: .medium)
                        Image(isDarkTheme ? "history_dark" : "history")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                    }
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                            )
                    )
                }
            }
            
            // Calendar Days - more compact
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.date) { day in
                    DayColumn(
                        day: day,
                        isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedDate),
                        onDateSelected: onDateSelected
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, MaterialSpacing.lg)
        .padding(.vertical, 8)
    }
}

// MARK: - DayColumn
struct DayColumn: View {
    @Environment(\.themeManager) private var themeManager
    let day: WeeklyCalendarDay
    let isSelected: Bool
    let onDateSelected: (Date) -> Void
    
    var body: some View {
        Button(action: { onDateSelected(day.date) }) {
            VStack(spacing: 5) {
                // Day of week label - more compact
                Text(day.dayName.uppercased())
                    .vagFont(size: 10, weight: .medium)
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.6) ?? LightThemeColors.onSurface.opacity(0.6))
                
                // Day circle - smaller
                ZStack {
                    Circle()
                        .fill(fillColor)
                        .overlay(
                            Circle()
                                .stroke(strokeColor, lineWidth: strokeWidth)
                        )
                    
                    Text("\(day.dayNumber)")
                        .vagFont(size: 14, weight: textWeight)
                        .foregroundColor(textColor)
                }
                .frame(width: 30, height: 30)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Computed Properties
    private var fillColor: Color {
        if day.hasWorkout {
            return themeManager?.colors.primary.opacity(0.2) ?? LightThemeColors.primary.opacity(0.2)
        } else if day.isToday {
            return themeManager?.colors.primary.opacity(0.1) ?? LightThemeColors.primary.opacity(0.1)
        } else if isSelected {
            return themeManager?.colors.primary.opacity(0.15) ?? LightThemeColors.primary.opacity(0.15)
        } else {
            return Color.clear
        }
    }
    
    private var strokeColor: Color {
        if day.hasWorkout {
            return themeManager?.colors.primary ?? LightThemeColors.primary
        } else if day.isToday {
            return themeManager?.colors.primary.opacity(0.5) ?? LightThemeColors.primary.opacity(0.5)
        } else if isSelected {
            return themeManager?.colors.primary.opacity(0.7) ?? LightThemeColors.primary.opacity(0.7)
        } else {
            return Color.clear
        }
    }
    
    private var strokeWidth: CGFloat {
        if day.hasWorkout || day.isToday || isSelected {
            return 2
        } else {
            return 0
        }
    }
    
    private var textColor: Color {
        if day.hasWorkout || day.isToday {
            return themeManager?.colors.primary ?? LightThemeColors.primary
        } else {
            return themeManager?.colors.onSurface ?? LightThemeColors.onSurface
        }
    }
    
    private var textWeight: Font.Weight {
        if day.hasWorkout || day.isToday {
            return .semibold
        } else {
            return .regular
        }
    }
}
