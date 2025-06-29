// Data/Repositories/WorkoutRepositoryImpl.swift
import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import CoreData
import os.log

class WorkoutRepositoryImpl: WorkoutRepository {
    
    // MARK: - Dependencies
    internal let firestore: Firestore
    private let authRepository: AuthRepository
    // TODO: Create these types when needed
    // private let workoutHistoryRepository: WorkoutHistoryRepository
    // private let coreDataStack: CoreDataStack
    
    // MARK: - Properties
    private let repositoryQueue = DispatchQueue(label: "workout.repository", qos: .userInitiated)
    internal let _syncProgress = CurrentValueSubject<SyncState, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()
    private var globalListener: ListenerRegistration?
    
    internal let logger = "WorkoutRepository"
    
    // MARK: - Public Properties
    var syncProgress: AnyPublisher<SyncState, Never> {
        _syncProgress.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(
        firestore: Firestore = Firestore.firestore(),
        authRepository: AuthRepository
        // TODO: Add these parameters when implementing
        // workoutHistoryRepository: WorkoutHistoryRepository,
        // coreDataStack: CoreDataStack
    ) {
        self.firestore = firestore
        self.authRepository = authRepository
        // TODO: Initialize these when implementing
        // self.workoutHistoryRepository = workoutHistoryRepository
        // self.coreDataStack = coreDataStack
        
        print("🚀 WorkoutRepositoryImpl initialized")
        // TODO: startGlobalExerciseSync()
    }
    
    // MARK: - Exercise Methods
    
    func getExercises() async throws -> AnyPublisher<[Exercise], Error> {
        print("⚡ Lightning-fast flat structure loading started")
        _syncProgress.send(.checkingCache)
        
        let isInitialSyncComplete = false // TODO: await checkInitialSyncComplete()
        let cacheCount = 0 // TODO: await getCachedExerciseCount()
        
        if isInitialSyncComplete && cacheCount > 0 {
            // Use Core Data cache (instant)
            print("⚡ Using Core Data cache (\(cacheCount) exercises)")
            _syncProgress.send(.complete(source: "cache", count: cacheCount))
            
            // TODO: getCachedExercises()
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            // Use Firestore with flat structure
            print("⚡ Using flat structure - single query for all exercises")
            _syncProgress.send(.fetchingNetwork)
            
            return Just([])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
        }
    }
    
    func searchExercises(query: String) -> AnyPublisher<[Exercise], Error> {
        print("⚡ Lightning-fast search for: '\(query)'")
        
        return Future<AnyPublisher<[Exercise], Error>, Error> { promise in
            Task {
                do {
                    let isInitialSyncComplete = false // TODO: await self.checkInitialSyncComplete()
                    
                    if isInitialSyncComplete {
                        // Use Core Data for search (instant)
                        print("⚡ Using Core Data for instant search")
                        let publisher = self.searchCachedExercises(query: query)
                        promise(.success(publisher))
                    } else {
                        // Use Firestore flat structure search
                        print("⚡ Using flat structure search")
                        let publisher = self.searchExercisesFromFirestore(query: query)
                        promise(.success(publisher))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
    
    func createCustomExercise(_ exercise: Exercise) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        let finalExercise = exercise.id.isEmpty ?
            Exercise(
                id: exercise.name.lowercased().replacingOccurrences(of: " ", with: ""),
                name: exercise.name,
                muscleGroup: exercise.muscleGroup,
                equipment: exercise.equipment,
                defaultReps: exercise.defaultReps,
                defaultSets: exercise.defaultSets,
                isBodyweight: exercise.isBodyweight,
                usesWeight: exercise.usesWeight,
                tracksDistance: exercise.tracksDistance,
                isTimeBased: exercise.isTimeBased,
                description: exercise.description,
                isSuperset: exercise.isSuperset,
                isDropset: exercise.isDropset
            ) : exercise
        
        // Store in flat structure format
        let flatExerciseData: [String: Any] = [
            "name": finalExercise.name,
            "id": finalExercise.id,
            "primaryMuscles": [finalExercise.muscleGroup],
            "secondaryMuscles": [],
            "equipment": finalExercise.equipment,
            "category": "strength",
            "force": "pull",
            "level": "beginner",
            "mechanic": "compound",
            "usesWeight": finalExercise.usesWeight,
            "isBodyweight": finalExercise.isBodyweight,
            "isTimeBased": finalExercise.isTimeBased,
            "isDistanceBased": finalExercise.tracksDistance,
            "defaultReps": finalExercise.defaultReps,
            "defaultSets": finalExercise.defaultSets,
            "instructions": finalExercise.description,
            "createdAt": Date().millisecondsSince1970,
            "isCustom": true
        ]
        
        // Store in Core Data cache
        // TODO: try await self.cacheExercise(finalExercise)
        
        // Store in Firestore flat collection
        try await firestore.collection("exercises")
            .document(finalExercise.id)
            .setData(flatExerciseData)
        
        print("Created custom exercise: \(finalExercise.name)")
    }
    
    // MARK: - Workout Methods
    
    func getWorkouts(userId: String) async throws -> AnyPublisher<[Workout], Error> {
        return Future<[Workout], Error> { promise in
            let listener = self.firestore.collection("user_workouts")
                .document(userId)
                .collection("routines")
                .order(by: "createdAt")
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        print("Error fetching workouts: \(error.localizedDescription)")
                        promise(.failure(RepositoryError.firestoreError(error.localizedDescription)))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let workouts = documents.compactMap { doc -> Workout? in
                        self.mapDocumentToWorkout(doc, userId: userId)
                    }
                    
                    promise(.success(workouts))
                }
            
            // Store listener for cleanup
            self.globalListener = listener
        }
        .eraseToAnyPublisher()
    }
    
    func getWorkoutById(_ workoutId: String) async throws -> Workout? {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        print("🔥 getWorkoutById called for: \(workoutId)")
        
        let document = try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(workoutId)
            .getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        // TODO: return mapDataToWorkout(data, documentId: workoutId, userId: userId)
        return Workout(id: workoutId, name: "Sample", userId: userId, colorHex: "#FF5722")
    }
    
    func createWorkout(_ workout: Workout) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        // Get used colors
        let usedColors: [String] = [] // TODO: try await getUsedColors(userId: userId)
        
        let colorHex = workout.colorHex ?? "#FF5722" // TODO: getNextAvailableColor(usedColors: usedColors)
        
        let docId = workout.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
        
        let exercisesData = workout.exercises.map { exercise in
            [
                "name": exercise.name,
                "muscleGroup": exercise.muscleGroup,
                "equipment": exercise.equipment
            ] // TODO: mapExerciseToData(exercise)
        }
        
        let workoutData: [String: Any] = [
            "name": workout.name,
            "exercises": exercisesData,
            "createdAt": workout.createdAt.millisecondsSince1970,
            "userId": userId,
            "colorHex": colorHex,
            "lastPerformed": workout.lastPerformed?.millisecondsSince1970 as Any
        ]
        
        try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(docId)
            .setData(workoutData)
        
        print("Created routine \(workout.name) with color \(colorHex)")
    }
    
    func updateWorkout(_ workout: Workout) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        print("🔥 REPOSITORY: Updating workout: \(workout.id) for user: \(userId)")
        
        let originalWorkout = try await getWorkoutById(workout.id)
        let nameChanged = originalWorkout?.name != workout.name
        
        let exercisesData = workout.exercises.map { exercise in
            [
                "name": exercise.name,
                "muscleGroup": exercise.muscleGroup,
                "equipment": exercise.equipment
            ] // TODO: mapExerciseToData(exercise)
        }
        
        let updateData: [String: Any] = [
            "name": workout.name,
            "exercises": exercisesData,
            "updatedAt": Date().millisecondsSince1970,
            "userId": userId
        ]
        
        try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(workout.id)
            .setData(updateData, merge: true)
        
        if nameChanged, let originalWorkout = originalWorkout {
            do {
                // TODO: try await workoutHistoryRepository.updateRoutineNameInHistory(
                //     userId: userId,
                //     routineId: workout.id,
                //     newName: workout.name
                // )
            } catch {
                print("Error updating workout history names: \(error.localizedDescription)")
            }
        }
        
        print("✅ Successfully updated workout: \(workout.name)")
    }
    
    func deleteWorkout(_ workoutId: String) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(workoutId)
            .delete()
    }
    
    func updateWorkoutColor(workoutId: String, colorHex: String) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(workoutId)
            .updateData(["colorHex": colorHex])
    }
    
