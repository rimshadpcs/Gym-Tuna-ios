//
//  ExerciseSearchViewModel.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 29/06/2025.
//

import Foundation
import Combine

@MainActor
class ExerciseSearchViewModel: ObservableObject {
    @Published private(set) var exerciseState: ExerciseState = .initial
    @Published private(set) var filteredExercises: [Exercise] = []
    
    private let exerciseRepository: ExerciseRepository
    private var allExercises: [Exercise] = []
    private var cancellables = Set<AnyCancellable>()
    
    // Search state
    private var searchQuery: String = ""
    
    init(exerciseRepository: ExerciseRepository) {
        self.exerciseRepository = exerciseRepository
    }
    
    func loadExercises() {
        print("🔍 ExerciseSearchViewModel: Starting to load exercises")
        exerciseState = .loading
        
        exerciseRepository.getAllExercises()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        print("❌ ExerciseSearchViewModel: Failed to load exercises: \(error)")
                        self?.exerciseState = .error(error.localizedDescription)
                    case .finished:
                        print("✅ ExerciseSearchViewModel: Finished loading exercises")
                        break
                    }
                },
                receiveValue: { [weak self] exercises in
                    print("📦 ExerciseSearchViewModel: Received \(exercises.count) exercises")
                    self?.allExercises = exercises
                    self?.applyFilters()
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshExercises() {
        print("🔄 ExerciseSearchViewModel: Refreshing exercises from cache")
        exerciseState = .loading
        
        exerciseRepository.refreshExerciseCache()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        print("❌ ExerciseSearchViewModel: Failed to refresh exercises: \(error)")
                        self?.exerciseState = .error(error.localizedDescription)
                    case .finished:
                        print("✅ ExerciseSearchViewModel: Finished refreshing exercises")
                        break
                    }
                },
                receiveValue: { [weak self] exercises in
                    print("📦 ExerciseSearchViewModel: Refreshed \(exercises.count) exercises")
                    self?.allExercises = exercises
                    self?.applyFilters()
                }
            )
            .store(in: &cancellables)
    }
    
    func updateSearchQuery(_ query: String) {
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        applyFilters()
    }
    
    
    private func applyFilters() {
        print("🔧 ExerciseSearchViewModel: Applying filters to \(allExercises.count) exercises")
        var filtered = allExercises
        
        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchQuery) ||
                exercise.muscleGroup.localizedCaseInsensitiveContains(searchQuery) ||
                exercise.equipment.localizedCaseInsensitiveContains(searchQuery) ||
                exercise.description.localizedCaseInsensitiveContains(searchQuery)
            }
            print("🔍 ExerciseSearchViewModel: After search filter: \(filtered.count) exercises")
        }
        
        
        // Sort exercises alphabetically
        filtered.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        filteredExercises = filtered
        exerciseState = .success(filtered)
        print("✅ ExerciseSearchViewModel: Final filtered count: \(filtered.count) exercises")
    }
}

// MARK: - Exercise State
enum ExerciseState: Equatable {
    case initial
    case idle
    case loading
    case success([Exercise])
    case error(String)
    
    static func == (lhs: ExerciseState, rhs: ExerciseState) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial), (.idle, .idle), (.loading, .loading):
            return true
        case (.success(let lhsExercises), .success(let rhsExercises)):
            return lhsExercises == rhsExercises
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}