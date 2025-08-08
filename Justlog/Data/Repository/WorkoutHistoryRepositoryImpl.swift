import Foundation
import Combine

class WorkoutHistoryRepositoryImpl: WorkoutHistoryRepository {
    
    // MARK: - Mock Implementation
    // TODO: Replace with actual Firebase implementation
    
    private var workoutHistory: [WorkoutHistory] = []
    private let historySubject = CurrentValueSubject<[WorkoutHistory], Error>([])
    
    init() {
        setupMockData()
    }
    
    private func setupMockData() {
        let calendar = Calendar.current
        let now = Date()
        
        // Create mock workout data
        let mockWorkouts = [
            WorkoutHistory(
                name: "All eggs",
                startTime: calendar.date(byAdding: .day, value: -20, to: now)!,
                endTime: calendar.date(byAdding: .day, value: -20, to: now)!.addingTimeInterval(1800),
                exercises: [
                    CompletedExercise(
                        exerciseId: "ex1",
                        name: "Squats",
                        muscleGroup: "Legs",
                        equipment: "Barbell",
                        sets: [
                            CompletedSet(setNumber: 1, weight: 60.0, reps: 12),
                            CompletedSet(setNumber: 2, weight: 65.0, reps: 10),
                            CompletedSet(setNumber: 3, weight: 70.0, reps: 8)
                        ]
                    )
                ],
                totalVolume: 195.0,
                totalSets: 3,
                colorHex: "#4CAF50",
                routineId: "routine_1",
                userId: "user1",
                exerciseIds: ["ex1"]
            ),
            WorkoutHistory(
                name: "Test 1",
                startTime: calendar.date(byAdding: .day, value: -20, to: now)!,
                endTime: calendar.date(byAdding: .day, value: -20, to: now)!.addingTimeInterval(2400),
                exercises: [
                    CompletedExercise(
                        exerciseId: "ex2",
                        name: "Bench Press",
                        muscleGroup: "Chest",
                        equipment: "Barbell",
                        sets: [
                            CompletedSet(setNumber: 1, weight: 80.0, reps: 10),
                            CompletedSet(setNumber: 2, weight: 85.0, reps: 8),
                            CompletedSet(setNumber: 3, weight: 90.0, reps: 6)
                        ]
                    ),
                    CompletedExercise(
                        exerciseId: "ex1",
                        name: "Squats",
                        muscleGroup: "Legs",
                        equipment: "Barbell",
                        sets: [
                            CompletedSet(setNumber: 1, weight: 100.0, reps: 10),
                            CompletedSet(setNumber: 2, weight: 105.0, reps: 8)
                        ]
                    ),
                    CompletedExercise(
                        exerciseId: "ex3",
                        name: "Pull-ups",
                        muscleGroup: "Back",
                        equipment: "Pull-up Bar",
                        sets: [
                            CompletedSet(setNumber: 1, weight: 0.0, reps: 12),
                            CompletedSet(setNumber: 2, weight: 0.0, reps: 10)
                        ]
                    ),
                    CompletedExercise(
                        exerciseId: "ex4",
                        name: "Push-ups",
                        muscleGroup: "Chest",
                        equipment: "Bodyweight",
                        sets: [
                            CompletedSet(setNumber: 1, weight: 0.0, reps: 20),
                            CompletedSet(setNumber: 2, weight: 0.0, reps: 18)
                        ]
                    )
                ],
                totalVolume: 1510.0,
                totalSets: 9,
                colorHex: "#2196F3",
                routineId: "routine_2",
                userId: "user1",
                exerciseIds: ["ex2", "ex1", "ex3", "ex4"]
            ),
            WorkoutHistory(
                name: "Testw",
                startTime: calendar.date(byAdding: .day, value: -20, to: now)!,
                endTime: calendar.date(byAdding: .day, value: -20, to: now)!.addingTimeInterval(1200),
                exercises: [
                    CompletedExercise(
                        exerciseId: "ex5",
                        name: "Deadlifts",
                        muscleGroup: "Back",
                        equipment: "Barbell",
                        sets: [
                            CompletedSet(setNumber: 1, weight: 120.0, reps: 5),
                            CompletedSet(setNumber: 2, weight: 125.0, reps: 4)
                        ]
                    ),
                    CompletedExercise(
                        exerciseId: "ex6",
                        name: "Rows",
                        muscleGroup: "Back",
                        equipment: "Barbell",
                        sets: [
                            CompletedSet(setNumber: 1, weight: 70.0, reps: 12),
                            CompletedSet(setNumber: 2, weight: 75.0, reps: 10)
                        ]
                    )
                ],
                totalVolume: 1950.0,
                totalSets: 4,
                colorHex: "#F44336",
                routineId: "routine_3",
                userId: "user1",
                exerciseIds: ["ex5", "ex6"]
            )
        ]
        
        // Duplicate some workouts with different dates to show multiple entries
        var allWorkouts: [WorkoutHistory] = []
        for i in 0..<5 {
            for workout in mockWorkouts {
                let offsetDays = -i * 2
                let newStartTime = calendar.date(byAdding: .day, value: offsetDays, to: now)!
                let duration = workout.endTime.timeIntervalSince(workout.startTime)
                let newEndTime = newStartTime.addingTimeInterval(duration)
                
                let newWorkout = WorkoutHistory(
                    id: "\(workout.id)_\(i)",
                    name: workout.name,
                    startTime: newStartTime,
                    endTime: newEndTime,
                    exercises: workout.exercises,
                    totalVolume: workout.totalVolume,
                    totalSets: workout.totalSets,
                    colorHex: workout.colorHex,
                    routineId: workout.routineId,
                    userId: workout.userId,
                    exerciseIds: workout.exerciseIds
                )
                allWorkouts.append(newWorkout)
            }
        }
        
        workoutHistory = allWorkouts
        historySubject.send(workoutHistory)
    }
    
    func saveWorkoutHistory(_ workoutHistory: WorkoutHistory) async throws {
        self.workoutHistory.append(workoutHistory)
        historySubject.send(self.workoutHistory)
    }
    
    func getWorkoutHistory(userId: String) -> AnyPublisher<[WorkoutHistory], Error> {
        return historySubject.eraseToAnyPublisher()
    }
    
    func getMonthlyHistory(userId: String, monthStart: Date, timeZone: TimeZone) -> AnyPublisher<[WorkoutHistory], Error> {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
        
        let filteredWorkouts = workoutHistory.filter { workout in
            workout.startTime >= monthStart && workout.startTime < monthEnd
        }
        
        return Just(filteredWorkouts)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func updateRoutineNameInHistory(userId: String, routineId: String, newName: String) async throws {
        for i in 0..<workoutHistory.count {
            if workoutHistory[i].routineId == routineId {
                workoutHistory[i] = WorkoutHistory(
                    id: workoutHistory[i].id,
                    name: newName,
                    startTime: workoutHistory[i].startTime,
                    endTime: workoutHistory[i].endTime,  
                    exercises: workoutHistory[i].exercises,
                    totalVolume: workoutHistory[i].totalVolume,
                    totalSets: workoutHistory[i].totalSets,
                    colorHex: workoutHistory[i].colorHex,
                    routineId: workoutHistory[i].routineId,
                    userId: workoutHistory[i].userId,
                    exerciseIds: workoutHistory[i].exerciseIds
                )
            }
        }
        historySubject.send(workoutHistory)
    }
}