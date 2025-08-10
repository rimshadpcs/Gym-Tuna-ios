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
        
        logger.info("⚡ WorkoutRepositoryImpl initialized with lightning-fast flat structure")
        
        Task {
            await startGlobalExerciseSync()
        }
    }
    
    // MARK: - Private Sync Methods
    
    private func startGlobalExerciseSync() async {
        logger.info("🌍 Starting global exercise sync")
        
        globalListener = firestore.collection("exercises").addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                self?.logger.error("❌ Firestore listener error: \(error.localizedDescription)")
                self?._syncProgress.send(.error(error.localizedDescription))
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            Task {
                await self?.processGlobalSync(documents: snapshot.documents)
            }
        }
    }
    
    private func processGlobalSync(documents: [DocumentSnapshot]) async {
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
    }
    
    private func performFullSync(documents: [DocumentSnapshot]) async {
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
    }
    
    // MARK: - Exercise Methods
    
    func getExercises() async throws -> AnyPublisher<[Exercise], Error> {
        logger.info("⚡ Lightning-fast flat structure loading started")
        _syncProgress.send(.checkingCache)
        
        let isCacheValid = Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration
        
        if isCacheValid && !exerciseCache.isEmpty {
            logger.info("⚡ Using memory cache (\(self.exerciseCache.count) exercises)")
            _syncProgress.send(.complete(source: "cache", count: exerciseCache.count))
            
            return Just(exerciseCache)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            logger.info("📡 Loading from network")
            _syncProgress.send(.fetchingNetwork)
            
            return firestore.collection("exercises").snapshotPublisher()
                .map { [weak self] snapshot in
                    let exercises = snapshot.documents.compactMap { doc in
                        self?.mapFlatDocumentToExercise(doc)
                    }
                    
                    self?.exerciseCache = exercises
                    self?.lastCacheUpdate = Date()
                    
                    self?._syncProgress.send(.complete(source: "flat", count: exercises.count))
                    return exercises
                }
                .eraseToAnyPublisher()
        }
    }
    
    func searchExercises(query: String) -> AnyPublisher<[Exercise], Error> {
        logger.info("🔍 Searching exercises with query: '\(query)'")
        
        let isCacheValid = Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration
        
        if isCacheValid && !exerciseCache.isEmpty {
            logger.info("🔍 Using cached search")
            
            let filteredExercises = query.isEmpty ? exerciseCache : exerciseCache.filter { exercise in
                exercise.matchesFlexibleSearch(query: query)
            }
            
            return Just(filteredExercises)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            logger.info("🔍 Network search")
            
            return firestore.collection("exercises").snapshotPublisher()
                .map { [weak self] snapshot in
                    let allExercises = snapshot.documents.compactMap { doc in
                        self?.mapFlatDocumentToExercise(doc)
                    }
                    
                    self?.exerciseCache = allExercises
                    self?.lastCacheUpdate = Date()
                    
                    return query.isEmpty ? allExercises : allExercises.filter { exercise in
                        exercise.matchesFlexibleSearch(query: query)
                    }
                }
                .eraseToAnyPublisher()
        }
    }
    
    private func mapFlatDocumentToExercise(_ doc: DocumentSnapshot) -> Exercise? {
        guard let data = doc.data() else { return nil }
        
        let name = data["name"] as? String ?? doc.documentID
        let exerciseId = data["id"] as? String ?? name.toCamelId()
        
        if name.lowercased().contains("plank") {
            logger.debug("🔥 FLAT STRUCTURE - PLANK MAPPING:")
            logger.debug("  Document ID: \(doc.documentID)")
            for (key, value) in data {
                logger.debug("  \(String(describing: key)): \(String(describing: value))")
            }
        }
        
        let isTimeBased = data["isTimeBased"] as? Bool ?? false
        let usesWeight = data["usesWeight"] as? Bool ?? true
        let tracksDistance: Bool = (data["tracksDistance"] as? Bool) ??
                                 (data["isDistanceBased"] as? Bool) ?? false
        let isBodyweight = data["isBodyweight"] as? Bool ?? false
        
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
        
        if name.lowercased().contains("plank") {
            logger.debug("🔥 PLANK PROCESSING:")
            logger.debug("  finalIsTimeBased: \(finalIsTimeBased)")
            logger.debug("  finalUsesWeight: \(finalUsesWeight)")
            logger.debug("  finalIsBodyweight: \(finalIsBodyweight)")
            logger.debug("  finalTracksDistance: \(finalTracksDistance)")
        }
        
        return Exercise(
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
    }
    
    func createCustomExercise(_ exercise: Exercise) async throws {
        // Check authentication status first
        let currentUser = try await authRepository.getCurrentUser()
        guard let userId = currentUser?.id else {
            logger.error("❌ User not authenticated when creating exercise")
            logger.error("❌ Current user object: \(String(describing: currentUser))")
            throw RepositoryError.userNotAuthenticated
        }
        
        logger.info("🆕 Creating custom exercise: \(exercise.name) for user: \(userId)")
        logger.info("👤 User authenticated: \(currentUser?.email ?? "no email")")
        
        let finalExercise = exercise.id.isEmpty ?
            exercise.copyWith(id: exercise.name.toCamelId()) : exercise
        
        let exerciseData: [String: Any] = [
            "name": finalExercise.name,
            "id": finalExercise.id,
            "muscleGroup": finalExercise.muscleGroup, // ✅ Firebase rules expect 'muscleGroup'
            "primaryMuscles": [finalExercise.muscleGroup], // Keep for compatibility
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
            "createdBy": userId,
            "isCustom": true
        ]
        
        logger.info("📝 Attempting to save exercise data: \(exerciseData)")
        
        do {
            try await firestore.collection("exercises")
                .document(finalExercise.id)
                .setData(exerciseData)
            
            exerciseCache.append(finalExercise)
            
            logger.info("✅ Successfully created custom exercise: \(finalExercise.name)")
        } catch {
            logger.error("❌ Firebase error creating exercise: \(error)")
            logger.error("❌ Error details: \(error.localizedDescription)")
            logger.error("❌ Exercise data that failed: \(exerciseData)")
            
            // Check if it's a permission error
            let errorMsg = error.localizedDescription.lowercased()
            if errorMsg.contains("permission") || 
               errorMsg.contains("denied") ||
               errorMsg.contains("permission_denied") {
                logger.error("🔒 Permission denied - check Firebase rules and user authentication")
                throw RepositoryError.unauthorized("Permission denied creating custom exercise")
            }
            
            throw RepositoryError.firestoreError(error.localizedDescription)
        }
    }
    
    // MARK: - Workout Methods
    
    func getWorkouts(userId: String) async throws -> AnyPublisher<[Workout], Error> {
        return firestore.collection("user_workouts").document(userId).collection("routines")
            .snapshotPublisher()
            .map { [weak self] snapshot in
                snapshot.documents.compactMap { doc in
                    self?.mapDocumentToWorkout(doc, userId: userId)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getWorkoutById(_ workoutId: String) async throws -> Workout? {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        logger.info("📱 Getting workout by ID: \(workoutId)")
        
        let document = try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(workoutId)
            .getDocument()
        
        return mapDocumentToWorkout(document, userId: userId)
    }
    
    func createWorkout(_ workout: Workout) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        logger.info("📱 Creating workout: \(workout.name)")
        
        // Auto-assign color if not provided, similar to Android implementation
        let finalColorHex: String
        if let providedColor = workout.colorHex, !providedColor.isEmpty {
            finalColorHex = providedColor
        } else {
            let usedColors = try await getUsedColors(userId: userId)
            finalColorHex = getNextAvailableColor(usedColors: usedColors)
        }
        
        let workoutData: [String: Any] = [
            "id": workout.id,
            "name": workout.name,
            "userId": userId,
            "exercises": workout.exercises.map { workoutExercise in
                [
                    "id": workoutExercise.exercise.id,
                    "name": workoutExercise.exercise.name,
                    "equipment": workoutExercise.exercise.equipment,
                    "muscleGroup": workoutExercise.exercise.muscleGroup,
                    "defaultReps": workoutExercise.exercise.defaultReps,
                    "defaultSets": workoutExercise.exercise.defaultSets,
                    "isBodyweight": workoutExercise.exercise.isBodyweight,
                    "usesWeight": workoutExercise.exercise.usesWeight,
                    "tracksDistance": workoutExercise.exercise.tracksDistance,
                    "isTimeBased": workoutExercise.exercise.isTimeBased,
                    "description": workoutExercise.exercise.description
                ]
            },
            "colorHex": finalColorHex,
            "createdAt": Date().millisecondsSince1970,
            "updatedAt": Date().millisecondsSince1970
        ]
        
        try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(workout.id)
            .setData(workoutData)
        
        // Note: Workout history is recorded when a workout is completed, not when a routine is created
        
        logger.info("✅ Successfully created workout: \(workout.name)")
    }
    
    func updateWorkout(_ workout: Workout) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        logger.info("📱 Updating workout: \(workout.name)")
        
        // Prepare workout data for update - same structure as createWorkout
        let workoutData: [String: Any] = [
            "name": workout.name,
            "exercises": workout.exercises.map { workoutExercise in
                [
                    "id": workoutExercise.exercise.id,
                    "name": workoutExercise.exercise.name,
                    "equipment": workoutExercise.exercise.equipment,
                    "muscleGroup": workoutExercise.exercise.muscleGroup,
                    "defaultReps": workoutExercise.exercise.defaultReps,
                    "defaultSets": workoutExercise.exercise.defaultSets,
                    "isBodyweight": workoutExercise.exercise.isBodyweight,
                    "usesWeight": workoutExercise.exercise.usesWeight,
                    "tracksDistance": workoutExercise.exercise.tracksDistance,
                    "isTimeBased": workoutExercise.exercise.isTimeBased,
                    "description": workoutExercise.exercise.description
                ]
            },
            "colorHex": workout.colorHex ?? "#007AFF",
            "updatedAt": Date().millisecondsSince1970
        ]
        
        try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(workout.id)
            .updateData(workoutData)
        
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
            .updateData([
                "colorHex": colorHex,
                "updatedAt": Date().millisecondsSince1970
            ])
        
        logger.info("🎨 Updated workout color: \(workoutId) -> \(colorHex)")
    }
    
    func updateWorkoutLastPerformed(routineId: String, lastPerformed: Date) async throws {
        guard let userId = try await authRepository.getCurrentUser()?.id else {
            throw RepositoryError.userNotAuthenticated
        }
        
        try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .document(routineId)
            .updateData([
                "lastPerformed": lastPerformed.millisecondsSince1970,
                "updatedAt": Date().millisecondsSince1970
            ])
        
        logger.info("📅 Updated last performed: \(routineId)")
    }
    
    // MARK: - Statistics
    
    func getWorkoutCount(userId: String) async throws -> Int {
        let snapshot = try await firestore.collection("user_workouts")
            .document(userId)
            .collection("routines")
            .getDocuments()
        return snapshot.documents.count
    }
    
    func getCustomExerciseCount(userId: String) async throws -> Int {
        let snapshot = try await firestore.collection("exercises")
            .whereField("createdBy", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.count
    }
    
    // MARK: - Calendar and Suggestions
    
    func getWeeklyCalendar() -> AnyPublisher<[WeeklyCalendarDay], Error> {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        let weekDays = (0..<7).compactMap { (dayOffset: Int) -> WeeklyCalendarDay? in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { return nil }
            
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            let dayNumber = calendar.component(.day, from: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            
            return WeeklyCalendarDay(
                date: date,
                dayName: dayName,
                dayNumber: dayNumber,
                isToday: isToday,
                isSelected: false,
                hasWorkout: false
            )
        }
        
        return Just(weekDays)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func getSuggestedNextWorkout() -> AnyPublisher<Workout?, Error> {
        return Just(nil as Workout?)
            .setFailureType(to: Error.self)
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
        
        let finalId = exerciseMap["id"] as? String ?? name.toCamelId()
        
        if name.lowercased().contains("plank") {
            logger.debug("🔥 mapToExercise DEBUG for \(name):")
            for (key, value) in exerciseMap {
                logger.debug("  \(String(describing: key)): \(String(describing: value))")
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
            tracksDistance: exerciseMap["tracksDistance"] as? Bool ?? false,
            isTimeBased: exerciseMap["isTimeBased"] as? Bool ?? false,
            description: exerciseMap["description"] as? String ?? ""
        )
        
        logger.debug("🔥 Created exercise: \(exercise.name), isTimeBased: \(exercise.isTimeBased)")
        logger.debug("🔥 usesWeight: \(exercise.usesWeight), isBodyweight: \(exercise.isBodyweight)")
        logger.debug("🔥 tracksDistance: \(exercise.tracksDistance)")
        logger.debug("🔥 defaultReps: \(exercise.defaultReps), defaultSets: \(exercise.defaultSets)")
        logger.debug("🔥 equipment: \(exercise.equipment)")
        logger.debug("🔥 muscleGroup: \(exercise.muscleGroup)")
        
        return exercise
    }
    
    private func mapDocumentToWorkout(_ document: DocumentSnapshot, userId: String) -> Workout? {
        guard let data = document.data() else { return nil }
        
        
        let exercises = (data["exercises"] as? [[String: Any]] ?? []).compactMap { exerciseMap -> WorkoutExercise? in
            guard let name = exerciseMap["name"] as? String else { return nil }
            
            let exercise = Exercise(
                id: exerciseMap["id"] as? String ?? "",
                name: name,
                muscleGroup: exerciseMap["muscleGroup"] as? String ?? "",
                equipment: exerciseMap["equipment"] as? String ?? "",
                defaultReps: exerciseMap["defaultReps"] as? Int ?? 15,
                defaultSets: exerciseMap["defaultSets"] as? Int ?? 3,
                isBodyweight: exerciseMap["isBodyweight"] as? Bool ?? false,
                usesWeight: exerciseMap["usesWeight"] as? Bool ?? true,
                tracksDistance: exerciseMap["tracksDistance"] as? Bool ?? false,
                isTimeBased: exerciseMap["isTimeBased"] as? Bool ?? false,
                description: exerciseMap["description"] as? String ?? ""
            )
            
            // Create WorkoutExercise with empty sets (will be populated during workout)
            return WorkoutExercise(exercise: exercise, sets: [])
        }
        
        // Convert createdAt timestamp if available
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Double {
            createdAt = Date(timeIntervalSince1970: timestamp / 1000) // Convert from milliseconds
        } else {
            createdAt = Date() // Fallback to current date
        }
        
        return Workout(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            userId: userId,
            exercises: exercises,
            createdAt: createdAt,
            colorHex: data["colorHex"] as? String ?? "#007AFF"
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
        return "#007AFF" // Default blue color
    }
    
    // MARK: - Cleanup
    
    func onCleared() {
        globalListener?.remove()
        cancellables.removeAll()
        clearCache()
    }
    
    func clearCache() {
        logger.info("🧹 Clearing workout repository cache")
        exerciseCache.removeAll()
        lastCacheUpdate = Date.distantPast
    }
}

