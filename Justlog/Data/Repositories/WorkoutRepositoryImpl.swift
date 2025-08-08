import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import CoreData
import os.log

class WorkoutRepositoryImpl: WorkoutRepository {
    
    // MARK: - Sync State
    enum SyncState {
        case idle
        case checkingCache
        case fetchingNetwork
        case syncingToCache
        case complete(source: String, count: Int)
        case error(message: String)
    }
    
    // MARK: - Dependencies
    internal let firestore: Firestore
    private let authRepository: AuthRepository
    private let workoutHistoryRepository: WorkoutHistoryRepository?
    
    // MARK: - Properties
    private let repositoryQueue = DispatchQueue(label: "workout.repository", qos: .userInitiated)
    internal let _syncProgress = CurrentValueSubject<SyncState, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()
    private var globalListener: ListenerRegistration?
    private var exerciseCache: [Exercise] = []
    private var lastCacheUpdate: Date = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    internal let logger = Logger(subsystem: "com.justlog.app", category: "WorkoutRepository")
    
    // MARK: - Public Properties
    var syncProgress: AnyPublisher<SyncState, Never> {
        _syncProgress.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(
        firestore: Firestore = Firestore.firestore(),
        authRepository: AuthRepository,
        workoutHistoryRepository: WorkoutHistoryRepository? = nil
    ) {
        self.firestore = firestore
        self.authRepository = authRepository
        self.workoutHistoryRepository = workoutHistoryRepository
        
        logger.info("🚀 WorkoutRepositoryImpl initialized - starting global sync")
        Task {
            await startGlobalExerciseSync()
        }
    }
    
    // MARK: - Global Exercise Sync
    private func startGlobalExerciseSync() async {
        guard let _ = try? await authRepository.getCurrentUser() else { return }
        
        logger.info("🌍 Starting global sync for flat structure")
        
        globalListener = firestore.collection("exercises")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.logger.error("Global sync error: \(error.localizedDescription)")
                    self?._syncProgress.send(.error(message: error.localizedDescription))
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                Task {
                    await self?.processGlobalSync(documents: snapshot.documents)
                }
            }
    }
    
    private func processGlobalSync(documents: [DocumentSnapshot]) async {
        do {
            let firestoreCount = documents.count
            let cacheCount = exerciseCache.count
            let isCacheValid = Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration
            
            logger.info("🌍 Global sync: Firestore=\(firestoreCount), Cache=\(cacheCount), Valid=\(isCacheValid)")
            
            if !isCacheValid || firestoreCount != cacheCount {
                logger.info("🌍 Performing sync - processing all documents")
                await performFullSync(documents: documents)
            } else {
                logger.info("🌍 Cache is up to date")
                _syncProgress.send(.complete(source: "cache", count: cacheCount))
            }
        } catch {
            logger.error("🌍 Global sync processing failed: \(error.localizedDescription)")
            _syncProgress.send(.error(message: "Sync failed: \(error.localizedDescription)"))
        }
    }
    
