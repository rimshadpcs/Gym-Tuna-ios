//
//  SetRowComponent.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 06/08/2025.
//

import SwiftUI

struct SetRowComponent: View {
    @Environment(\.themeManager) private var themeManager
    
    let setNumber: Int
    let weightUnit: WeightUnit
    let distanceUnit: DistanceUnit
    let set: ExerciseSet
    let usesWeight: Bool
    let tracksDistance: Bool
    let isTimeBased: Bool
    let isSessionBestPR: Bool
    let firstInputFocusRequester: FocusRequester?
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
    
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    @FocusState private var isDistanceFocused: Bool
    @FocusState private var isTimeFocused: Bool
    
    // Field visibility (matching Android logic exactly)
    private var showWeightField: Bool { usesWeight }
    private var showDistanceField: Bool { tracksDistance }
    private var showTimeField: Bool { isTimeBased }
    private var showRepsField: Bool { !isTimeBased }
    
    var body: some View {
        HStack(spacing: 8) {
            setNumberView
            previousPerformanceView
            bestPerformanceView
            Spacer(minLength: 8)
            inputFieldsView
            Spacer(minLength: 8)
            completeButtonView
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(backgroundView)
        .onAppear { updateTextFields() }
        .onChange(of: set) { _ in updateTextFields() }
        .onTapGesture { handleTapGesture() }
    }
    
    // MARK: - Sub Views
    
    private var setNumberView: some View {
        Text("\(setNumber)")
            .vagFont(size: 14, weight: .medium)
            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            .frame(width: 32)
    }
    
    private var previousPerformanceView: some View {
        VStack(spacing: 2) {
            if let prevWeight = set.previousWeight, let prevReps = set.previousReps, prevWeight > 0 || prevReps > 0 {
                let displayString = buildDisplayString(
                    weight: prevWeight > 0 ? prevWeight : nil,
                    reps: prevReps > 0 ? prevReps : nil,
                    distance: set.previousDistance,
                    time: set.previousTime,
                    weightUnit: weightUnit,
                    distanceUnit: distanceUnit,
                    showUnits: false
                )
                Text(displayString)
                    .vagFont(size: 10, weight: .regular)
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.6) ?? LightThemeColors.onSurface.opacity(0.6))
                    .lineLimit(1)
            } else {
                Text("-")
                    .vagFont(size: 10, weight: .regular)
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.6) ?? LightThemeColors.onSurface.opacity(0.6))
            }
        }
        .frame(width: 40)
    }
    
    private var bestPerformanceView: some View {
        VStack(spacing: 2) {
            if let bestWeight = set.bestWeight, let bestReps = set.bestReps, bestWeight > 0 || bestReps > 0 {
                let displayString = buildDisplayString(
                    weight: bestWeight > 0 ? bestWeight : nil,
                    reps: bestReps > 0 ? bestReps : nil,
                    distance: set.bestDistance,
                    time: set.bestTime,
                    weightUnit: weightUnit,
                    distanceUnit: distanceUnit,
                    showUnits: false
                )
                Text(displayString)
                    .vagFont(size: 10, weight: .regular)
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.6) ?? LightThemeColors.onSurface.opacity(0.6))
                    .lineLimit(1)
            } else {
                Text("-")
                    .vagFont(size: 10, weight: .regular)
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.6) ?? LightThemeColors.onSurface.opacity(0.6))
            }
        }
        .frame(width: 40)
    }
    
    private var inputFieldsView: some View {
        HStack(spacing: 4) {
            // Calculate field widths
            let inputFields = calculateInputFields()
            let widths = calculateFieldWidths(inputFieldCount: inputFields.count)
            
            if showWeightField {
                weightFieldView(width: widths.standard)
            }
            
            if showDistanceField {
                distanceFieldView(width: widths.standard)
            }
            
            if showTimeField {
                timeFieldView(width: widths.time)
            }
            
            if showRepsField {
                repsFieldView(width: widths.standard)
            }
        }
    }
    
    private var completeButtonView: some View {
        Button(action: {
            onCompleted(!set.isCompleted)
        }) {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(
                    set.isCompleted ?
                    (themeManager?.colors.primary ?? LightThemeColors.primary) :
                    (themeManager?.colors.onSurface.opacity(0.3) ?? LightThemeColors.onSurface.opacity(0.3))
                )
        }
        .frame(width: 28, height: 28)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColorForSet)
            .overlay(
                // PR indicator border
                isSessionBestPR ? 
                RoundedRectangle(cornerRadius: 8)
                    .stroke(themeManager?.colors.primary ?? LightThemeColors.primary, lineWidth: 2) :
                nil
            )
    }
    
    // MARK: - Individual Field Views
    
    private func weightFieldView(width: CGFloat) -> some View {
        FocusableNumericTextField(
            value: $weightText,
            placeholder: "0",
            keyboardType: .decimalPad,
            isFocused: $isWeightFocused
        )
        .frame(width: width)
        .onSubmit {
            if let weight = Double(weightText) {
                onUpdateWeight(weight)
            }
            moveToNextField(from: "weight")
        }
        .focused($isWeightFocused)
    }
    
    private func distanceFieldView(width: CGFloat) -> some View {
        FocusableNumericTextField(
            value: $distanceText,
            placeholder: "0",
            keyboardType: .decimalPad,
            isFocused: $isDistanceFocused
        )
        .frame(width: width)
        .onSubmit {
            if let distance = Double(distanceText) {
                onUpdateDistance(distance)
            }
            moveToNextField(from: "distance")
        }
        .focused($isDistanceFocused)
    }
    
    private func timeFieldView(width: CGFloat) -> some View {
        FocusableNumericTextField(
            value: $timeText,
            placeholder: "0",
            keyboardType: .numberPad,
            isFocused: $isTimeFocused
        )
        .frame(width: width)
        .onSubmit {
            if let time = Int(timeText) {
                onUpdateTime(time)
            }
            moveToNextField(from: "time")
        }
        .focused($isTimeFocused)
    }
    
    private func repsFieldView(width: CGFloat) -> some View {
        FocusableNumericTextField(
            value: $repsText,
            placeholder: "0",
            keyboardType: .numberPad,
            isFocused: $isRepsFocused
        )
        .frame(width: width)
        .onSubmit {
            if let reps = Int(repsText) {
                onUpdateReps(reps)
            }
            onFocusNext()
        }
        .focused($isRepsFocused)
    }
    
    // MARK: - Helper Methods
    
    private func calculateInputFields() -> [String] {
        var fields: [String] = []
        if showWeightField { fields.append("weight") }
        if showDistanceField { fields.append("distance") }
        if showTimeField { fields.append("time") }
        if showRepsField { fields.append("reps") }
        return fields
    }
    
    private func calculateFieldWidths(inputFieldCount: Int) -> (standard: CGFloat, time: CGFloat) {
        let timeFieldWidth: CGFloat = inputFieldCount == 1 ? 120 : 80
        let standardFieldWidth: CGFloat = showTimeField && inputFieldCount > 1 ? 
            (200 - timeFieldWidth - CGFloat(inputFieldCount - 1) * 4) / CGFloat(inputFieldCount - 1) :
            200 / CGFloat(inputFieldCount)
        
        return (standard: standardFieldWidth, time: timeFieldWidth)
    }
    
    private func moveToNextField(from currentField: String) {
        switch currentField {
        case "weight":
            if showDistanceField {
                isDistanceFocused = true
            } else if showTimeField {
                isTimeFocused = true
            } else if showRepsField {
                isRepsFocused = true
            } else {
                onFocusNext()
            }
        case "distance":
            if showTimeField {
                isTimeFocused = true
            } else if showRepsField {
                isRepsFocused = true
            } else {
                onFocusNext()
            }
        case "time":
            if showRepsField {
                isRepsFocused = true
            } else {
                onFocusNext()
            }
        default:
            onFocusNext()
        }
    }
    
    private func handleTapGesture() {
        if showWeightField {
            isWeightFocused = true
        } else if showDistanceField {
            isDistanceFocused = true
        } else if showTimeField {
            isTimeFocused = true
        } else if showRepsField {
            isRepsFocused = true
        }
    }
    
    private var backgroundColorForSet: Color {
        if isSessionBestPR {
            return (themeManager?.colors.primary.opacity(0.1) ?? LightThemeColors.primary.opacity(0.1))
        } else if set.isCompleted {
            return (themeManager?.colors.primary.opacity(0.05) ?? LightThemeColors.primary.opacity(0.05))
        } else {
            return Color.clear
        }
    }
    
    private func updateTextFields() {
        weightText = set.weight > 0 ? String(set.weight.formatWeight()) : ""
        repsText = set.reps > 0 ? String(set.reps) : ""
        distanceText = set.distance > 0 ? String(set.distance.removeTrailingZeros()) : ""
        timeText = set.time > 0 ? String(set.time) : ""
    }
    
    // MARK: - Display String Builder
    
    private func buildDisplayString(
        weight: Double?,
        reps: Int?,
        distance: Double?,
        time: Int?,
        weightUnit: WeightUnit,
        distanceUnit: DistanceUnit,
        showUnits: Bool
    ) -> String {
        if let weight = weight, let reps = reps, weight > 0, reps > 0 {
            let weightStr = String(weight.formatWeight())
            let unitStr = showUnits ? " \(weightUnit.rawValue)" : ""
            return "\(weightStr)\(unitStr) x \(reps)"
        } else if let distance = distance, distance > 0 {
            let distanceStr = String(distance.removeTrailingZeros())
            let unitStr = showUnits ? " \(distanceUnit.rawValue)" : ""
            return "\(distanceStr)\(unitStr)"
        } else if let time = time, time > 0 {
            return formatTimeDisplay(seconds: time)
        } else {
            return "-"
        }
    }
    
    private func formatTimeDisplay(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", remainingSeconds))"
        } else {
            return "\(remainingSeconds)s"
        }
    }
}

// Define FocusRequester for SwiftUI
struct FocusRequester {
    private let uuid = UUID()
    
    func requestFocus() {
        // Implementation for focus request
        // In SwiftUI, this would be handled by @FocusState
    }
}