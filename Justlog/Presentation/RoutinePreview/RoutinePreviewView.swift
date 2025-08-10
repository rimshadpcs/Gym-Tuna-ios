import SwiftUI

struct RoutinePreviewView: View {
    @StateObject private var viewModel: RoutinePreviewViewModel
    @Environment(\.themeManager) private var themeManager
    
    let routineId: String
    let onBack: () -> Void
    let onStartWorkout: (String) -> Void
    
    init(
        routineId: String,
        workoutRepository: WorkoutRepository,
        onBack: @escaping () -> Void,
        onStartWorkout: @escaping (String) -> Void
    ) {
        self.routineId = routineId
        self.onBack = onBack
        self.onStartWorkout = onStartWorkout
        self._viewModel = StateObject(wrappedValue: RoutinePreviewViewModel(
            workoutRepository: workoutRepository
        ))
    }
    
    private var colors: ThemeColorScheme {
        themeManager?.colors ?? ThemeColorScheme(
            primary: LightThemeColors.primary,
            onPrimary: LightThemeColors.onPrimary,
            secondary: LightThemeColors.secondary,
            onSecondary: LightThemeColors.onSecondary,
            background: LightThemeColors.background,
            onBackground: LightThemeColors.onBackground,
            surface: LightThemeColors.surface,
            onSurface: LightThemeColors.onSurface,
            outline: LightThemeColors.outline,
            primaryContainer: LightThemeColors.primaryContainer,
            onPrimaryContainer: LightThemeColors.onPrimaryContainer,
            surfaceVariant: LightThemeColors.surfaceVariant,
            onSurfaceVariant: LightThemeColors.onSurfaceVariant,
            error: LightThemeColors.error,
            shadow: LightThemeColors.shadow
        )
    }
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, MaterialSpacing.lg)
                    .padding(.vertical, MaterialSpacing.lg)
                
                if viewModel.isLoading {
                    loadingView
                } else if let routine = viewModel.routine {
                    routineContentView(routine)
                } else {
                    errorView
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadRoutine(routineId)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .center, spacing: MaterialSpacing.md) {
            // Back button
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(colors.onBackground)
            }
            
            // Title and info
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.routine?.name ?? "Loading...")
                    .vagFont(size: 20, weight: .semibold)
                    .foregroundColor(colors.onBackground)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let routine = viewModel.routine {
                    Text("\(routine.exercises.count) exercises")
                        .font(MaterialTypography.body2)
                        .foregroundColor(colors.onBackground.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Routine color indicator
            if let routine = viewModel.routine,
               let colorHex = routine.colorHex,
               let routineColor = Color(hex: colorHex) {
                Circle()
                    .fill(routineColor.opacity(0.45))
                    .overlay(
                        Circle()
                            .stroke(routineColor, lineWidth: 1)
                    )
                    .frame(width: 16, height: 16)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.2)
                .tint(colors.primary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: MaterialSpacing.lg) {
            Spacer()
            
            VStack(spacing: MaterialSpacing.md) {
                Text("Routine not found")
                    .font(MaterialTypography.headline6)
                    .foregroundColor(colors.onBackground)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(MaterialTypography.body2)
                        .foregroundColor(colors.onBackground.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            
            Button("Go Back") {
                onBack()
            }
            .padding(.horizontal, MaterialSpacing.xl)
            .padding(.vertical, MaterialSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.primary)
            )
            .foregroundColor(colors.onPrimary)
            .font(MaterialTypography.button)
            
            Spacer()
        }
        .padding(.horizontal, MaterialSpacing.lg)
    }
    
    // MARK: - Routine Content View
    private func routineContentView(_ routine: Workout) -> some View {
        VStack(spacing: 0) {
            // Exercise list
            ScrollView {
                LazyVStack(spacing: MaterialSpacing.sm) {
                    // Section header
                    HStack {
                        Text("Exercises")
                            .font(MaterialTypography.subtitle1)
                            .vagFont(size: 16, weight: .semibold)
                            .foregroundColor(colors.onBackground)
                        
                        Spacer()
                    }
                    .padding(.horizontal, MaterialSpacing.lg)
                    .padding(.vertical, MaterialSpacing.md)
                    
                    // Exercise cards
                    ForEach(Array(routine.exercises.enumerated()), id: \.element.exercise.id) { index, workoutExercise in
                        ExercisePreviewCard(
                            workoutExercise: workoutExercise,
                            exerciseNumber: index + 1
                        )
                        .padding(.horizontal, MaterialSpacing.lg)
                    }
                }
                .padding(.bottom, 100) // Space for bottom button
            }
            
            // Bottom start button
            VStack(spacing: 0) {
                Divider()
                    .background(colors.outline.opacity(0.5))
                
                Button(action: {
                    onStartWorkout(routineId)
                }) {
                    HStack(spacing: MaterialSpacing.md) {
                        Image(themeManager?.currentTheme == .dark ? "play_dark" : "play")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                        
                        Text("Start Workout")
                            .vagFont(size: 16, weight: .semibold)
                    }
                    .foregroundColor(colors.onPrimary)
                    .padding(.vertical, MaterialSpacing.lg)
                    .frame(maxWidth: .infinity)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.primary)
                )
                .padding(.horizontal, MaterialSpacing.lg)
                .padding(.vertical, MaterialSpacing.lg)
            }
            .background(colors.background)
        }
    }
}