    private func performFullSync(documents: [DocumentSnapshot]) async {
        do {
            logger.info("📥 Performing full sync with flat structure")
            _syncProgress.send(.fetchingNetwork)
            
            let exercises = documents.compactMap { doc in
                mapFlatDocumentToExercise(doc)
            }
            
            exerciseCache = exercises
            lastCacheUpdate = Date()
            
            logger.info("✅ Full sync complete: \(exercises.count) exercises")
            _syncProgress.send(.syncingToCache)
            _syncProgress.send(.complete(source: "network", count: exercises.count))
        } catch {
            logger.error("❌ Full sync failed: \(error.localizedDescription)")
            _syncProgress.send(.error(message: "Full sync failed: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Exercise Methods
    
    func getExercises() async throws -> AnyPublisher<[Exercise], Error> {
        logger.info("⚡ Lightning-fast flat structure loading started")
        _syncProgress.send(.checkingCache)
        
        let isCacheValid = Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration
        
        if isCacheValid && !exerciseCache.isEmpty {
            // Use memory cache (instant)
            logger.info("⚡ Using memory cache (\(exerciseCache.count) exercises)")
            _syncProgress.send(.complete(source: "cache", count: exerciseCache.count))
            
            return Just(exerciseCache)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            // Use Firestore with flat structure
            logger.info("⚡ Using flat structure - single query for all exercises")
            _syncProgress.send(.fetchingNetwork)
            
            return firestore.collection("exercises")
                .snapshotPublisher()
                .map { snapshot in
                    let startTime = Date()
                    let exercises = snapshot.documents.compactMap { doc in
                        self.mapFlatDocumentToExercise(doc)
                    }
                    
                    let loadTime = Date().timeIntervalSince(startTime) * 1000
                    self.logger.info("⚡ FLAT STRUCTURE: Loaded \(exercises.count) exercises in \(Int(loadTime))ms!")
                    
                    // Update cache
                    self.exerciseCache = exercises
                    self.lastCacheUpdate = Date()
                    
                    self._syncProgress.send(.complete(source: "flat", count: exercises.count))
                    return exercises
                }
                .eraseToAnyPublisher()
        }
    }
    
    func searchExercises(query: String) -> AnyPublisher<[Exercise], Error> {
        logger.info("⚡ Lightning-fast search for: '\(query)'")
        
        let isCacheValid = Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration
        
        if isCacheValid && !exerciseCache.isEmpty {
            // Use memory cache for search (instant)
            logger.info("⚡ Using memory cache for instant search")
            
            let filteredExercises = query.isEmpty ? exerciseCache : exerciseCache.filter { exercise in
                exercise.matchesFlexibleSearch(query: query)
            }
            
            return Just(filteredExercises)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            // Use Firestore flat structure search
            logger.info("⚡ Using flat structure search")
            
            return firestore.collection("exercises")
                .snapshotPublisher()
                .map { snapshot in
                    let allExercises = snapshot.documents.compactMap { doc in
                        self.mapFlatDocumentToExercise(doc)
                    }
                    
                    // Update cache
                    self.exerciseCache = allExercises
                    self.lastCacheUpdate = Date()
                    
                    let filteredExercises = query.isEmpty ? allExercises : allExercises.filter { exercise in
                        exercise.matchesFlexibleSearch(query: query)
                    }
                    
                    self.logger.info("⚡ Flat search found \(filteredExercises.count) results instantly")
                    return filteredExercises
                }
                .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Flat Document Mapping
    private func mapFlatDocumentToExercise(_ doc: DocumentSnapshot) -> Exercise? {
        do {
            guard let data = doc.data() else { return nil }
            let name = data["name"] as? String ?? doc.documentID
            let exerciseId = data["id"] as? String ?? name.toCamelId()
            
            // Debug important exercises like Plank
            if name.lowercased().contains("plank") {
                logger.debug("🔥 FLAT STRUCTURE - PLANK MAPPING:")
                logger.debug("  Document ID: \(doc.documentID)")
                data.forEach { key, value in
                    logger.debug("  \(key): \(value)")
                }
            }
            
            // Handle field name inconsistencies and missing fields
            let isTimeBased = data["isTimeBased"] as? Bool ?? false
            let usesWeight = data["usesWeight"] as? Bool ?? true
            let tracksDistance = (data["tracksDistance"] as? Bool) ??
                               (data["isDistanceBased"] as? Bool) ?? false
            let isBodyweight = data["isBodyweight"] as? Bool ?? false
            
            // Smart defaults: If boolean fields are missing, infer from exercise name
            let finalIsTimeBased = data.keys.contains("isTimeBased") ? isTimeBased :
                name.lowercased().contains("plank") ||
                name.lowercased().contains("wall sit") ||
                name.lowercased().contains("dead hang") ||
                name.lowercased().contains("hold")
            
            let finalUsesWeight = data.keys.contains("usesWeight") ? usesWeight :
                !(finalIsTimeBased && !name.lowercased().contains("weighted")) &&
                !name.lowercased().contains("bodyweight") &&
                !name.lowercased().contains("push") &&
                !name.lowercased().contains("pull")
            
            let finalTracksDistance = data.keys.contains("tracksDistance") || data.keys.contains("isDistanceBased") ?
                tracksDistance :
                name.lowercased().contains("running") ||
                name.lowercased().contains("cycling") ||
                name.lowercased().contains("rowing") ||
                name.lowercased().contains("swimming")
            
            let finalIsBodyweight = data.keys.contains("isBodyweight") ? isBodyweight : !finalUsesWeight
            
            let exercise = Exercise(
                id: exerciseId,
                name: name,
                muscleGroup: mapPrimaryMuscleToMuscleGroup(data["primaryMuscles"] as? [String]),
                equipment: data["equipment"] as? String ?? "",
                defaultReps: (data["defaultReps"] as? NSNumber)?.intValue ?? (finalIsTimeBased ? 0 : 12),
                defaultSets: (data["defaultSets"] as? NSNumber)?.intValue ?? 3,
                isBodyweight: finalIsBodyweight,
                usesWeight: finalUsesWeight,
                tracksDistance: finalTracksDistance,
                isTimeBased: finalIsTimeBased,
                description: data["instructions"] as? String ?? ""
            )
            
            // Final debug for Plank exercises
            if name.lowercased().contains("plank") {
                logger.debug("🔥 FINAL MAPPED EXERCISE:")
                logger.debug("  name: \(exercise.name)")
                logger.debug("  id: \(exercise.id)")
                logger.debug("  isTimeBased: \(exercise.isTimeBased)")
                logger.debug("  usesWeight: \(exercise.usesWeight)")
                logger.debug("  tracksDistance: \(exercise.tracksDistance)")
                logger.debug("  isBodyweight: \(exercise.isBodyweight)")
                logger.debug("  defaultReps: \(exercise.defaultReps)")
            }
            
            return exercise
            
        } catch {
            logger.error("Error mapping flat exercise \(doc.documentID): \(error.localizedDescription)")
            return nil
        }
    }
    
    func createCustomExercise(_ exercise: Exercise) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        let finalExercise = exercise.id.isEmpty ?
            exercise.copyWith(id: exercise.name.toCamelId()) : exercise
        
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
        
        // Store in Firestore flat collection
        try await firestore.collection("exercises")
            .document(finalExercise.id)
            .setData(flatExerciseData)
        
        // Update cache
        exerciseCache.append(finalExercise)
        
        logger.info("Created custom exercise: \(finalExercise.name)")
    }
    
    // MARK: - Workout Methods
    
    func getWorkouts(userId: String) async throws -> AnyPublisher<[Workout], Error> {
        return firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .order(by: "createdAt")
            .snapshotPublisher()
            .map { snapshot in
                snapshot.documents.compactMap { doc in
                    self.mapDocumentToWorkout(doc, userId: userId)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getWorkoutById(_ workoutId: String) async throws -> Workout? {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        logger.info("🔥 getWorkoutById called for: \(workoutId)")
        
        let document = try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(workoutId)
            .getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        let exercises = (data["exercises"] as? [[String: Any]])?.compactMap { exerciseMap in
            mapToExercise(exerciseMap)
        } ?? []
        
        return Workout(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            userId: userId,
            exercises: exercises,
            createdAt: Date(millisecondsSince1970: data["createdAt"] as? Int64 ?? 0),
            colorHex: data["colorHex"] as? String,
            lastPerformed: data["lastPerformed"] as? Int64 != nil ? 
                Date(millisecondsSince1970: data["lastPerformed"] as! Int64) : nil
        )
    }
    
    func createWorkout(_ workout: Workout) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        // Get used colors
        let usedColors = try await getUsedColors(userId: userId)
        
        let colorHex = workout.colorHex ?? getNextAvailableColor(usedColors: usedColors)
        
        let docId = workout.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-z0-9_]", with: "", options: .regularExpression)
        
        // Use consistent field names
        let exercisesData = workout.exercises.map { exercise in
            [
                "id": exercise.id,
                "name": exercise.name,
                "equipment": exercise.equipment,
                "muscleGroup": exercise.muscleGroup,
                "defaultReps": exercise.defaultReps,
                "defaultSets": exercise.defaultSets,
                "isBodyweight": exercise.isBodyweight,
                "usesWeight": exercise.usesWeight,
                "isDistanceBased": exercise.tracksDistance,
                "isTimeBased": exercise.isTimeBased,
                "description": exercise.description,
                "isSuperset": exercise.isSuperset ?? false,
                "isDropset": exercise.isDropset ?? false
            ]
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
        
        logger.info("Created routine \(workout.name) with color \(colorHex)")
    }
    
    func updateWorkout(_ workout: Workout) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        logger.info("🔥 REPOSITORY: Updating workout: \(workout.id) for user: \(userId)")
        
        let originalWorkout = try await getWorkoutById(workout.id)
        let nameChanged = originalWorkout?.name != workout.name
        
        // Use consistent field names that match Firestore exercises collection
        let exercisesData = workout.exercises.map { exercise in
            [
                "id": exercise.id,
                "name": exercise.name,
                "equipment": exercise.equipment,
                "muscleGroup": exercise.muscleGroup,
                "defaultReps": exercise.defaultReps,
                "defaultSets": exercise.defaultSets,
                "isBodyweight": exercise.isBodyweight,
                "usesWeight": exercise.usesWeight,
                "isDistanceBased": exercise.tracksDistance,
                "isTimeBased": exercise.isTimeBased,
                "description": exercise.description,
                "isSuperset": exercise.isSuperset ?? false,
                "isDropset": exercise.isDropset ?? false
            ]
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
                try await workoutHistoryRepository?.updateRoutineNameInHistory(
                    userId: userId,
                    routineId: workout.id,
                    newName: workout.name
                )
            } catch {
                logger.error("Error updating workout history names: \(error.localizedDescription)")
            }
        }
        
        logger.info("✅ Successfully updated workout: \(workout.name)")
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
            logger.info("Workout count for user \(userId): \(count)")
            return count
        } catch {
            logger.error("Error getting workout count: \(error.localizedDescription)")
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
            logger.info("Custom exercise count for user \(userId): \(count)")
            return count
        } catch {
            logger.error("Error getting custom exercise count: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Calendar and Suggestions
    
    func getWeeklyCalendar() -> AnyPublisher<[WeeklyCalendarDay], Error> {
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
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
                        let dayFormatter = DateFormatter()
                        dayFormatter.dateFormat = "E"
                        let dayName = dayFormatter.string(from: date)
                        let dayNumber = Calendar.current.component(.day, from: date)
                        let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
                        
                        return WeeklyCalendarDay(
                            date: date,
                            dayName: dayName,
                            dayNumber: dayNumber,
                            isToday: isToday,
                            isSelected: false,
                            hasWorkout: false,
                            routineId: nil,
                            isCompleted: false,
                            colorHex: nil
                        )
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
                                self.logger.error("getWeeklyCalendar: listener error \(error.localizedDescription)")
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
                                
                                let dayFormatter = DateFormatter()
                                dayFormatter.dateFormat = "E"
                                let dayName = dayFormatter.string(from: date)
                                let dayNumber = Calendar.current.component(.day, from: date)
                                let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
                                
                                return WeeklyCalendarDay(
                                    date: date,
                                    dayName: dayName,
                                    dayNumber: dayNumber,
                                    isToday: isToday,
                                    isSelected: false,
                                    hasWorkout: completion?.0 != nil,
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
        return Future { [weak self] promise in
            Task {
                guard let self = self else { return }
                do {
                    guard let userId = try await self.authRepository.getCurrentUser()?.id else {
                        throw RepositoryError.userNotAuthenticated
                    }
                    
                    let listener = self.firestore.collection("user_workouts")
                        .document(userId)
                        .collection("routines")
                        .addSnapshotListener { snapshot, error in
                            if let error = error {
                                self.logger.error("Error fetching workouts: \(error.localizedDescription)")
                                promise(.failure(RepositoryError.firestoreError(error.localizedDescription)))
                                return
                            }
                            
                            let workouts = snapshot?.documents.compactMap { doc in
                                self.mapDocumentToWorkout(doc, userId: userId)
                            } ?? []
                            
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
    
    private func mapPrimaryMuscleToMuscleGroup(_ primaryMuscles: [String]?) -> String {
        guard let muscle = primaryMuscles?.first?.lowercased() else { return "full body" }
        
        switch muscle {
        case "abdominals": return "core"
        case "quadriceps", "hamstrings", "glutes": return "legs"
        case "calves": return "calves"
        case "chest": return "chest"
        case "shoulders": return "shoulders"
        case "triceps": return "triceps"
        case "biceps": return "biceps"
        case "forearms": return "forearms"
        case "lats", "middle back", "lower back", "traps": return "back"
        default: return muscle
        }
    }
    
    private func mapToExercise(_ exerciseMap: [String: Any]) -> Exercise? {
        guard let name = exerciseMap["name"] as? String else { return nil }
        
        let rawId = exerciseMap["id"] as? String
        let finalId = rawId?.isEmpty == false ? rawId! : name.toCamelId()
        
        // Debug Plank exercises
        if name.lowercased().contains("plank") {
            logger.debug("🔥 mapToExercise DEBUG for \(name):")
            exerciseMap.forEach { key, value in
                logger.debug("  \(key): \(value)")
            }
        }
        
        let exercise = Exercise(
            id: finalId,
            name: name,
            muscleGroup: exerciseMap["muscleGroup"] as? String ?? "",
            equipment: exerciseMap["equipment"] as? String ?? "",
            defaultReps: exerciseMap["defaultReps"] as? Int ?? 12,
            defaultSets: exerciseMap["defaultSets"] as? Int ?? 3,
            isBodyweight: exerciseMap["isBodyweight"] as? Bool ?? false,
            usesWeight: exerciseMap["usesWeight"] as? Bool ?? true,
            tracksDistance: exerciseMap["isDistanceBased"] as? Bool ?? false,
            isTimeBased: exerciseMap["isTimeBased"] as? Bool ?? false,
            description: exerciseMap["description"] as? String ?? "",
            isSuperset: exerciseMap["isSuperset"] as? Bool ?? false,
            isDropset: exerciseMap["isDropset"] as? Bool ?? false
        )
        
        if name.lowercased().contains("plank") {
            logger.debug("🔥 Final Exercise object from routine:")
            logger.debug("  name: \(exercise.name)")
            logger.debug("  isTimeBased: \(exercise.isTimeBased)")
            logger.debug("  isBodyweight: \(exercise.isBodyweight)")
            logger.debug("  usesWeight: \(exercise.usesWeight)")
            logger.debug("  tracksDistance: \(exercise.tracksDistance)")
        }
        
        return exercise
    }
    
    private func mapDocumentToWorkout(_ document: DocumentSnapshot, userId: String) -> Workout? {
        guard let data = document.data() else { return nil }
        
        let exercises = (data["exercises"] as? [[String: Any]])?.compactMap { exerciseMap in
            mapToExercise(exerciseMap)
        } ?? []
        
        return Workout(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            userId: userId,
            exercises: exercises,
            createdAt: Date(millisecondsSince1970: data["createdAt"] as? Int64 ?? 0),
            colorHex: data["colorHex"] as? String,
            lastPerformed: data["lastPerformed"] as? Int64 != nil ?
                Date(millisecondsSince1970: data["lastPerformed"] as! Int64) : nil
        )
    }
    
    private func getUsedColors(userId: String) async throws -> [String] {
        let snapshot = try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            doc.data()["colorHex"] as? String
        }
    }
    
    private func getNextAvailableColor(usedColors: [String]) -> String {
        let availableColors = RoutineColors.colorOptions.filter { color in
            !usedColors.contains(color.hex)
        }
        
        return availableColors.first?.hex ?? RoutineColors.colorOptions[usedColors.count % RoutineColors.colorOptions.count].hex
    }
    
    // MARK: - Cleanup
    
    func onCleared() {
        globalListener?.remove()
        cancellables.removeAll()
    }
}

// MARK: - Extensions

extension String {
    func normalizeForSearch() -> String {
        return self.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
    }
    
    func toCamelId() -> String {
        return self.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    }
}

extension Exercise {
    func matchesFlexibleSearch(query: String) -> Bool {
        let normalizedQuery = query.normalizeForSearch()
        return name.normalizeForSearch().contains(normalizedQuery) ||
               equipment.normalizeForSearch().contains(normalizedQuery) ||
               muscleGroup.normalizeForSearch().contains(normalizedQuery)
    }
    
    func copyWith(
        id: String? = nil,
        name: String? = nil,
        muscleGroup: String? = nil,
        equipment: String? = nil,
        defaultReps: Int? = nil,
        defaultSets: Int? = nil,
        isBodyweight: Bool? = nil,
        usesWeight: Bool? = nil,
        tracksDistance: Bool? = nil,
        isTimeBased: Bool? = nil,
        description: String? = nil,
        isSuperset: Bool? = nil,
        isDropset: Bool? = nil
    ) -> Exercise {
        return Exercise(
            id: id ?? self.id,
            name: name ?? self.name,
            muscleGroup: muscleGroup ?? self.muscleGroup,
            equipment: equipment ?? self.equipment,
            defaultReps: defaultReps ?? self.defaultReps,
            defaultSets: defaultSets ?? self.defaultSets,
            isBodyweight: isBodyweight ?? self.isBodyweight,
            usesWeight: usesWeight ?? self.usesWeight,
            tracksDistance: tracksDistance ?? self.tracksDistance,
            isTimeBased: isTimeBased ?? self.isTimeBased,
            description: description ?? self.description ?? "",
            isSuperset: isSuperset ?? self.isSuperset,
            isDropset: isDropset ?? self.isDropset
        )
    }
}

extension QuerySnapshot {
    func snapshotPublisher() -> AnyPublisher<QuerySnapshot, Error> {
        return Just(self)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

extension Query {
    func snapshotPublisher() -> AnyPublisher<QuerySnapshot, Error> {
        return Future { promise in
            let listener = self.addSnapshotListener { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                } else if let snapshot = snapshot {
                    promise(.success(snapshot))
                }
            }
            // Note: In a real implementation, you'd want to manage listener cleanup
        }
        .eraseToAnyPublisher()
    }
}