import Foundation

enum Screen: String, CaseIterable {
    case auth = "auth"
    case home = "home"
    case activeWorkout = "active_workout"
    case workout = "workout"
    case createRoutine = "create_routine"
    case exerciseSearch = "exercise_search"
    case settings = "settings"
    case profile = "profile"
    case subscription = "subscription"
    case createExercise = "create_exercise"
    case history = "history"
    case workoutDetail = "workout_detail"
    case counter = "counter"
    case routinePreview = "routine_preview"
    
    var route: String {
        return rawValue
    }
    
    // MARK: - ExerciseSearch helpers
    func withSource(_ source: String) -> String {
        guard self == .exerciseSearch else { return route }
        return "\(route)?from=\(source)"
    }
    
    func withReplacement() -> String {
        guard self == .exerciseSearch else { return route }
        return "\(route)?replacement=true"
    }
    
    func withSourceAndReplacement(_ source: String) -> String {
        guard self == .exerciseSearch else { return route }
        return "\(route)?from=\(source)&replacement=true"
    }
    
    // MARK: - WorkoutDetail helpers
    func withWorkoutId(_ workoutId: String) -> String {
        guard self == .workoutDetail else { return route }
        return "\(route)/\(workoutId)"
    }
    
    // MARK: - Routine helpers
    func withRoutineId(_ routineId: String) -> String {
        switch self {
        case .activeWorkout, .workout:
            return "\(route)?routineId=\(routineId)"
        case .createRoutine:
            return "\(route)?routineId=\(routineId)"
        case .routinePreview:
            return "\(route)/\(routineId)"
        default:
            return route
        }
    }
    
    func withRoutine(routineId: String, routineName: String) -> String {
        let encodedName = routineName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? routineName
        switch self {
        case .activeWorkout, .workout:
            return "\(route)?routineId=\(routineId)&routineName=\(encodedName)"
        default:
            return route
        }
    }
}