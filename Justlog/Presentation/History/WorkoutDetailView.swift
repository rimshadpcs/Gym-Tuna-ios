import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutHistory
    let weightUnit: WeightUnit
    
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                (themeManager?.colors.background ?? LightThemeColors.background)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: MaterialSpacing.lg) {
                        // Workout Header
                        workoutHeader
                            .padding(.horizontal, MaterialSpacing.md)
                        
                        // Workout Stats
                        workoutStats
                            .padding(.horizontal, MaterialSpacing.md)
                        
                        // Exercises Section
                        exercisesSection
                            .padding(.horizontal, MaterialSpacing.md)
                    }
                    .padding(.vertical, MaterialSpacing.lg)
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                }
            }
        }
    }
    
    // MARK: - Workout Header
    private var workoutHeader: some View {
        VStack(spacing: MaterialSpacing.sm) {
            HStack {
                // Routine color indicator
                Circle()
                    .fill(routineColor.opacity(0.45))
                    .overlay(
                        Circle()
                            .stroke(routineColor, lineWidth: 1)
                    )
                    .frame(width: 16, height: 16)
                
                Text(workout.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                
                Spacer()
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    
                    Text(dateTimeText)
                        .font(.subheadline)
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                }
                
                Spacer()
                
                Text(durationText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            }
        }
        .padding(MaterialSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
        )
    }
    
    // MARK: - Workout Stats
    private var workoutStats: some View {
        HStack(spacing: MaterialSpacing.lg) {
            StatColumn(
                title: "Exercises",
                value: "\(workout.exercises.count)",
                icon: "star"
            )
            
            Divider()
                .frame(height: 40)
            
            StatColumn(
                title: "Sets",
                value: "\(workout.totalSets)",
                icon: nil
            )
            
            Divider()
                .frame(height: 40)
            
            StatColumn(
                title: "Volume",
                value: formatWeight(workout.totalVolume),
                icon: nil
            )
        }
        .padding(MaterialSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
        )
    }
    
    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: MaterialSpacing.md) {
            Text("Exercises")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                .padding(.horizontal, MaterialSpacing.md)
            
            ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                ExerciseDetailCard(
                    exercise: exercise,
                    exerciseNumber: index + 1,
                    weightUnit: weightUnit
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var routineColor: Color {
        Color(hex: workout.colorHex) ?? (themeManager?.colors.primary ?? LightThemeColors.primary)
    }
    
    private var dateTimeText: String {
        let startDate = workout.startTime
        let endDate = workout.endTime
        
        let calendar = Calendar.current
        let now = Date()
        let daysAgo = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: now)).day ?? 0
        
        let dayText: String
        switch daysAgo {
        case 0:
            dayText = "Today"
        case 1:
            dayText = "Yesterday"
        default:
            dayText = "\(daysAgo) days ago"
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let startTime = timeFormatter.string(from: startDate)
        let endTime = timeFormatter.string(from: endDate)
        
        return "\(dayText) | \(startTime) - \(endTime)"
    }
    
    private var durationText: String {
        let duration = Int(workout.endTime.timeIntervalSince(workout.startTime))
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatWeight(_ weightInKg: Double) -> String {
        let converted: Double
        let unitLabel: String
        
        switch weightUnit {
        case .kg:
            converted = weightInKg
            unitLabel = "kg"
        case .lb:
            converted = weightInKg * 2.20462
            unitLabel = "lb"
        }
        
        if converted == converted.rounded() {
            return "\(Int(converted.rounded())) \(unitLabel)"
        } else {
            return String(format: "%.1f", converted).replacingOccurrences(of: ".0", with: "") + " \(unitLabel)"
        }
    }
}

// MARK: - Stat Column
struct StatColumn: View {
    let title: String
    let value: String
    let icon: String?
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                }
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Exercise Detail Card
struct ExerciseDetailCard: View {
    let exercise: CompletedExercise
    let exerciseNumber: Int
    let weightUnit: WeightUnit
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: MaterialSpacing.md) {
            // Exercise Header
            HStack {
                Text("\(exerciseNumber). \(exercise.name)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                
                Spacer()
                
                Text(exercise.muscleGroup)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((themeManager?.colors.surfaceVariant ?? LightThemeColors.surfaceVariant).opacity(0.3))
                    )
            }
            
            // Sets Table Header
            HStack {
                Text("Set")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    .frame(width: 40, alignment: .leading)
                
                Text("Weight")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Reps")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, MaterialSpacing.sm)
            
            Divider()
                .background(themeManager?.colors.outline ?? LightThemeColors.outline)
            
            // Sets Data
            ForEach(exercise.sets, id: \.setNumber) { set in
                HStack {
                    Text("\(set.setNumber)")
                        .font(.body)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .frame(width: 40, alignment: .leading)
                    
                    Text(formatWeight(set.weight))
                        .font(.body)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("\(set.reps)")
                        .font(.body)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.horizontal, MaterialSpacing.sm)
            }
            
            // Exercise Notes (if any)
            if !exercise.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    
                    Text(exercise.notes)
                        .font(.body)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                }
                .padding(.top, MaterialSpacing.sm)
            }
        }
        .padding(MaterialSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
        )
    }
    
    private func formatWeight(_ weightInKg: Double) -> String {
        if weightInKg == 0 {
            return "Bodyweight"
        }
        
        let converted: Double
        let unitLabel: String
        
        switch weightUnit {
        case .kg:
            converted = weightInKg
            unitLabel = "kg"
        case .lb:
            converted = weightInKg * 2.20462
            unitLabel = "lb"
        }
        
        if converted == converted.rounded() {
            return "\(Int(converted.rounded())) \(unitLabel)"
        } else {
            return String(format: "%.1f", converted).replacingOccurrences(of: ".0", with: "") + " \(unitLabel)"
        }
    }
}