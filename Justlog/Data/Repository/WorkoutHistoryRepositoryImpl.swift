import Foundation
import Combine
import Firebase
import FirebaseFirestore

class WorkoutHistoryRepositoryImpl: WorkoutHistoryRepository {
    
    // MARK: - Firebase Implementation
    
    private let firestore = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("🔥 WorkoutHistoryRepositoryImpl initialized with Firebase")
    }
    
    func saveWorkoutHistory(_ workoutHistory: WorkoutHistory) async throws {
        print("🔥 Saving workout history to Firebase: \(workoutHistory.name)")
        
        let data = workoutHistory.toFirestoreData()
        
        do {
            try await firestore
                .collection("workout_history")
                .document(workoutHistory.userId)
                .collection("workouts")
                .document(workoutHistory.id)
                .setData(data)
            
            print("✅ Workout history saved successfully to Firebase")
        } catch {
            print("❌ Error saving workout history: \(error)")
            throw error
        }
    }
    
    func getWorkoutHistory(userId: String) -> AnyPublisher<[WorkoutHistory], Error> {
        return Future<[WorkoutHistory], Error> { promise in
            Task {
                do {
                    print("🔥 Loading workout history from Firebase for user: \(userId)")
                    
                    let snapshot = try await self.firestore
                        .collection("workout_history")
                        .document(userId)
                        .collection("workouts")
                        .order(by: "startTime", descending: true)
                        .getDocuments()
                    
                    let workouts = snapshot.documents.compactMap { document in
                        WorkoutHistory.fromFirestoreData(document.data())
                    }
                    
                    print("✅ Loaded \(workouts.count) workout history entries from Firebase")
                    promise(.success(workouts))
                    
                } catch {
                    print("❌ Error loading workout history: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getMonthlyHistory(userId: String, monthStart: Date, timeZone: TimeZone) -> AnyPublisher<[WorkoutHistory], Error> {
        return Future<[WorkoutHistory], Error> { promise in
            Task {
                do {
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.timeZone = timeZone
                    
                    let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
                    let startTimeMs = monthStart.timeIntervalSince1970 * 1000
                    let endTimeMs = monthEnd.timeIntervalSince1970 * 1000
                    
                    print("🔥 Loading monthly history from \(monthStart) to \(monthEnd)")
                    
                    let snapshot = try await self.firestore
                        .collection("workout_history")
                        .document(userId)
                        .collection("workouts")
                        .whereField("startTime", isGreaterThanOrEqualTo: startTimeMs)
                        .whereField("startTime", isLessThan: endTimeMs)
                        .order(by: "startTime", descending: true)
                        .getDocuments()
                    
                    let workouts = snapshot.documents.compactMap { document in
                        WorkoutHistory.fromFirestoreData(document.data())
                    }
                    
                    print("✅ Loaded \(workouts.count) monthly workout entries")
                    promise(.success(workouts))
                    
                } catch {
                    print("❌ Error loading monthly history: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateRoutineNameInHistory(userId: String, routineId: String, newName: String) async throws {
        do {
            print("🔥 Updating routine name in workout history: \(routineId) -> \(newName)")
            
            let snapshot = try await firestore
                .collection("workout_history")
                .document(userId)
                .collection("workouts")
                .whereField("routineId", isEqualTo: routineId)
                .getDocuments()
            
            let batch = firestore.batch()
            
            for document in snapshot.documents {
                let docRef = firestore
                    .collection("workout_history")
                    .document(userId)
                    .collection("workouts")
                    .document(document.documentID)
                
                batch.updateData(["name": newName], forDocument: docRef)
            }
            
            try await batch.commit()
            print("✅ Updated \(snapshot.documents.count) workout history entries")
            
        } catch {
            print("❌ Error updating routine name in history: \(error)")
            throw error
        }
    }
}