// MARK: - Exercise Preview Card
struct ExercisePreviewCard: View {
    let workoutExercise: WorkoutExercise
    let exerciseNumber: Int
    @Environment(\.themeManager) private var themeManager
    
    private var colors: ThemeColorScheme {
        themeManager?.colors ?? ThemeColorScheme(
            primary: LightThemeColors.primary,
            onPrimary: LightThemeColors.onPrimary,
            secondary: LightThemeColors.secondary,
            onSecondary: LightThemeColors.onSecondary,
            background: LightThemeColors.background,
            onBackground: LightThemeColors.onBackground,
            surface: LightThemeColors.surface,
            onSurface: LightThemeColors.onSurface,
            outline: LightThemeColors.outline,
            primaryContainer: LightThemeColors.primaryContainer,
            onPrimaryContainer: LightThemeColors.onPrimaryContainer,
            surfaceVariant: LightThemeColors.surfaceVariant,
            onSurfaceVariant: LightThemeColors.onSurfaceVariant,
            error: LightThemeColors.error,
            shadow: LightThemeColors.shadow
        )
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: MaterialSpacing.lg) {
            // Exercise number badge
            ZStack {
                Circle()
                    .fill(colors.primary.opacity(0.1))
                    .overlay(
                        Circle()
                            .stroke(colors.primary, lineWidth: 1)
                    )
                    .frame(width: 32, height: 32)
                
                Text("\(exerciseNumber)")
                    .font(MaterialTypography.caption)
                    .vagFont(size: 12, weight: .bold)
                    .foregroundColor(colors.primary)
            }
            
            // Exercise details
            VStack(alignment: .leading, spacing: 4) {
                Text(cleanExerciseName(workoutExercise.exercise.name))
                    .vagFont(size: 14, weight: .semibold)
                    .foregroundColor(colors.onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Muscle group and equipment
                HStack(spacing: 12) {
                    if !workoutExercise.exercise.muscleGroup.isEmpty {
                        Text(workoutExercise.exercise.muscleGroup)
                            .font(MaterialTypography.caption)
                            .foregroundColor(colors.onSurface.opacity(0.7))
                    }
                    
                    if !workoutExercise.exercise.equipment.isEmpty {
                        Text("•")
                            .foregroundColor(colors.onSurface.opacity(0.7))
                            .font(.system(size: 12))
                        
                        Text(workoutExercise.exercise.equipment)
                            .font(MaterialTypography.caption)
                            .foregroundColor(colors.onSurface.opacity(0.7))
                    }
                }
                
                // Exercise type indicators
                HStack(spacing: MaterialSpacing.sm) {
                    if workoutExercise.exercise.isBodyweight {
                        ExerciseTypeChip(text: "Bodyweight", color: colors.secondary)
                    }
                    if workoutExercise.exercise.isTimeBased {
                        ExerciseTypeChip(text: "Time-based", color: Color.orange)
                    }
                    if workoutExercise.exercise.tracksDistance {
                        ExerciseTypeChip(text: "Distance", color: colors.error)
                    }
                }
            }
            
            Spacer()
            
            // Sets info
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(workoutExercise.sets.count)")
                    .font(MaterialTypography.subtitle2)
                    .vagFont(size: 16, weight: .bold)
                    .foregroundColor(colors.onSurface)
                
                Text("sets")
                    .font(MaterialTypography.caption)
                    .foregroundColor(colors.onSurface.opacity(0.7))
            }
        }
        .padding(MaterialSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colors.outline, lineWidth: 1)
                )
        )
    }
    
    // Clean exercise name function - Swift version of Kotlin function
    private func cleanExerciseName(_ name: String) -> String {
        print("Original exercise name: '\(name)'")
        
        var cleaned = name
            // Fix pipe character "|" patterns
            .replacingOccurrences(of: #"\|\s+barbell\b"#, with: "barbell", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\|\s+dumbbell\b"#, with: "dumbbell", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\|\s+machine\b"#, with: "machine", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\|\s+cable\b"#, with: "cable", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\|\s+press\b"#, with: "press", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\|\s+curl\b"#, with: "curl", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\|\s+row\b"#, with: "row", options: [.regularExpression, .caseInsensitive])
            
            // Fix "word |" patterns
            .replacingOccurrences(of: #"\bchest\s+\|\b"#, with: "chest", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bback\s+\|\b"#, with: "back", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bleg\s+\|\b"#, with: "leg", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\barm\s+\|\b"#, with: "arm", options: [.regularExpression, .caseInsensitive])
            
            // Remove standalone "|" characters
            .replacingOccurrences(of: #"\s+\|\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"^\|\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+\|$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "|", with: "")
            
            // Clean up multiple spaces
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        let finalResult: String
        if !cleaned.isEmpty {
            // Capitalize first letter of each word
            finalResult = cleaned.split(separator: " ")
                .map { String($0).lowercased().prefix(1).uppercased() + String($0).lowercased().dropFirst() }
                .joined(separator: " ")
        } else {
            finalResult = "Unknown Exercise"
        }
        
        print("Cleaned exercise name: '\(finalResult)'")
        return finalResult
    }
}

// MARK: - Exercise Type Chip
struct ExerciseTypeChip: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}