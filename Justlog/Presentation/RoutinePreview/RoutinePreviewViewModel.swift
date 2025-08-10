import Foundation
import Combine

@MainActor
class RoutinePreviewViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var routine: Workout? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    private let workoutRepository: WorkoutRepository
    private var cancellables = Set<AnyCancellable>()
    private let logger = "RoutinePreviewViewModel"
    
    // MARK: - Initialization
    init(workoutRepository: WorkoutRepository) {
        self.workoutRepository = workoutRepository
    }
    
    // MARK: - Public Methods
    func loadRoutine(_ routineId: String) {
        Task {
            await loadRoutineAsync(routineId)
        }
    }
    
    // MARK: - Private Methods
    private func loadRoutineAsync(_ routineId: String) async {
        do {
            isLoading = true
            errorMessage = nil
            print("\(logger): Loading routine with ID: \(routineId)")
            
            let workout = try await workoutRepository.getWorkoutById(routineId)
            routine = workout
            
            if let workout = workout {
                print("\(logger): Loaded routine: \(workout.name) with \(workout.exercises.count) exercises")
            } else {
                print("\(logger): Routine not found for ID: \(routineId)")
                errorMessage = "Routine not found"
            }
            
        } catch {
            print("\(logger): Error loading routine: \(error)")
            routine = nil
            errorMessage = "Failed to load routine: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}