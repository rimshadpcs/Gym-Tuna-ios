//
//  BottomWorkoutBanner.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI
import Foundation

struct BottomWorkoutBanner: View {
    @ObservedObject var workoutSessionManager: WorkoutSessionManager
    let onResumeClick: () -> Void
    let onDiscardClick: () -> Void
    
    var body: some View {
        if let workoutState = workoutSessionManager.getWorkoutState() {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workoutState.routineName)
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(workoutSessionManager.getCurrentDuration())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Discard", action: onDiscardClick)
                        .buttonStyle(.bordered)
                    
                    Button("Resume", action: onResumeClick)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.systemGray4)),
                alignment: .top
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        }
    }
}