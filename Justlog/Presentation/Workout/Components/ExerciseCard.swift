//
//  ExpandableExerciseItem.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import SwiftUI

struct ExerciseCard: View {
    @Environment(\.themeManager) private var themeManager
    @ObservedObject private var viewModel: WorkoutViewModel
    
    @FocusState private var focusedField: FocusableField?
    
    let workoutExercise: WorkoutExercise
    let weightUnit: WeightUnit
    let distanceUnit: DistanceUnit
    let exerciseIndex: Int
    let totalExercises: Int
    let isReorderMode: Bool
    let allSetsCompleted: Bool
    let isExpanded: Bool
    let onExpandedChange: (Bool) -> Void
    let onAddSet: () -> Void
    let onSetCompleted: (ExerciseSet, Bool) -> Void
    let onUpdateWeight: (ExerciseSet, Double) -> Void
    let onUpdateReps: (ExerciseSet, Int) -> Void
    let onUpdateDistance: (ExerciseSet, Double) -> Void
    let onUpdateTime: (ExerciseSet, Int) -> Void
    let onUpdateNotes: (String) -> Void
    let onDeleteSet: (WorkoutExercise, Int) -> Void
    let onArrangeExercise: (WorkoutExercise) -> Void
    let onReplaceExercise: (WorkoutExercise) -> Void
    let onAddToSuperset: (WorkoutExercise) -> Void
    let onToggleDropset: (WorkoutExercise) -> Void
    let onRemoveExercise: (WorkoutExercise) -> Void
    
    @State private var notes: String = ""
    @State private var showOptions = false
    
    private var isDarkTheme: Bool {
        switch themeManager?.currentTheme {
        case .dark:
            return true
        case .neutral, .light, .none:
            return false
        }
    }
    
