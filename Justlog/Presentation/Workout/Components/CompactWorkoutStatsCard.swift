//
//  CompactWorkoutStatsCard.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import SwiftUI

struct CompactWorkoutStatsCard: View {
    @Environment(\.themeManager) private var themeManager
    
    let duration: String
    let volume: String
    let sets: Int
    let isActive: Bool
    
    private var isDarkTheme: Bool {
        switch themeManager?.currentTheme {
        case .dark:
            return true
        case .neutral, .light, .none:
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Duration section
                HStack(spacing: 6) {
                    Image(isDarkTheme ? "timer_dark" : "timer")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(duration)
                            .vagFont(size: 16, weight: .bold)
                            .foregroundColor(
                                isActive ? 
                                (themeManager?.colors.primary ?? LightThemeColors.primary) :
                                (themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                            )
                        
                        Text("Duration")
                            .vagFont(size: 10, weight: .medium)
                            .foregroundColor(themeManager?.colors.onSurface.opacity(0.6) ?? LightThemeColors.onSurface.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Vertical divider
                Rectangle()
                    .fill(themeManager?.colors.outline.opacity(0.2) ?? LightThemeColors.outline.opacity(0.2))
                    .frame(width: 1, height: 32)
                
                // Volume section
                VStack(spacing: 2) {
                    Text(volume)
                        .vagFont(size: 16, weight: .bold)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    
                    Text("Volume")
                        .vagFont(size: 10, weight: .medium)
                        .foregroundColor(themeManager?.colors.onSurface.opacity(0.6) ?? LightThemeColors.onSurface.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                
                // Vertical divider
                Rectangle()
                    .fill(themeManager?.colors.outline.opacity(0.2) ?? LightThemeColors.outline.opacity(0.2))
                    .frame(width: 1, height: 32)
                
                // Sets section
                VStack(spacing: 2) {
                    Text(String(sets))
                        .vagFont(size: 16, weight: .bold)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    
                    Text("Sets")
                        .vagFont(size: 10, weight: .medium)
                        .foregroundColor(themeManager?.colors.onSurface.opacity(0.6) ?? LightThemeColors.onSurface.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(12)
        }
        .materialCard()
        .overlay(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .stroke(
                    isActive ? 
                    (themeManager?.colors.primary.opacity(0.3) ?? LightThemeColors.primary.opacity(0.3)) :
                    (themeManager?.colors.outline.opacity(0.5) ?? LightThemeColors.outline.opacity(0.5)),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, MaterialSpacing.lg)
        .padding(.vertical, 4)
    }
}

struct UltraCompactWorkoutStatsCard: View {
    @Environment(\.themeManager) private var themeManager
    
    let duration: String
    let volume: String
    let sets: Int
    let isActive: Bool
    
    private var isDarkTheme: Bool {
        switch themeManager?.currentTheme {
        case .dark:
            return true
        case .neutral, .light, .none:
            return false
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Duration with timer icon
            HStack(spacing: 4) {
                Image(isDarkTheme ? "timer_dark" : "timer")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                
                Text(duration)
                    .vagFont(size: 14, weight: .bold)
                    .foregroundColor(
                        isActive ? 
                        (themeManager?.colors.primary ?? LightThemeColors.primary) :
                        (themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    )
            }
            
            // Volume
            Text(volume)
                .vagFont(size: 14, weight: .bold)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            
            // Sets
            Text("\(sets) sets")
                .vagFont(size: 14, weight: .bold)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            
            Spacer()
        }
        .padding(8)
        .materialCard()
        .overlay(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.small)
                .stroke(
                    isActive ? 
                    (themeManager?.colors.primary.opacity(0.3) ?? LightThemeColors.primary.opacity(0.3)) :
                    (themeManager?.colors.outline.opacity(0.5) ?? LightThemeColors.outline.opacity(0.5)),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, MaterialSpacing.lg)
        .padding(.vertical, 2)
    }
}