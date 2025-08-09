//
//  RestTimerButton.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import SwiftUI

struct RestTimerButton: View {
    @Environment(\.themeManager) private var themeManager
    
    let isRunning: Bool
    let remainingTime: Int
    let totalTime: Int
    let isPaused: Bool
    let onStart: (Int) -> Void
    let onStop: () -> Void
    let onPauseResume: () -> Void
    
    @State private var showTimerSheet = false
    
    private let presetTimes = [30, 60, 90, 120, 180, 300] // 30s to 5min
    
    private var isDarkTheme: Bool {
        switch themeManager?.currentTheme {
        case .dark:
            return true
        case .neutral, .light, .none:
            return false
        }
    }
    
    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - remainingTime) / Double(totalTime)
    }
    
    private var formattedTime: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if isRunning || isPaused {
                // Active timer display
                activeTimerView
            } else {
                // Start timer button
                startTimerButton
            }
        }
    }
    
    private var startTimerButton: some View {
        Button(action: {
            showTimerSheet = true
        }) {
            HStack(spacing: 8) {
                Image(isDarkTheme ? "timer_dark" : "timer")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                
                Text("Rest Timer")
                    .vagFont(size: 14, weight: .medium)
            }
            .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(themeManager?.colors.primary ?? LightThemeColors.primary, lineWidth: 1.5)
                    .fill(Color.clear)
            )
        }
        .sheet(isPresented: $showTimerSheet) {
            RestTimerSelectionSheet(
                presetTimes: presetTimes,
                onTimeSelected: { duration in
                    onStart(duration)
                    showTimerSheet = false
                }
            )
        }
    }
    
    private var activeTimerView: some View {
        VStack(spacing: 8) {
            // Timer display with controls
            HStack(spacing: 12) {
                // Timer icon and time
                HStack(spacing: 6) {
                    Image(isDarkTheme ? "timer_dark" : "timer")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                    
                    Text(formattedTime)
                        .vagFont(size: 16, weight: .bold)
                        .foregroundColor(
                            isPaused ? 
                            (themeManager?.colors.onSurface ?? LightThemeColors.onSurface) :
                            (themeManager?.colors.primary ?? LightThemeColors.primary)
                        )
                    
                    if isPaused {
                        Text("(Paused)")
                            .vagFont(size: 12, weight: .medium)
                            .foregroundColor(themeManager?.colors.onSurface.opacity(0.6) ?? LightThemeColors.onSurface.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 8) {
                    Button(action: onPauseResume) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    }
                    .padding(6)
                    .background(
                        Circle()
                            .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                            .overlay(
                                Circle()
                                    .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                            )
                    )
                    
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .padding(6)
                    .background(
                        Circle()
                            .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                            .overlay(
                                Circle()
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                    )
            )
            
            // Progress bar
            if !isPaused {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager?.colors.primary ?? LightThemeColors.primary))
                    .scaleEffect(x: 1, y: 0.8)
            }
        }
    }
}

struct RestTimerSelectionSheet: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    
    let presetTimes: [Int]
    let onTimeSelected: (Int) -> Void
    
    @State private var customTime = 60
    @State private var showCustomInput = false
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return remainingSeconds == 0 ? "\(minutes)m" : "\(minutes)m \(remainingSeconds)s"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("Rest Timer")
                    .vagFont(size: 20, weight: .semibold)
                    .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                    .padding(.top, 20)
                
                // Preset times
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(presetTimes, id: \.self) { time in
                        Button(action: {
                            onTimeSelected(time)
                        }) {
                            Text(formatTime(time))
                                .vagFont(size: 16, weight: .semibold)
                                .foregroundColor(themeManager?.colors.onPrimary ?? LightThemeColors.onPrimary)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                
                
                Spacer()
            }
            .background(themeManager?.colors.background ?? LightThemeColors.background)
            .navigationBarHidden(true)
            .overlay(
                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                                .overlay(
                                    Circle()
                                        .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                                )
                        )
                }
                .padding(.top, 20)
                .padding(.trailing, 20),
                alignment: .topTrailing
            )
        }
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
    }
}