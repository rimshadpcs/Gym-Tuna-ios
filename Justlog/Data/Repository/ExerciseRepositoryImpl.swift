//
//  ExerciseRepositoryImpl.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 29/06/2025.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

class ExerciseRepositoryImpl: ExerciseRepository {
    private let db = Firestore.firestore()
    private let exercisesCollection = "exercises"
    private let userExercisesCollection = "user_exercises"
    
    func getAllExercises() -> AnyPublisher<[Exercise], Error> {
        // Try to get exercises from Firestore, fallback to sample data if there's an error
        return getFirestoreExercises()
            .catch { [weak self] error in
                print("❌ Firestore error: \(error.localizedDescription)")
                print("🔄 Falling back to sample exercises")
                return self?.getDefaultExercises() ?? Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getExercisesByMuscleGroup(_ muscleGroup: String) -> AnyPublisher<[Exercise], Error> {
        return getAllExercises()
            .map { exercises in
                exercises.filter { $0.muscleGroup.localizedCaseInsensitiveContains(muscleGroup) }
            }
            .eraseToAnyPublisher()
    }
    
    func searchExercises(_ query: String) -> AnyPublisher<[Exercise], Error> {
        return getAllExercises()
            .map { exercises in
                exercises.filter { exercise in
                    exercise.name.localizedCaseInsensitiveContains(query) ||
                    exercise.muscleGroup.localizedCaseInsensitiveContains(query) ||
                    exercise.equipment.localizedCaseInsensitiveContains(query) ||
                    exercise.description.localizedCaseInsensitiveContains(query)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getExerciseById(_ id: String) -> AnyPublisher<Exercise?, Error> {
        return getAllExercises()
            .map { exercises in
                exercises.first { $0.id == id }
            }
            .eraseToAnyPublisher()
    }
    
    func addCustomExercise(_ exercise: Exercise) -> AnyPublisher<Void, Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Fail(error: RepositoryError.userNotAuthenticated)
                .eraseToAnyPublisher()
        }
        
        return Future<Void, Error> { [weak self] promise in
            self?.db.collection(self?.userExercisesCollection ?? "")
                .document(userId)
                .collection("exercises")
                .document(exercise.id)
                .setData(exercise.toFirestoreData()) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    func updateExercise(_ exercise: Exercise) -> AnyPublisher<Void, Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Fail(error: RepositoryError.userNotAuthenticated)
                .eraseToAnyPublisher()
        }
        
        return Future<Void, Error> { [weak self] promise in
            self?.db.collection(self?.userExercisesCollection ?? "")
                .document(userId)
                .collection("exercises")
                .document(exercise.id)
                .updateData(exercise.toFirestoreData()) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteExercise(_ exerciseId: String) -> AnyPublisher<Void, Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Fail(error: RepositoryError.userNotAuthenticated)
                .eraseToAnyPublisher()
        }
        
        return Future<Void, Error> { [weak self] promise in
            self?.db.collection(self?.userExercisesCollection ?? "")
                .document(userId)
                .collection("exercises")
                .document(exerciseId)
                .delete() { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func getFirestoreExercises() -> AnyPublisher<[Exercise], Error> {
        print("🔍 Attempting to load exercises from Firestore...")
        
        return Future<[Exercise], Error> { [weak self] promise in
            self?.db.collection(self?.exercisesCollection ?? "exercises")
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("❌ Firestore exercises error: \(error)")
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("📭 No exercise documents found in Firestore")
                        promise(.success([]))
                        return
                    }
                    
                    print("📦 Found \(documents.count) exercise documents in Firestore")
                    
                    let exercises = documents.compactMap { document in
                        let data = document.data()
                        return Exercise.fromFirestoreData(data)
                    }
                    
                    print("✅ Successfully parsed \(exercises.count) exercises from Firestore")
                    promise(.success(exercises))
                }
        }
        .eraseToAnyPublisher()
    }
    
    private func getDefaultExercises() -> AnyPublisher<[Exercise], Error> {
        // For now, return sample exercises. In production, this would fetch from a default exercises collection
        let exercises = Exercise.sampleExercises + Exercise.extendedSampleExercises
        print("🏋️ Loading \(exercises.count) default exercises")
        
        return Just(exercises)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func getUserCustomExercises() -> AnyPublisher<[Exercise], Error> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return Future<[Exercise], Error> { [weak self] promise in
            self?.db.collection(self?.userExercisesCollection ?? "")
                .document(userId)
                .collection("exercises")
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    let exercises = snapshot?.documents.compactMap { document in
                        Exercise.fromFirestoreData(document.data())
                    } ?? []
                    
                    promise(.success(exercises))
                }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Extended Sample Exercises
extension Exercise {
    static let extendedSampleExercises: [Exercise] = [
        // Chest Exercises
        Exercise(
            name: "Incline Dumbbell Press",
            primaryMuscles: ["chest"],
            equipment: "Dumbbells",
            description: "Upper chest development with dumbbells on incline bench"
        ),
        Exercise(
            name: "Chest Dips",
            primaryMuscles: ["chest"],
            equipment: "Dip Bars",
            description: "Compound exercise targeting lower chest and triceps"
        ),
        Exercise(
            name: "Cable Chest Fly",
            primaryMuscles: ["chest"],
            equipment: "Cable Machine",
            description: "Isolation exercise for chest muscle definition"
        ),
        
        // Back Exercises
        Exercise(
            name: "Lat Pulldown",
            primaryMuscles: ["back"],
            equipment: "Cable Machine",
            description: "Vertical pulling exercise for latissimus dorsi"
        ),
        Exercise(
            name: "Seated Cable Row",
            muscleGroup: "Back",
            equipment: "Cable Machine",
            description: "Horizontal pulling for middle back development"
        ),
        Exercise(
            name: "T-Bar Row",
            muscleGroup: "Back",
            equipment: "T-Bar",
            description: "Compound rowing movement for back thickness"
        ),
        
        // Shoulder Exercises
        Exercise(
            name: "Overhead Press",
            muscleGroup: "Shoulders",
            equipment: "Barbell",
            description: "Compound movement for overall shoulder development"
        ),
        Exercise(
            name: "Lateral Raises",
            muscleGroup: "Shoulders",
            equipment: "Dumbbells",
            description: "Isolation exercise for side deltoids"
        ),
        Exercise(
            name: "Rear Delt Fly",
            muscleGroup: "Shoulders",
            equipment: "Dumbbells",
            description: "Targets rear deltoids and upper back"
        ),
        
        // Arms Exercises
        Exercise(
            name: "Barbell Curls",
            muscleGroup: "Arms",
            equipment: "Barbell",
            description: "Classic bicep building exercise"
        ),
        Exercise(
            name: "Tricep Dips",
            muscleGroup: "Arms",
            equipment: "Bench",
            description: "Bodyweight exercise for tricep development"
        ),
        Exercise(
            name: "Hammer Curls",
            muscleGroup: "Arms",
            equipment: "Dumbbells",
            description: "Targets biceps and forearms with neutral grip"
        ),
        
        // Leg Exercises
        Exercise(
            name: "Romanian Deadlift",
            muscleGroup: "Legs",
            equipment: "Barbell",
            description: "Hip hinge movement targeting hamstrings and glutes"
        ),
        Exercise(
            name: "Bulgarian Split Squats",
            muscleGroup: "Legs",
            equipment: "Dumbbells",
            description: "Unilateral leg exercise for balance and strength"
        ),
        Exercise(
            name: "Calf Raises",
            muscleGroup: "Legs",
            equipment: "Dumbbells",
            description: "Isolation exercise for calf muscle development"
        ),
        
        // Core/Abs Exercises
        Exercise(
            name: "Plank",
            muscleGroup: "Abs",
            equipment: "Body Weight",
            isBodyweight: true,
            usesWeight: false,
            isTimeBased: true,
            description: "Isometric core exercise for stability"
        ),
        Exercise(
            name: "Russian Twists",
            muscleGroup: "Abs",
            equipment: "Body Weight",
            isBodyweight: true,
            usesWeight: false,
            description: "Rotational movement for obliques"
        ),
        Exercise(
            name: "Hanging Leg Raises",
            muscleGroup: "Abs",
            equipment: "Pull-up Bar",
            isBodyweight: true,
            usesWeight: false,
            description: "Advanced core exercise targeting lower abs"
        ),
        
        // Cardio Exercises
        Exercise(
            name: "Burpees",
            muscleGroup: "Cardio",
            equipment: "Body Weight",
            isBodyweight: true,
            usesWeight: false,
            isTimeBased: true,
            description: "Full body high-intensity exercise"
        ),
        Exercise(
            name: "Mountain Climbers",
            muscleGroup: "Cardio",
            equipment: "Body Weight",
            isBodyweight: true,
            usesWeight: false,
            isTimeBased: true,
            description: "Dynamic cardio exercise with core engagement"
        ),
        Exercise(
            name: "Jumping Jacks",
            muscleGroup: "Cardio",
            equipment: "Body Weight",
            isBodyweight: true,
            usesWeight: false,
            isTimeBased: true,
            description: "Classic cardio exercise for warm-up or conditioning"
        )
    ]
}