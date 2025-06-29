//
//  WeeklyCalendarStrip.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI
import Foundation

struct WeeklyCalendarStrip: View {
    let weeklyCalendar: [WeeklyCalendarDay]
    let onHistoryClick: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isLightTheme: Bool {
        colorScheme == .light
    }
    
    var body: some View {
        VStack(spacing: MaterialSpacing.lg) {
            // Header (Material Design style)
            HStack {
                Text("This Week")
                    .font(MaterialTypography.headline6)
                    .foregroundColor(MaterialColors.onBackground)
                
                Spacer()
                
                // History Button (Material Chip)
                Button(action: onHistoryClick) {
                    HStack(spacing: 6) {
                        Text("History")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MaterialColors.onSurface)
                        
                        let historyIconName = isLightTheme ? "history" : "history_dark"
                        Image(historyIconName)
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                }
                .buttonStyle(.materialChip)
            }
            
            // Calendar Days
            HStack(spacing: MaterialSpacing.xs) {
                ForEach(weeklyCalendar, id: \.date) { day in
                    DayColumn(
                        day: day,
                        isToday: Calendar.current.isDateInToday(day.date)
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, MaterialSpacing.screenHorizontal)
        .padding(.vertical, MaterialSpacing.lg)
        .background(MaterialColors.background)
    }
}

// MARK: - DayColumn
struct DayColumn: View {
    let day: WeeklyCalendarDay
    let isToday: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isLightTheme: Bool {
        colorScheme == .light
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: day.date)
    }
    
    private var ringColor: Color {
        if let colorHex = day.colorHex {
            return Color(hex: colorHex) ?? (isLightTheme ? .gray : .gray)
        } else {
            return isLightTheme ? .gray : Color(.lightGray)
        }
    }
    
    private var fillColor: Color {
        if let colorHex = day.colorHex {
            let baseColor = Color(hex: colorHex) ?? .clear
            return baseColor.opacity(isLightTheme ? 0.35 : 0.45)
        } else if isToday {
            return isLightTheme ? Color.gray.opacity(0.10) : Color.white.opacity(0.20)
        } else {
            return .clear
        }
    }
    
    private var textColor: Color {
        if isToday {
            return .primary
        } else if day.colorHex != nil {
            return isLightTheme ? .black : .white
        } else {
            return .secondary
        }
    }
    
    private var textWeight: Font.Weight {
        if isToday {
            return .bold
        } else if day.colorHex != nil {
            return .semibold
        } else {
            return .regular
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Day of week label
            Text(dayFormatter.string(from: day.date).uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Day circle
            ZStack {
                Circle()
                    .fill(fillColor)
                    .overlay(
                        Circle()
                            .stroke(ringColor, lineWidth: 1.5)
                    )
                
                Text(dayNumber)
                    .font(.body)
                    .fontWeight(textWeight)
                    .foregroundColor(textColor)
            }
            .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 4)
    }
}