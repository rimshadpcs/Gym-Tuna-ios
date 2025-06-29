//
//  ExerciseRepository.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 29/06/2025.
//

import Foundation
import Combine

protocol ExerciseRepository {
    func getAllExercises() -> AnyPublisher<[Exercise], Error>
    func getExercisesByMuscleGroup(_ muscleGroup: String) -> AnyPublisher<[Exercise], Error>
    func searchExercises(_ query: String) -> AnyPublisher<[Exercise], Error>
    func getExerciseById(_ id: String) -> AnyPublisher<Exercise?, Error>
    func addCustomExercise(_ exercise: Exercise) -> AnyPublisher<Void, Error>
    func updateExercise(_ exercise: Exercise) -> AnyPublisher<Void, Error>
    func deleteExercise(_ exerciseId: String) -> AnyPublisher<Void, Error>
}