    init(workoutExercise: WorkoutExercise, weightUnit: WeightUnit, distanceUnit: DistanceUnit, exerciseIndex: Int, totalExercises: Int, isReorderMode: Bool, allSetsCompleted: Bool, isExpanded: Bool, viewModel: WorkoutViewModel, onExpandedChange: @escaping (Bool) -> Void, onAddSet: @escaping () -> Void, onSetCompleted: @escaping (ExerciseSet, Bool) -> Void, onUpdateWeight: @escaping (ExerciseSet, Double) -> Void, onUpdateReps: @escaping (ExerciseSet, Int) -> Void, onUpdateDistance: @escaping (ExerciseSet, Double) -> Void, onUpdateTime: @escaping (ExerciseSet, Int) -> Void, onUpdateNotes: @escaping (String) -> Void, onDeleteSet: @escaping (WorkoutExercise, Int) -> Void, onArrangeExercise: @escaping (WorkoutExercise) -> Void, onReplaceExercise: @escaping (WorkoutExercise) -> Void, onAddToSuperset: @escaping (WorkoutExercise) -> Void, onToggleDropset: @escaping (WorkoutExercise) -> Void, onRemoveExercise: @escaping (WorkoutExercise) -> Void) {
        self.workoutExercise = workoutExercise
        self.weightUnit = weightUnit
        self.distanceUnit = distanceUnit
        self.exerciseIndex = exerciseIndex
        self.totalExercises = totalExercises
        self.isReorderMode = isReorderMode
        self.allSetsCompleted = allSetsCompleted
        self.isExpanded = isExpanded
        self.onExpandedChange = onExpandedChange
        self.onAddSet = onAddSet
        self.onSetCompleted = onSetCompleted
        self.onUpdateWeight = onUpdateWeight
        self.onUpdateReps = onUpdateReps
        self.onUpdateDistance = onUpdateDistance
        self.onUpdateTime = onUpdateTime
        self.onUpdateNotes = onUpdateNotes
        self.onDeleteSet = onDeleteSet
        self.onArrangeExercise = onArrangeExercise
        self.onReplaceExercise = onReplaceExercise
        self.onAddToSuperset = onAddToSuperset
        self.onToggleDropset = onToggleDropset
        self.onRemoveExercise = onRemoveExercise
        self.viewModel = viewModel
        self._notes = State(initialValue: workoutExercise.notes)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise header with icon, name, completion count, and controls
            exerciseHeaderView
                .padding(.horizontal, 0)
                .padding(.vertical, 16)
                .background(backgroundColor)
            
            // Expandable content (only show when expanded and not in reorder mode)
            if isExpanded && !isReorderMode {
                expandableContentView
                    .padding(.bottom, 16)
            }
        }
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
        )
        .cornerRadius(12)
        .onAppear {
            notes = workoutExercise.notes
        }
        .sheet(isPresented: $showOptions) {
            ExerciseOptionsBottomSheet(
                exerciseName: workoutExercise.exercise.name,
                isSuperset: workoutExercise.isSuperset,
                isDropset: workoutExercise.isDropset,
                onReArrange: { onArrangeExercise(workoutExercise) },
                onReplace: { onReplaceExercise(workoutExercise) },
                onToggleSuperset: { onAddToSuperset(workoutExercise) },
                onToggleDropset: { onToggleDropset(workoutExercise) },
                onRemove: { onRemoveExercise(workoutExercise) }
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    handleKeyboardDoneButton()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        themeManager?.colors.surface ?? LightThemeColors.surface // Use surface color for cards
    }
    
    private var onSurfaceColor: Color {
        themeManager?.colors.onSurface ?? .primary
    }
    
    private var secondaryColor: Color {
        themeManager?.colors.onSurface.opacity(0.7) ?? .secondary
    }
    
    // MARK: - Sub Views
    
    private var expandableContentView: some View {
        VStack(spacing: 16) {
            // Notes field
            notesFieldView
                .padding(.horizontal, 4) // Further reduced for maximum width
            
            // Rest timer - LEFT ALIGNED
            HStack {
                restTimerView
                Spacer()
            }
            .padding(.horizontal, 4) // Further reduced for maximum width
            
            // Sets header and list
            setsContentView
        }
    }
    
    private var setsContentView: some View {
        VStack(spacing: 8) {
            setsHeaderView
                .padding(.horizontal, 4) // Further reduced for maximum width
            
            // Sets list
            setsListView
            
            // Add set button
            addSetButtonView
                .padding(.horizontal, 4) // Further reduced for maximum width
                .padding(.top, 8)
        }
    }
    
    private var setsListView: some View {
        VStack(spacing: 8) {
            let bestSetInSession = calculateBestSetInSession()
            let historicalBest = calculateHistoricalBest()
            
            ForEach(Array(workoutExercise.sets.enumerated()), id: \.offset) { setIndex, set in
                // Only show PR trophy if this is the best completed set in session AND it beats historical record
                let isSessionBestPR = bestSetInSession?.setNumber == set.setNumber &&
                                     set.isCompleted &&
                                     bestSetInSession != nil &&
                                     isNewPersonalRecord(set: bestSetInSession!, historicalBest: historicalBest)
                
                let _ = print("🏆 PR Check for \(workoutExercise.exercise.name) set \(set.setNumber): bestInSession=\(bestSetInSession?.setNumber ?? -1), completed=\(set.isCompleted), currentScore=\(calculateSetScore(set: set)), historicalBest=\(historicalBest), isPR=\(isSessionBestPR)")
                
                createSetRow(for: set, at: setIndex, isSessionBestPR: isSessionBestPR)
                    .padding(.horizontal, 0)
            }
        }
    }
    
    private func createSetRow(for set: ExerciseSet, at setIndex: Int, isSessionBestPR: Bool) -> some View {
        SetRowComponent(
            setNumber: set.setNumber,
            weightUnit: weightUnit,
            distanceUnit: distanceUnit,
            set: set,
            usesWeight: workoutExercise.exercise.usesWeight,
            tracksDistance: workoutExercise.exercise.tracksDistance,
            isTimeBased: workoutExercise.exercise.isTimeBased,
            isSessionBestPR: isSessionBestPR,
            focusedField: $focusedField,
            onCompleted: { isCompleted in
                handleSetCompletion(set: set, isCompleted: isCompleted, setIndex: setIndex)
            },
            onUpdateReps: { reps in onUpdateReps(set, reps) },
            onUpdateWeight: { weight in onUpdateWeight(set, weight) },
            onUpdateDistance: { distance in onUpdateDistance(set, distance) },
            onUpdateTime: { time in onUpdateTime(set, time) },
            onDelete: { onDeleteSet(workoutExercise, set.setNumber) },
            onFocusNext: {
                focusNextField(from: setIndex)
            }
        )
    }
    
    private var exerciseHeaderView: some View {
        HStack(spacing: 12) {
            // Muscle group icon
            muscleGroupIconView
            
            // Exercise name and labels
            VStack(alignment: .leading, spacing: 4) {
                // Exercise name - LEFT ALIGNED
                Text(workoutExercise.exercise.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(onSurfaceColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Superset and Dropset labels
                if workoutExercise.isSuperset || workoutExercise.isDropset {
                    VStack(alignment: .leading, spacing: 3) {
                        if workoutExercise.isSuperset {
                            Text("SUPERSET")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.orange)
                                )
                        }
                        
                        if workoutExercise.isDropset {
                            Text("DROPSET")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.green)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            if !isReorderMode {
                headerControlsView
            } else {
                reorderControlsView
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var muscleGroupIconView: some View {
        ZStack {
            Circle()
                .fill(themeManager?.colors.surface ?? Color(.systemBackground)) // Keep surface for icon background
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isDarkTheme ? Color.white : Color.black, lineWidth: 1)
                )
            
            Image(workoutExercise.exercise.muscleGroup.getMuscleGroupIcon(isDarkTheme: isDarkTheme))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        }
    }
    
    private var headerControlsView: some View {
        HStack(spacing: 12) {
            // Set completion count
            if !workoutExercise.sets.isEmpty {
                let completedSets = workoutExercise.sets.count { $0.isCompleted }
                Text("\(completedSets)/\(workoutExercise.sets.count)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(secondaryColor)
            }
            
            // Expand/collapse button
            Button(action: { onExpandedChange(!isExpanded) }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(secondaryColor)
            }
            
            // Options menu
            Button(action: { showOptions = true }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(secondaryColor)
                    .rotationEffect(.degrees(90))
            }
        }
    }
    
    private var reorderControlsView: some View {
        VStack(spacing: 4) {
            Button(action: {
                if exerciseIndex > 0 {
                    viewModel.reorderExercises(fromIndex: exerciseIndex, toIndex: exerciseIndex - 1)
                }
            }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(exerciseIndex > 0 ? .primary : .secondary)
            }
            .disabled(exerciseIndex <= 0)
            
            Button(action: {
                if exerciseIndex < totalExercises - 1 {
                    viewModel.reorderExercises(fromIndex: exerciseIndex, toIndex: exerciseIndex + 1)
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(exerciseIndex < totalExercises - 1 ? .primary : .secondary)
            }
            .disabled(exerciseIndex >= totalExercises - 1)
        }
    }
    
    private var notesFieldView: some View {
        HStack {
            TextField("Add notes here...", text: $notes)
                .font(.system(size: 16))
                .foregroundColor(secondaryColor)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: notes) { newNotes in
                    onUpdateNotes(newNotes)
                }
            Spacer()
        }
    }
    
    private var restTimerView: some View {
        // Only show if timer is running or paused
        if viewModel.isRestTimerRunning || viewModel.isRestTimerPaused {
            RestTimerButton(
                isRunning: viewModel.isRestTimerRunning,
                remainingTime: viewModel.restTimerRemaining,
                totalTime: viewModel.restTimerTotal,
                isPaused: viewModel.isRestTimerPaused,
                onStart: { duration in viewModel.startRestTimer(duration) },
                onStop: {
                    viewModel.stopRestTimer()
                    // Timer will disappear automatically since isRunning becomes false
                },
                onPauseResume: { viewModel.pauseResumeRestTimer() }
            )
        } else {
            // Show start timer button
            RestTimerButton(
                isRunning: false,
                remainingTime: 0,
                totalTime: 0,
                isPaused: false,
                onStart: { duration in viewModel.startRestTimer(duration) },
                onStop: { viewModel.stopRestTimer() },
                onPauseResume: { viewModel.pauseResumeRestTimer() }
            )
        }
    }
    
    private var setsHeaderView: some View {
        HStack(spacing: 6) { // Consistent spacing for perfect alignment
            // SET - match SetRowComponent setNumberView width
            Text("SET")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .center)
            
            // LAST - match SetRowComponent previousPerformanceView width
            Text("LAST")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .center)
            
            // BEST - match SetRowComponent bestPerformanceView width
            Text("BEST")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .center)
            
            // Dynamic headers based on exercise type - match SetRowComponent inputFieldsView width
            dynamicHeadersView
                .frame(maxWidth: 165) // Updated to match adjusted input field area
            
            // Checkbox column space - match SetRowComponent completionCheckboxView width
            Spacer().frame(width: 24)
        }
        .padding(.horizontal, 12) // Increased to match set row padding for perfect alignment
    }
    
    private var dynamicHeadersView: some View {
        // Calculate field layout to match SetRowComponent exactly
        let showWeightField = workoutExercise.exercise.usesWeight
        let showDistanceField = workoutExercise.exercise.tracksDistance
        let showTimeField = workoutExercise.exercise.isTimeBased
        let showRepsField = !workoutExercise.exercise.isTimeBased
        
        var inputFieldCount = 0
        if showWeightField { inputFieldCount += 1 }
        if showDistanceField { inputFieldCount += 1 }
        if showTimeField { inputFieldCount += 1 }
        if showRepsField { inputFieldCount += 1 }
        
        let availableWidth: CGFloat = 157 // Match SetRowComponent
        let fieldSpacing: CGFloat = 6 // Match SetRowComponent
        let totalSpacing = fieldSpacing * CGFloat(max(0, inputFieldCount - 1))
        let baseFieldWidth = (availableWidth - totalSpacing) / CGFloat(max(1, inputFieldCount))
        
        let timeFieldWidth: CGFloat = inputFieldCount == 1 ? 80 : 65
        let standardFieldWidth: CGFloat = (showTimeField && inputFieldCount > 1) ?
            (availableWidth - timeFieldWidth - totalSpacing) / CGFloat(max(1, inputFieldCount - 1)) :
            baseFieldWidth
        
        return HStack(spacing: fieldSpacing) { // Match exact field spacing
            if showWeightField {
                Text(weightUnit == .kg ? "KG" : "LB")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: standardFieldWidth, alignment: .center)
            }
            
            if showDistanceField {
                Text(distanceUnit == .km ? "KM" : "MI")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: standardFieldWidth, alignment: .center)
            }
            
            if showTimeField {
                Text("TIME")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: timeFieldWidth, alignment: .center)
            }
            
            if showRepsField {
                Text("REPS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: standardFieldWidth, alignment: .center)
            }
        }
    }
    
    private var addSetButtonView: some View {
        Button(action: onAddSet) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Add Set")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(onSurfaceColor)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager?.colors.surface ?? Color(.systemBackground)) // Keep surface for button background
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDarkTheme ? Color.white : Color.black, lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleKeyboardDoneButton() {
        // Find the currently focused field
        guard let currentFocusedField = focusedField else { return }
        
        var currentSetIndex: Int? = nil
        var currentSet: ExerciseSet? = nil
        var nextFieldInSameSet: FocusableField? = nil
        
        // Find which set the current field belongs to
        for setIndex in workoutExercise.sets.indices {
            let set = workoutExercise.sets[setIndex]
            
            let fieldsInOrder: [FocusableField] = [
                workoutExercise.exercise.usesWeight ? .weight(set.setNumber) : nil,
                workoutExercise.exercise.tracksDistance ? .distance(set.setNumber) : nil,
                workoutExercise.exercise.isTimeBased ? .time(set.setNumber) : nil,
                !workoutExercise.exercise.isTimeBased ? .reps(set.setNumber) : nil
            ].compactMap { $0 }
            
            // Check if current field belongs to this set
            if let currentFieldIndex = fieldsInOrder.firstIndex(of: currentFocusedField) {
                currentSetIndex = setIndex
                currentSet = set
                
                // Check if there's a next field in the same set
                let nextIndex = currentFieldIndex + 1
                if nextIndex < fieldsInOrder.count {
                    nextFieldInSameSet = fieldsInOrder[nextIndex]
                }
                break
            }
        }
        
        if let nextField = nextFieldInSameSet {
            // Move to next field in the same set
            focusedField = nextField
        } else if let set = currentSet {
            // No more fields in current set - complete it and dismiss keyboard
            if !set.isCompleted {
                onSetCompleted(set, true)
            }
            // Dismiss keyboard - user needs to manually tap next set
            focusedField = nil
        } else {
            // Fallback - just dismiss keyboard
            focusedField = nil
        }
    }
    
    private func handleSetCompletion(set: ExerciseSet, isCompleted: Bool, setIndex: Int) {
        onSetCompleted(set, isCompleted)
        if isCompleted && setIndex + 1 < workoutExercise.sets.count {
            // Request focus for the first input field of the next set
            focusNextField(from: setIndex)
        }
    }
    
    private func focusNextField(from setIndex: Int) {
        if setIndex + 1 < workoutExercise.sets.count {
            let nextSet = workoutExercise.sets[setIndex + 1]
            
            // Request focus for the first input field of the next set
            if workoutExercise.exercise.usesWeight {
                focusedField = .weight(nextSet.setNumber)
            } else if workoutExercise.exercise.tracksDistance {
                focusedField = .distance(nextSet.setNumber)
            } else if workoutExercise.exercise.isTimeBased {
                focusedField = .time(nextSet.setNumber)
            } else {
                focusedField = .reps(nextSet.setNumber)
            }
        }
    }
    
    private func calculateBestSetInSession() -> ExerciseSet? {
        guard !workoutExercise.sets.isEmpty else { return nil }
        
        return workoutExercise.sets.filter { set in
            set.isCompleted && hasValidData(set: set)
        }.max(by: { set1, set2 in
            calculateSetScore(set: set1) < calculateSetScore(set: set2)
        })
    }
    
    private func calculateHistoricalBest() -> Double {
        guard !workoutExercise.sets.isEmpty else { return 0.0 }
        
        var historicalBest: Double = 0.0
        
        // Find the best historical performance across all sets
        for set in workoutExercise.sets {
            let historicalScore: Double
            
            switch true {
            case workoutExercise.exercise.usesWeight:
                let prevWeight = set.previousWeight ?? 0.0
                let prevReps = set.previousReps ?? 0
                historicalScore = prevWeight > 0 && prevReps > 0 ? prevWeight * Double(prevReps) : 0.0
            case workoutExercise.exercise.tracksDistance:
                historicalScore = set.previousDistance ?? 0.0
            case workoutExercise.exercise.isTimeBased:
                historicalScore = Double(set.previousTime ?? 0)
            default:
                historicalScore = Double(set.previousReps ?? 0)
            }
            
            if historicalScore > historicalBest {
                historicalBest = historicalScore
            }
        }
        
        return historicalBest
    }
    
    private func hasValidData(set: ExerciseSet) -> Bool {
        switch true {
        case workoutExercise.exercise.usesWeight:
            return set.weight > 0 && set.reps > 0
        case workoutExercise.exercise.tracksDistance:
            return set.distance > 0
        case workoutExercise.exercise.isTimeBased:
            return set.time > 0
        default:
            return set.reps > 0
        }
    }
    
    private func calculateSetScore(set: ExerciseSet) -> Double {
        switch true {
        case workoutExercise.exercise.usesWeight:
            return set.weight * Double(set.reps)
        case workoutExercise.exercise.tracksDistance:
            return set.distance
        case workoutExercise.exercise.isTimeBased:
            return Double(set.time)
        default:
            return Double(set.reps)
        }
    }
    
    private func isNewPersonalRecord(set: ExerciseSet, historicalBest: Double) -> Bool {
        let currentScore = calculateSetScore(set: set)
        // PR if current score beats historical best (even if historical best is 0, first completion is a PR)
        return currentScore > historicalBest && currentScore > 0
    }
}
