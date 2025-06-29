//
//  WorkoutState.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation

enum WorkoutState: Equatable {
    case initial
    case loading
    case idle
    case success([Workout])
    case error(String)
}