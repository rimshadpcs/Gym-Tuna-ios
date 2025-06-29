//
//  QuickActionsSection.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI
import Foundation

struct QuickActionsSection: View {
    let onStartEmptyWorkout: () -> Void
    let onNewRoutine: () -> Void
    let onNavigateToCounter: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkTheme: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        VStack(spacing: MaterialSpacing.lg) {
            // Title and Counter button
            HStack {
                Text("Quick Actions")
                    .font(MaterialTypography.headline6)
                    .foregroundColor(MaterialColors.onBackground)
                
                Spacer()
                
                // Counter Button (Material Chip Style)
                Button(action: onNavigateToCounter) {
                    HStack(spacing: 6) {
                        Text("Custom counter")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MaterialColors.onSurface)
                        
                        let counterIconName = isDarkTheme ? "counter_dark" : "counter"
                        Image(counterIconName)
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                }
                .buttonStyle(.materialChip)
            }
            .padding(.horizontal, MaterialSpacing.screenHorizontal)
            
            // Quick Action Buttons (Android Compact Style)
            HStack(spacing: MaterialSpacing.sm) {
                // Quick Start Button
                Button(action: onStartEmptyWorkout) {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(MaterialColors.onSurface)
                        
                        Text("Quick Start")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MaterialColors.onSurface)
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.materialOutlined(height: 56))
                
                // New Routine Button  
                Button(action: onNewRoutine) {
                    VStack(spacing: 6) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(MaterialColors.onSurface)
                        
                        Text("New Routine")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MaterialColors.onSurface)
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.materialOutlined(height: 56))
            }
            .padding(.horizontal, MaterialSpacing.screenHorizontal)
        }
        .padding(.vertical, MaterialSpacing.sm)
    }
}