    func updateWorkoutLastPerformed(routineId: String, lastPerformed: Date) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(routineId)
            .updateData(["lastPerformed": lastPerformed.millisecondsSince1970])
    }
    
    // MARK: - Statistics
    
    func getWorkoutCount(userId: String) async throws -> Int {
        do {
            let snapshot = try await firestore.collection("user_workouts")
                .document(userId)
                .collection("routines")
                .getDocuments()
            
            let count = snapshot.documents.count
            print("Workout count for user \(userId): \(count)")
            return count
        } catch {
            print("Error getting workout count: \(error.localizedDescription)")
            return 0
        }
    }
    
    func getCustomExerciseCount(userId: String) async throws -> Int {
        do {
            let snapshot = try await firestore.collection("user_workouts")
                .document(userId)
                .collection("custom_exercises")
                .getDocuments()
            
            let count = snapshot.documents.count
            print("Custom exercise count for user \(userId): \(count)")
            return count
        } catch {
            print("Error getting custom exercise count: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Calendar and Suggestions
    
    func getWeeklyCalendar() -> AnyPublisher<[WeeklyCalendarDay], Error> {
        return Future { promise in
            Task {
                do {
                    guard let userId = try await self.authRepository.getCurrentUser()?.id else {
                        throw RepositoryError.userNotAuthenticated
                    }
                    
                    let calendar = Calendar.current
                    let today = Date()
                    let startDate = calendar.date(byAdding: .day, value: -6, to: today)!
                    let weekDates = (0...6).compactMap {
                        calendar.date(byAdding: .day, value: $0, to: startDate)
                    }
                    
                    let emptyWeek = weekDates.map { date in
                        WeeklyCalendarDay(date: date, routineId: nil, isCompleted: false, colorHex: nil)
                    }
                    
                    promise(.success(emptyWeek))
                    
                    // Listen for updates
                    let startMs = startDate.millisecondsSince1970
                    
                    let listener = self.firestore.collection("workout_history")
                        .document(userId)
                        .collection("workouts")
                        .whereField("startTime", isGreaterThanOrEqualTo: startMs)
                        .addSnapshotListener { snapshot, error in
                            if let error = error {
                                print("getWeeklyCalendar: listener error \(error.localizedDescription)")
                                return
                            }
                            
                            let completedDays: [Date: (String?, Bool, String?)] = snapshot?.documents.compactMap { doc in
                                guard let startTime = doc.data()["startTime"] as? Int64 else { return nil }
                                let date = Date(millisecondsSince1970: startTime)
                                let routineId = doc.data()["routineId"] as? String
                                let colorHex = doc.data()["colorHex"] as? String
                                return (calendar.startOfDay(for: date), (routineId, true, colorHex))
                            }.reduce(into: [:]) { (result: inout [Date: (String?, Bool, String?)], item: (Date, (String?, Bool, String?))) in
                                result[item.0] = item.1
                            } ?? [:]
                            
                            let calendarDays = weekDates.map { date in
                                let dayStart = calendar.startOfDay(for: date)
                                let completion = completedDays[dayStart]
                                return WeeklyCalendarDay(
                                    date: date,
                                    routineId: completion?.0,
                                    isCompleted: completion?.1 ?? false,
                                    colorHex: completion?.2
                                )
                            }
                            
                            promise(.success(calendarDays))
                        }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getSuggestedNextWorkout() -> AnyPublisher<Workout?, Error> {
        return Future { promise in
            Task {
                do {
                    guard let userId = try await self.authRepository.getCurrentUser()?.id else {
                        throw RepositoryError.userNotAuthenticated
                    }
                    
                    let listener = self.firestore.collection("user_workouts")
                        .document(userId)
                        .collection("routines")
                        .addSnapshotListener { snapshot, error in
                            if let error = error {
                                print("Error fetching workouts: \(error.localizedDescription)")
                                promise(.failure(RepositoryError.firestoreError(error.localizedDescription)))
                                return
                            }
                            
                            let workouts: [Workout] = [] // TODO: snapshot?.documents.compactMap { doc in
                            //     self.mapDocumentToWorkout(doc, userId: userId)
                            // } ?? []
                            
                            let suggested = workouts.min { w1, w2 in
                                let time1 = w1.lastPerformed?.timeIntervalSince1970 ?? 0
                                let time2 = w2.lastPerformed?.timeIntervalSince1970 ?? 0
                                return time1 < time2
                            }
                            
                            promise(.success(suggested))
                        }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func searchCachedExercises(query: String) -> AnyPublisher<[Exercise], Error> {
        // TODO: Implement Core Data search
        return Just([])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func searchExercisesFromFirestore(query: String) -> AnyPublisher<[Exercise], Error> {
        // TODO: Implement Firestore search with flat structure
        return Just([])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func mapDocumentToWorkout(_ document: DocumentSnapshot, userId: String) -> Workout? {
        guard let data = document.data() else { return nil }
        
        let name = data["name"] as? String ?? "Unknown"
        let colorHex = data["colorHex"] as? String ?? "#FF5722"
        let createdAt = Date(millisecondsSince1970: data["createdAt"] as? Int64 ?? 0)
        let lastPerformed = data["lastPerformed"] as? Int64
        
        return Workout(
            id: document.documentID,
            name: name,
            userId: userId,
            exercises: [], // TODO: Map exercises from data
            createdAt: createdAt,
            colorHex: colorHex,
            lastPerformed: lastPerformed != nil ? Date(millisecondsSince1970: lastPerformed!) : nil
        )
    }
    
    // MARK: - Cleanup
    
    func onCleared() {
        globalListener?.remove()
        cancellables.removeAll()
    }
}
