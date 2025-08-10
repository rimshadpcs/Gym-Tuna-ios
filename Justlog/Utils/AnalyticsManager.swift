import Foundation
import FirebaseAnalytics

class AnalyticsManager {
    
    static let shared = AnalyticsManager()
    private init() {}
    
    // MARK: - Authentication Events
    
    func logUserSignUp(method: String = "email") {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    func logUserLogin(method: String = "email") {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    // MARK: - Workout Events
    
    func logWorkoutStarted(
        isRoutineBased: Bool,
        routineName: String? = nil,
        exerciseCount: Int = 0
    ) {
        var parameters: [String: Any] = [
            "is_routine_based": isRoutineBased,
            "exercise_count": exerciseCount
        ]
        
        if let routineName = routineName {
            parameters["routine_name"] = routineName
        }
        
        Analytics.logEvent("workout_started", parameters: parameters)
    }
    
    func logWorkoutCompleted(
        workoutDurationMinutes: Int,
        totalSets: Int,
        totalExercises: Int,
        isRoutineBased: Bool,
        totalVolume: Double,
        weightUnit: String
    ) {
        Analytics.logEvent("workout_completed", parameters: [
            "workout_duration_minutes": workoutDurationMinutes,
            "total_sets": totalSets,
            "total_exercises": totalExercises,
            "is_routine_based": isRoutineBased,
            "total_volume": totalVolume,
            "weight_unit": weightUnit
        ])
    }
    
    func logWorkoutAbandoned(
        workoutDurationMinutes: Int,
        completedSets: Int,
        totalPlannedSets: Int,
        isRoutineBased: Bool
    ) {
        let completionPercentage = totalPlannedSets > 0 ? (Double(completedSets) / Double(totalPlannedSets) * 100) : 0
        
        Analytics.logEvent("workout_abandoned", parameters: [
            "workout_duration_minutes": workoutDurationMinutes,
            "completed_sets": completedSets,
            "total_planned_sets": totalPlannedSets,
            "is_routine_based": isRoutineBased,
            "completion_percentage": Int(completionPercentage)
        ])
    }
    
    func logQuickWorkoutCreated() {
        Analytics.logEvent("quick_workout_created", parameters: [:])
    }
    
    func logRoutineWorkoutStarted(routineName: String, exerciseCount: Int) {
        Analytics.logEvent("routine_workout_started", parameters: [
            "routine_name": routineName,
            "exercise_count": exerciseCount
        ])
    }
    
    // MARK: - Exercise & Routine Management Events
    
    func logExerciseAdded(exerciseName: String, muscleGroup: String) {
        Analytics.logEvent("exercise_added", parameters: [
            "exercise_name": exerciseName,
            "muscle_group": muscleGroup
        ])
    }
    
    func logRoutineCreated(routineName: String, exerciseCount: Int) {
        Analytics.logEvent("routine_created", parameters: [
            "routine_name": routineName,
            "exercise_count": exerciseCount
        ])
    }
    
    func logRoutineDeleted(routineName: String) {
        Analytics.logEvent("routine_deleted", parameters: [
            "routine_name": routineName
        ])
    }
    
    func logExerciseReplaced(oldExercise: String, newExercise: String) {
        Analytics.logEvent("exercise_replaced", parameters: [
            "old_exercise": oldExercise,
            "new_exercise": newExercise
        ])
    }
    
    func logExerciseCreated(exerciseName: String, muscleGroup: String, exerciseType: String) {
        Analytics.logEvent("custom_exercise_created", parameters: [
            "exercise_name": exerciseName,
            "muscle_group": muscleGroup,
            "exercise_type": exerciseType // "weight", "time", "distance", "bodyweight"
        ])
    }
    
    // MARK: - Premium Features Events
    
    func logSubscriptionViewed(source: String = "unknown") {
        Analytics.logEvent("subscription_viewed", parameters: [
            "source": source // "routine_limit", "settings", "workout_finish", etc.
        ])
    }
    
    func logSubscriptionPurchased(productId: String) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterItemName: "Premium Subscription",
            AnalyticsParameterItemCategory: "subscription"
        ])
    }
    
    func logPremiumFeatureUsed(featureName: String) {
        Analytics.logEvent("premium_feature_used", parameters: [
            "feature_name": featureName
        ])
    }
    
    // MARK: - Settings & Preferences Events
    
    func logThemeChanged(newTheme: String) {
        Analytics.logEvent("theme_changed", parameters: [
            "new_theme": newTheme // "light", "dark", "neutral"
        ])
    }
    
    func logUnitsChanged(unitType: String, newUnit: String) {
        Analytics.logEvent("units_changed", parameters: [
            "unit_type": unitType, // "weight" or "distance"
            "new_unit": newUnit // "kg", "lbs", "km", "miles"
        ])
    }
    
    func logSettingsAccessed() {
        Analytics.logEvent("settings_accessed", parameters: [:])
    }
    
    // MARK: - Navigation & Engagement Events
    
    func logScreenView(screenName: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName
        ])
    }
    
    func logOnboardingCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: [:])
    }
    
    // MARK: - History & Progress Events
    
    func logHistoryViewed() {
        Analytics.logEvent("history_viewed", parameters: [:])
    }
    
    func logWorkoutDetailViewed(workoutId: String) {
        Analytics.logEvent("workout_detail_viewed", parameters: [
            "workout_id": workoutId
        ])
    }
    
    // MARK: - Error Events
    
    func logError(errorType: String, errorMessage: String, screenName: String) {
        Analytics.logEvent("app_error", parameters: [
            "error_type": errorType,
            "error_message": errorMessage,
            "screen_name": screenName
        ])
    }
    
    // MARK: - Counter Events
    
    func logCounterUsed(counterName: String) {
        Analytics.logEvent("counter_used", parameters: [
            "counter_name": counterName
        ])
    }
    
    // MARK: - User Properties
    
    func setUserProperties(
        isPremium: Bool,
        preferredTheme: String,
        preferredWeightUnit: String,
        preferredDistanceUnit: String
    ) {
        Analytics.setUserProperty(isPremium.description, forName: "is_premium")
        Analytics.setUserProperty(preferredTheme, forName: "preferred_theme")
        Analytics.setUserProperty(preferredWeightUnit, forName: "preferred_weight_unit")
        Analytics.setUserProperty(preferredDistanceUnit, forName: "preferred_distance_unit")
    }
    
    func setUserId(_ userId: String) {
        Analytics.setUserID(userId)
    }
}