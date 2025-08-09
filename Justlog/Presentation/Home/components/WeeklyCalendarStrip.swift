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
    
    private var isLightTheme: Bool {
        switch themeManager?.currentTheme {
        case .light, .neutral:
            return true
        case .dark, .none:
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
                        Image(isLightTheme ? "history" : "history_dark")
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
    
    private var isLightTheme: Bool {
        switch themeManager?.currentTheme {
        case .light, .neutral:
            return true
        case .dark, .none:
            return false
        }
    }
    
    var body: some View {
        Button(action: { onDateSelected(day.date) }) {
            VStack(spacing: 4) {
                // Day of week label
                Text(day.dayName.prefix(3).uppercased())
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(secondaryContentColor)
                
                // Day circle
                ZStack {
                    Circle()
                        .fill(fillColor)
                        .overlay(
                            Circle()
                                .stroke(ringColor, lineWidth: strokeWidth)
                        )
                    
                    Text("\(day.dayNumber)")
                        .font(.system(size: 14, weight: textWeight))
                        .foregroundColor(textColor)
                }
                .frame(width: 32, height: 32)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
    
    // MARK: - Computed Properties (matching Android logic exactly)
    
    private var contentColor: Color {
        return themeManager?.colors.onBackground ?? (isLightTheme ? Color.black : Color.white)
    }
    
    private var secondaryContentColor: Color {
        return contentColor.opacity(0.6)
    }
    
    // Ring color based on day's colorHex or theme
    private var ringColor: Color {
        if let colorHex = day.colorHex {
            // Parse hex color
            return Color(hex: colorHex) ?? (isLightTheme ? Color.gray : Color(.lightGray))
        } else {
            return isLightTheme ? Color.gray : Color(.lightGray)
        }
    }
    
    // Today highlight color
    private var todayHighlightColor: Color {
        if isLightTheme {
            return Color.gray.opacity(0.10)
        } else {
            return Color.white.opacity(0.20)
        }
    }
    
    // Fill color based on completion status, today status, and theme
    private var fillColor: Color {
        if let _ = day.colorHex {
            // For days with custom colors, adjust opacity based on theme
            if isLightTheme {
                return ringColor.opacity(0.35)
            } else {
                return ringColor.opacity(0.45)
            }
        } else if day.isToday {
            return todayHighlightColor
        } else {
            return Color.clear
        }
    }
    
    private var strokeWidth: CGFloat {
        if day.isCompleted {
            return isLightTheme ? 1.5 : 1.5
        } else {
            return 1.5
        }
    }
    
    // Text color logic based on status and theme
    private var textColor: Color {
        if day.isToday {
            return contentColor // Today's text uses primary content color
        } else if day.colorHex != nil {
            // For days with color, adapt text color based on theme
            return isLightTheme ? Color.black : Color.white
        } else {
            return secondaryContentColor // Other days use secondary content color
        }
    }
    
    private var textWeight: Font.Weight {
        if day.isToday {
            return .bold
        } else if day.colorHex != nil {
            return .semibold
        } else {
            return .regular
        }
    }
}

