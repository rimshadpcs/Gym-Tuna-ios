//
//  SetRowComponent.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import SwiftUI

// Define FocusableField enum outside the struct
enum FocusableField: Hashable {
    case weight(Int)
    case reps(Int)
    case distance(Int)
    case time(Int)
}

struct SetRowComponent: View {
    @Environment(\.themeManager) private var optionalThemeManager
    
    let setNumber: Int
    let weightUnit: WeightUnit
    let distanceUnit: DistanceUnit
    let set: ExerciseSet
    let usesWeight: Bool
    let tracksDistance: Bool
    let isTimeBased: Bool
    let isSessionBestPR: Bool
    var focusedField: FocusState<FocusableField?>.Binding
    let onCompleted: (Bool) -> Void
    let onUpdateReps: (Int) -> Void
    let onUpdateWeight: (Double) -> Void
    let onUpdateDistance: (Double) -> Void
    let onUpdateTime: (Int) -> Void
    let onDelete: () -> Void
    let onFocusNext: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var distanceText: String = ""
    @State private var timeText: String = ""
    @State private var isTimerRunning: Bool = false
    @State private var timerValue: Int = 0
    
    // Swipe-to-delete state
    @State private var dragOffset: CGFloat = 0
    @State private var isSwipeToDeleteActive: Bool = false
    @State private var showingDeleteHint: Bool = false
    
    private var themeManager: ThemeManager {
        optionalThemeManager ?? ThemeManager(userPreferences: UserPreferences.shared)
    }
    
    private var isDarkTheme: Bool {
        themeManager.currentTheme == .dark
    }
    
    // Focus state computed properties
    private var isWeightFocused: Bool {
        if case .weight(let setNum) = focusedField.wrappedValue {
            return setNum == setNumber
        }
        return false
    }
    
    private var isDistanceFocused: Bool {
        if case .distance(let setNum) = focusedField.wrappedValue {
            return setNum == setNumber
        }
        return false
    }
    
    private var isTimeFocused: Bool {
        if case .time(let setNum) = focusedField.wrappedValue {
            return setNum == setNumber
        }
        return false
    }
    
