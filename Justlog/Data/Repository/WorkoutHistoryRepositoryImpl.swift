//
//  WorkoutHistoryRepositoryImpl.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import Foundation
import Combine
import FirebaseFirestore

class WorkoutHistoryRepositoryImpl: WorkoutHistoryRepository {
    
    private let firestore = Firestore.firestore()
    private let calendar = Calendar.current
    
    private static let tag = "WorkoutHistoryRepo"
    
    // MARK: - Public Methods
    
    func saveWorkoutHistory(_ workoutHistory: WorkoutHistory) async throws {
        do {
            let userId = workoutHistory.userId
            let workoutId = workoutHistory.id
            
            print("[\(Self.tag)] Attempting to save workout history")
            print("[\(Self.tag)] User ID: \(userId)")
            print("[\(Self.tag)] Workout ID: \(workoutId)")
            
            let workoutData = workoutHistory.toFirestoreData()
            
            // Write to: workout_history/{uid}/workouts/{workoutId}
            try await firestore
                .collection("workout_history")
                .document(userId)
                .collection("workouts")
                .document(workoutId)
                .setData(workoutData)
            
            print("[\(Self.tag)] Successfully saved workout history")
            
        } catch {
            print("[\(Self.tag)] Error saving workout history: \(error)")
            print("[\(Self.tag)] Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getWorkoutHistory(userId: String) -> AnyPublisher<[WorkoutHistory], Error> {
        return Publishers.SnapshotListener(
            query: firestore
                .collection("workout_history")
                .document(userId)
                .collection("workouts")
                .order(by: "startTime", descending: true)
        )
        .map { snapshot in
            return snapshot.documents.compactMap { document in
                WorkoutHistory.fromFirestoreData(document.data())
            }
        }
        .handleEvents(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("[\(Self.tag)] Error getting workout history: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    func getMonthlyHistory(
        userId: String,
        monthStart: Date,
        timeZone: TimeZone = TimeZone.current
    ) -> AnyPublisher<[WorkoutHistory], Error> {
        
        // Calculate start and end timestamps for the month
        let startOfMonth = calendar.dateInterval(of: .month, for: monthStart)?.start ?? monthStart
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? Date()
        
        let startMs = startOfMonth.timeIntervalSince1970 * 1000 // Convert to milliseconds
        let endMs = endOfMonth.timeIntervalSince1970 * 1000
        
        return Publishers.SnapshotListener(
            query: firestore
                .collection("workout_history")
                .document(userId)
                .collection("workouts")
                .whereField("startTime", isGreaterThanOrEqualTo: startMs)
                .whereField("startTime", isLessThan: endMs)
                .order(by: "startTime", descending: true)
        )
        .map { snapshot in
            return snapshot.documents.compactMap { document in
                WorkoutHistory.fromFirestoreData(document.data())
            }
        }
        .handleEvents(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("[\(Self.tag)] Error getting monthly history: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    func updateRoutineNameInHistory(
        userId: String,
        routineId: String,
        newName: String
    ) async throws {
        do {
            print("[\(Self.tag)] Updating routine name in history: \(routineId) -> \(newName)")
            
            // Get all workout history entries for this routine
            let querySnapshot = try await firestore
                .collection("workout_history")
                .document(userId)
                .collection("workouts")
                .whereField("routineId", isEqualTo: routineId)
                .getDocuments()
            
            // Update each document with the new name using batch write
            let batch = firestore.batch()
            
            for document in querySnapshot.documents {
                batch.updateData(["name": newName], forDocument: document.reference)
            }
            
            // Commit all updates in a single batch
            try await batch.commit()
            
            print("[\(Self.tag)] Updated \(querySnapshot.documents.count) workout history entries with new name: \(newName)")
            
        } catch {
            print("[\(Self.tag)] Error updating routine name in history: \(error)")
            throw error
        }
    }
}

// MARK: - Firestore Snapshot Listener Publisher

extension Publishers {
    
    struct SnapshotListener: Publisher {
        typealias Output = QuerySnapshot
        typealias Failure = Error
        
        private let query: Query
        
        init(query: Query) {
            self.query = query
        }
        
        func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, QuerySnapshot == S.Input {
            let subscription = SnapshotSubscription(subscriber: subscriber, query: query)
            subscriber.receive(subscription: subscription)
        }
    }
    
    private class SnapshotSubscription<S>: Subscription where S: Subscriber, S.Input == QuerySnapshot, S.Failure == Error {
        
        private var subscriber: S?
        private var listenerRegistration: ListenerRegistration?
        
        init(subscriber: S, query: Query) {
            self.subscriber = subscriber
            
            listenerRegistration = query.addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    subscriber.receive(completion: .failure(error))
                } else if let snapshot = snapshot {
                    _ = subscriber.receive(snapshot)
                }
            }
        }
        
        func request(_ demand: Subscribers.Demand) {
            // Firestore listeners don't support demand
        }
        
        func cancel() {
            listenerRegistration?.remove()
            listenerRegistration = nil
            subscriber = nil
        }
    }
}