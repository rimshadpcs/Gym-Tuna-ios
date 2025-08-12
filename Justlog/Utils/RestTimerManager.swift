//
//  RestTimerManager.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
class RestTimerManager: ObservableObject {
    
    @Published var timerState: RestTimerState = .inactive
    
    // Computed properties for API compatibility
    var isRunning: Bool {
        switch timerState {
        case .active: return true
        default: return false
        }
    }
    
    var isPaused: Bool {
        switch timerState {
        case .paused: return true
        default: return false
        }
    }
    
    var totalTime: TimeInterval {
        switch timerState {
        case .active(_, let total), .paused(_, let total):
            return total
        default:
            return 0
        }
    }
    
    private var timer: Timer?
    private var totalDuration: TimeInterval = 0
    var remainingTime: TimeInterval = 0 // Made public for access
    
    func startTimer(duration: TimeInterval) {
        stopTimer()
        
        totalDuration = duration
        remainingTime = duration
        timerState = .active(remaining: remainingTime, total: totalDuration)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.tick()
            }
        }
    }
    
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .paused(remaining: remainingTime, total: totalDuration)
    }
    
    func resumeTimer() {
        guard case .paused = timerState else { return }
        
        timerState = .active(remaining: remainingTime, total: totalDuration)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.tick()
            }
        }
    }
    
    func resetTimer() {
        stopTimer()
        timerState = .inactive
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .inactive
    }
    
    func pauseResumeTimer() {
        switch timerState {
        case .active:
            pauseTimer()
        case .paused:
            resumeTimer()
        default:
            break
        }
    }
    
    private func tick() {
        remainingTime -= 1
        
        if remainingTime <= 0 {
            stopTimer()
            timerState = .completed
        } else {
            // Add haptic feedback for the last 3 seconds
            if remainingTime <= 3 && remainingTime > 0 {
                let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
                hapticFeedback.impactOccurred()
                print("🔸 Rest timer haptic feedback: \(Int(remainingTime)) seconds remaining")
            }
            
            timerState = .active(remaining: remainingTime, total: totalDuration)
        }
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Rest Timer State
enum RestTimerState {
    case inactive
    case active(remaining: TimeInterval, total: TimeInterval)
    case paused(remaining: TimeInterval, total: TimeInterval)
    case completed
}