    private var isRepsFocused: Bool {
        if case .reps(let setNum) = focusedField.wrappedValue {
            return setNum == setNumber
        }
        return false
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Set number or trophy
            setNumberView
                .frame(width: 40, alignment: .center)
            
            // Previous performance
            previousPerformanceView
                .frame(width: 50, alignment: .center)
            
            // Best performance
            bestPerformanceView
                .frame(width: 50, alignment: .center)
            
            // Input fields - constrained width
            inputFieldsView
                .frame(maxWidth: 160) // Limit input fields width
            
            // Completion checkbox - fixed position
            completionCheckboxView
                .frame(width: 28, height: 28)
                .onAppear { print("🔲 Checkbox appeared for set \(setNumber), completed: \(set.isCompleted)") }
        }
        .padding(.horizontal, 24)
        .frame(height: 56)
        .background(backgroundColorForRow)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(rowBorderColor, lineWidth: isSessionBestPR ? 2 : 0)
        )
        .offset(x: dragOffset)
        .background(
            // Delete background that shows when swiping
            HStack {
                Spacer()
                if showingDeleteHint {
                    VStack {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .medium))
                        Text(dragOffset < -120 ? "Release to Delete" : "Swipe to Delete")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.trailing, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.red)
            .cornerRadius(8)
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.width
                    if translation < 0 {
                        dragOffset = max(translation, -200)
                        showingDeleteHint = dragOffset < -40
                    }
                }
                .onEnded { value in
                    let translation = value.translation.width
                    if translation < -120 {
                        // Delete threshold reached (70% of 200)
                        withAnimation(.easeOut(duration: 0.3)) {
                            dragOffset = -300
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDelete()
                        }
                    } else {
                        // Snap back
                        withAnimation(.easeOut(duration: 0.3)) {
                            dragOffset = 0
                            showingDeleteHint = false
                        }
                    }
                }
        )
        .clipped()
        .onAppear {
            updateTextFields()
        }
        .onChange(of: set) { _ in
            // Only update if no field is focused to prevent value disappearance
            if !isWeightFocused && !isDistanceFocused && !isTimeFocused && !isRepsFocused {
                updateTextFields()
            }
        }
    }
    
    // MARK: - Sub Views
    
    private var setNumberView: some View {
        ZStack {
            if isSessionBestPR {
                Text("🏆")
                    .font(.system(size: 20))
            } else {
                Text("\(setNumber)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSessionBestPR ? Color(hex: "#FFD700") ?? .yellow : themeManager.colors.onSurface)
            }
        }
    }
    
    private var previousPerformanceView: some View {
        VStack(spacing: 1) {
            let prevText = buildPreviousDisplayString()
            Text(prevText)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(themeManager.colors.onSurface.opacity(0.6))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
    
    private var bestPerformanceView: some View {
        VStack(spacing: 1) {
            let bestText = buildBestDisplayString()
            Text(bestText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.colors.onSurface)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
    
    private var inputFieldsView: some View {
        let showWeightField = usesWeight
        let showDistanceField = tracksDistance
        let showTimeField = isTimeBased
        let showRepsField = !isTimeBased
        
        // Calculate dynamic widths
        var inputFieldCount = 0
        if showWeightField { inputFieldCount += 1 }
        if showDistanceField { inputFieldCount += 1 }
        if showTimeField { inputFieldCount += 1 }
        if showRepsField { inputFieldCount += 1 }
        
        let availableWidth: CGFloat = 150 // Reduced from 200 to fit screen
        let fieldSpacing: CGFloat = 2 // Reduced spacing
        let totalSpacing = fieldSpacing * CGFloat(max(0, inputFieldCount - 1))
        let baseFieldWidth = (availableWidth - totalSpacing) / CGFloat(max(1, inputFieldCount))
        
        let timeFieldWidth: CGFloat = inputFieldCount == 1 ? 80 : 60 // Reduced width
        let standardFieldWidth: CGFloat = (showTimeField && inputFieldCount > 1) ?
            (availableWidth - timeFieldWidth - totalSpacing) / CGFloat(max(1, inputFieldCount - 1)) :
            baseFieldWidth
            
        return HStack(spacing: 2) { // Reduced spacing between input fields
            if showWeightField {
                TextField((weightUnit == .kg) ? "kg" : "lb", text: $weightText)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(themeManager.colors.onSurface)
                    .focused(focusedField, equals: FocusableField.weight(set.setNumber))
                    .submitLabel(.done)
                    .onChange(of: weightText) { newValue in
                        if newValue.isEmpty || isValidDecimalInput(newValue) {
                            if let value = Double(newValue) {
                                let kgValue = (weightUnit == .kg) ? value : WeightConverter.lbsToKg(value)
                                onUpdateWeight(kgValue)
                            } else {
                                onUpdateWeight(0.0)
                            }
                        } else {
                            weightText = String(newValue.dropLast())
                        }
                    }
                    .onSubmit {
                        handleDonePressed()
                    }
                    .frame(width: standardFieldWidth, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(inputBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(inputBorderColor, lineWidth: 1)
                            )
                    )
            }
            
            if showDistanceField {
                TextField((distanceUnit == .km) ? "km" : "mi", text: $distanceText)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(themeManager.colors.onSurface)
                    .focused(focusedField, equals: FocusableField.distance(set.setNumber))
                    .submitLabel(.done)
                    .onChange(of: distanceText) { newValue in
                        if newValue.isEmpty || isValidDecimalInput(newValue) {
                            if let value = Double(newValue) {
                                let kmValue = (distanceUnit == .km) ? value : DistanceConverter.milesToKm(value)
                                onUpdateDistance(kmValue)
                            } else {
                                onUpdateDistance(0.0)
                            }
                        } else {
                            distanceText = String(newValue.dropLast())
                        }
                    }
                    .onSubmit {
                        handleDonePressed()
                    }
                    .frame(width: standardFieldWidth, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(inputBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(inputBorderColor, lineWidth: 1)
                            )
                    )
            }
            
            if showTimeField {
                TimeInputField(
                    time: $timeText,
                    isTimerRunning: $isTimerRunning,
                    onStartStopTimer: {
                        if isTimerRunning {
                            isTimerRunning = false
                        } else {
                            timerValue = Int(timeText) ?? 0
                            isTimerRunning = true
                        }
                    },
                    onResetTimer: {
                        timerValue = 0
                        timeText = "0"
                        onUpdateTime(0)
                    },
                    previousTime: set.previousTime.map { Double($0) },
                    width: timeFieldWidth,
                    bgColor: inputBackgroundColor,
                    borderColor: inputBorderColor,
                    contentColor: actualContentColor,
                    placeholderColor: actualPlaceholderColor,
                    isDarkTheme: isDarkTheme
                )
            }
            
            if showRepsField {
                TextField("reps", text: $repsText)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(themeManager.colors.onSurface)
                    .focused(focusedField, equals: FocusableField.reps(set.setNumber))
                    .submitLabel(.done)
                    .onChange(of: repsText) { newValue in
                        if newValue.isEmpty || newValue.allSatisfy({ $0.isWholeNumber }) {
                            if let value = Int(newValue) {
                                onUpdateReps(value)
                            } else {
                                onUpdateReps(0)
                            }
                        } else {
                            repsText = String(newValue.dropLast())
                        }
                    }
                    .onSubmit {
                        handleDonePressed()
                    }
                    .frame(width: standardFieldWidth, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(inputBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(inputBorderColor, lineWidth: 1)
                            )
                    )
            }
        }
    }
    
    private var completionCheckboxView: some View {
        Checkbox(
            checked: set.isCompleted,
            onCheckedChange: { isChecked in
                onCompleted(isChecked)
                if isChecked {
                    // Auto-focus next set's first input field
                    onFocusNext()
                }
            },
            uncheckedColor: themeManager.colors.outline,
            checkmarkColor: .white,
            isDarkTheme: isDarkTheme
        )
        .frame(width: 28, height: 28)
    }
    
    // MARK: - Helper Methods
    
    private func handleDonePressed() {
        // Find current focused field and move to next field in same row
        guard let currentField = focusedField.wrappedValue else { 
            // No field focused, dismiss keyboard
            focusedField.wrappedValue = nil
            return 
        }
        
        // Get all available fields for this set in order
        let fieldsInOrder: [FocusableField] = [
            usesWeight ? FocusableField.weight(set.setNumber) : nil,
            tracksDistance ? FocusableField.distance(set.setNumber) : nil,
            isTimeBased ? FocusableField.time(set.setNumber) : nil,
            !isTimeBased ? FocusableField.reps(set.setNumber) : nil
        ].compactMap { $0 }
        
        // Find current field index
        guard let currentIndex = fieldsInOrder.firstIndex(of: currentField) else {
            // Current field not found, dismiss keyboard
            focusedField.wrappedValue = nil
            return
        }
        
        // Check if there's a next field in the same row
        let nextIndex = currentIndex + 1
        if nextIndex < fieldsInOrder.count {
            // Move to next field in same row
            focusedField.wrappedValue = fieldsInOrder[nextIndex]
        } else {
            // No more fields in this row - complete the set and dismiss keyboard
            if !set.isCompleted {
                onCompleted(true)
                if isTimeBased && isTimerRunning {
                    isTimerRunning = false
                }
            }
            focusedField.wrappedValue = nil
        }
    }
    
    private func focusNext(currentIndex: Int) {
        // Determine the next focus state based on the current index and available fields
        var nextIndexInRow = currentIndex + 1
        
        // Helper to get the next FocusableField case
        func getNextFocusableField(for index: Int) -> FocusableField? {
            let fields: [(Bool, (Int) -> FocusableField)] = [
                (usesWeight, FocusableField.weight),
                (tracksDistance, FocusableField.distance),
                (isTimeBased, FocusableField.time),
                (!isTimeBased, FocusableField.reps)
            ]
            
            var currentField = 0
            for (shouldShow, fieldConstructor) in fields {
                if shouldShow {
                    if currentField == index {
                        return fieldConstructor(set.setNumber)
                    }
                    currentField += 1
                }
            }
            return nil
        }
        
        // Try to focus the next field in the current row
        if let nextField = getNextFocusableField(for: nextIndexInRow) {
            focusedField.wrappedValue = nextField
            return // Successfully moved focus to next field in current row
        }
        
        // If no more fields in this row, auto-complete and move to next set
        if !set.isCompleted {
            onCompleted(true)
            if isTimeBased && isTimerRunning {
                isTimerRunning = false
            }
        }
        onFocusNext() // Move to next set's first input field
    }
    
    private func formatNumber(_ number: Double) -> String {
        if number == number.rounded() {
            return String(format: "%.0f", number)
        } else {
            return String(format: "%.2f", number)
        }
    }
    
    private func updateTextFields() {
        weightText = {
            if set.weight > 0 {
                let displayWeight = (weightUnit == .kg) ? set.weight : WeightConverter.kgToLbs(set.weight)
                return formatNumber(displayWeight)
            } else if let prevWeight = set.previousWeight, prevWeight > 0 {
                let displayWeight = (weightUnit == .kg) ? prevWeight : WeightConverter.kgToLbs(prevWeight)
                return formatNumber(displayWeight)
            }
            else {
                return ""
            }
        }()
        
        repsText = {
            if set.reps > 0 {
                return String(set.reps)
            } else if let prevReps = set.previousReps, prevReps > 0 {
                return String(prevReps)
            }
            else {
                return ""
            }
        }()
        
        distanceText = {
            if set.distance > 0 {
                let displayDistance = (distanceUnit == .km) ? set.distance : DistanceConverter.kmToMiles(set.distance)
                return String(format: "%.1f", displayDistance)
            } else if let prevDistance = set.previousDistance, prevDistance > 0 {
                let displayDistance = (distanceUnit == .km) ? prevDistance : DistanceConverter.kmToMiles(prevDistance)
                return String(format: "%.1f", displayDistance)
            }
            else {
                return ""
            }
        }()
        
        timeText = {
            if set.time > 0 {
                return String(set.time)
            } else if let prevTime = set.previousTime, prevTime > 0 {
                return String(prevTime)
            }
            else {
                return ""
            }
        }()
        
        timerValue = set.time
    }
    
    private func buildPreviousDisplayString() -> String {
        return buildDisplayString(
            weight: set.previousWeight,
            reps: set.previousReps,
            distance: set.previousDistance,
            time: set.previousTime.map { Double($0) }, // Cast Int? to Double?
            weightUnit: weightUnit,
            distanceUnit: distanceUnit
        )
    }
    
    private func buildBestDisplayString() -> String {
        return buildDisplayString(
            weight: set.bestWeight,
            reps: set.bestReps,
            distance: set.bestDistance,
            time: set.bestTime.map { Double($0) }, // Cast Int? to Double?
            weightUnit: weightUnit,
            distanceUnit: distanceUnit
        )
    }
    
    private var isValidDecimalInput: (String) -> Bool {
        return { input in
            return input.isEmpty ||
                   (input.allSatisfy { $0.isNumber || $0 == "." } && input.filter { $0 == "." }.count <= 1)
        }
    }
    
    // MARK: - Computed Properties for Colors and Styling
    
    private var actualContentColor: Color {
        themeManager.colors.onSurface
    }
    
    private var actualPlaceholderColor: Color {
        actualContentColor.opacity(0.6)
    }
    
    private var backgroundColorForRow: Color {
        if set.isCompleted {
            return isDarkTheme ? Color(red: 46/255, green: 255/255, blue: 66/255, opacity: 1.0) : Color(red: 27/255, green: 225/255, blue: 45/255, opacity: 1.0)
        } else if isSessionBestPR {
            return Color(hex: "FFD700")?.opacity(0.1) ?? Color.yellow.opacity(0.1)
        } else {
            return isDarkTheme ? Color(hex: "212121") ?? themeManager.colors.surface : themeManager.colors.surface
        }
    }
    
    private var rowBorderColor: Color {
        if isSessionBestPR {
            return Color(hex: "#FFD700") ?? .yellow
        } else {
            return Color.clear
        }
    }
    
    private var inputBackgroundColor: Color {
        if set.isCompleted {
            return Color.clear
        } else if isDarkTheme {
            return Color(hex: "2C2C2C") ?? themeManager.colors.surface
        } else {
            return themeManager.colors.surface
        }
    }
    
    private var inputBorderColor: Color {
        if set.isCompleted {
            return Color.clear
        } else if isDarkTheme {
            return Color.white.opacity(0.3)
        } else {
            return themeManager.colors.outline.opacity(0.3)
        }
    }
}

// MARK: - Helper function to build display strings
func buildDisplayString(
    weight: Double?,
    reps: Int?,
    distance: Double?,
    time: Double?,
    weightUnit: WeightUnit,
    distanceUnit: DistanceUnit
) -> String {
    var components: [String] = []
    
    if let weight = weight, weight > 0 {
        let displayWeight = (weightUnit == .kg) ? weight : WeightConverter.kgToLbs(weight)
        let weightStr = String(format: displayWeight == displayWeight.rounded() ? "%.0f" : "%.1f", displayWeight)
        components.append("\(weightStr)\(weightUnit == .kg ? "kg" : "lb")")
    }
    
    if let distance = distance, distance > 0 {
        let displayDistance = (distanceUnit == .km) ? distance : DistanceConverter.kmToMiles(distance)
        let distanceStr = String(format: "%.1f", displayDistance)
        components.append("\(distanceStr)\(distanceUnit == .km ? "km" : "mi")")
    }
    
    if let time = time, time > 0 {
        components.append(DistanceConverter.formatTime(Int(time)))
    }
    
    if let reps = reps, reps > 0 {
        components.append("\(reps)")
    }
    
    return components.isEmpty ? "--" : components.joined(separator: "\n")
}

// MARK: - Helper Structs

struct InputField: View {
    @Binding var value: String
    let onValueChange: (String) -> Void
    let placeholder: String
    let keyboardType: UIKeyboardType
    let width: CGFloat
    let bgColor: Color
    let borderColor: Color
    let contentColor: Color
    let placeholderColor: Color
    @FocusState var focusState: Bool
    let onDone: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(bgColor)
                .frame(width: width, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: 1)
                )
            
            TextField("", text: $value)
                .placeholder(when: value.isEmpty) {
                    Text(placeholder)
                        .font(.system(size: 12))
                        .foregroundColor(placeholderColor)
                }
                .keyboardType(keyboardType)
                .multilineTextAlignment(.center)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(contentColor)
                .frame(width: width - 8, height: 32) // Inner padding
                .focused($focusState)
                .submitLabel(.done)
                .onSubmit {
                    onDone()
                }
        }
    }
}

struct TimeInputField: View {
    @Binding var time: String
    @Binding var isTimerRunning: Bool
    let onStartStopTimer: () -> Void
    let onResetTimer: () -> Void
    let previousTime: Double?
    let width: CGFloat
    let bgColor: Color
    let borderColor: Color
    let contentColor: Color
    let placeholderColor: Color
    let isDarkTheme: Bool
    
    @Environment(\.themeManager) private var optionalThemeManager
    
    private var themeManager: ThemeManager {
        optionalThemeManager ?? ThemeManager(userPreferences: UserPreferences.shared)
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(bgColor)
                    .frame(width: width * 0.65, height: 32) // Adjust width for timer display
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isTimerRunning ? themeManager.colors.primary : borderColor, lineWidth: 1)
                    )
                
                Text(formattedTime)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isTimerRunning ? themeManager.colors.primary : contentColor)
                    .multilineTextAlignment(.center)
            }
            .frame(width: width * 0.65, height: 32)
            
            // Timer controls
            HStack(spacing: 0) {
                Button(action: onStartStopTimer) {
                    Image(isTimerRunning ? (isDarkTheme ? "stop_dark" : "stop") : (isDarkTheme ? "play_dark" : "play"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
                .frame(width: 24, height: 24)
                
                if !isTimerRunning && (Int(time) ?? 0) > 0 {
                    Button(action: onResetTimer) {
                        Image(isDarkTheme ? "reset_dark" : "reset")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                    }
                    .frame(width: 24, height: 24)
                }
            }
        }
        .frame(width: width, height: 32)
    }
    
    private var formattedTime: String {
        let seconds = Int(time) ?? 0
        if seconds == 0 && previousTime != nil {
            return DistanceConverter.formatTime(Int(previousTime!))
        } else if seconds == 0 {
            return "--:--"
        }
        return DistanceConverter.formatTime(seconds)
    }
}

struct Checkbox: View {
    let checked: Bool
    let onCheckedChange: (Bool) -> Void
    let uncheckedColor: Color
    let checkmarkColor: Color
    let isDarkTheme: Bool
    
    var body: some View {
        Button(action: {
            print("🔲 Checkbox tapped! Current state: \(checked), will change to: \(!checked)")
            onCheckedChange(!checked)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(checked ? Color.black : uncheckedColor, lineWidth: 2)
                    .background(checked ? Color.black : Color.clear)
                    .cornerRadius(4)
                
                if checked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear { print("🔲 Checkbox component rendered - checked: \(checked)") }
    }
}

// Helper for TextField placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}

// MARK: - Extensions (for compilation)
extension String {
    func cleanDecimalString() -> String {
        if let number = Double(self) {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: number)) ?? self
        }
        return self
    }
}
