//
//  ExerciseSearchView.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 29/06/2025.
//

import SwiftUI

struct ExerciseSearchView: View {
    @StateObject private var viewModel: ExerciseSearchViewModel
    @State private var searchText = ""
    @Environment(\.themeManager) private var themeManager
    let onBack: () -> Void
    let onExerciseSelected: (Exercise) -> Void
    let onCreateExercise: () -> Void
    
    init(
        exerciseRepository: ExerciseRepository,
        onBack: @escaping () -> Void,
        onExerciseSelected: @escaping (Exercise) -> Void,
        onCreateExercise: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: ExerciseSearchViewModel(exerciseRepository: exerciseRepository))
        self.onBack = onBack
        self.onExerciseSelected = onExerciseSelected
        self.onCreateExercise = onCreateExercise
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            topNavigationBar(themeManager: themeManager)
            
            // Search Bar
            searchBar
                .padding(.horizontal, MaterialSpacing.screenHorizontal)
                .padding(.vertical, MaterialSpacing.md)
            
            // Exercise Count and Create Button
            exerciseCountSection
                .padding(.horizontal, MaterialSpacing.screenHorizontal)
                .padding(.bottom, MaterialSpacing.sm)
            
            // Create Exercise Button
            createExerciseButton
                .padding(.horizontal, MaterialSpacing.screenHorizontal)
                .padding(.bottom, MaterialSpacing.md)
            
            // Exercise List
            exerciseList
        }
        .background(themeManager?.colors.background)
        .navigationBarHidden(true)
        .onAppear {
            print("🔄 ExerciseSearchView: onAppear - refreshing exercises")
            viewModel.refreshExercises()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.updateSearchQuery(newValue)
        }
    }
    
    // MARK: - Top Navigation Bar
    private func topNavigationBar(themeManager: ThemeManager?) -> some View {
        HStack {
            IOSBackButton(action: onBack)
            
            Text("Add Exercises")
                .font(MaterialTypography.headline6)
                // 👇 This line was changed
                .foregroundColor(themeManager?.colors.onBackground)
            
            Spacer()
        }
        .padding(.horizontal, MaterialSpacing.screenHorizontal)
        .padding(.vertical, MaterialSpacing.md)
        .background(themeManager?.colors.surface)
    }
    // MARK: - Search Bar
    private var searchBar: some View {
        
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager?.colors.onSurfaceVariant ?? .secondary)
                .font(.system(size: 16))
            
            TextField("Search exercises...", text: $searchText)
                .font(.system(size: 16))
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? .secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    
    // MARK: - Exercise Count Section
    private var exerciseCountSection: some View {
        HStack {
            if case .success(let exercises) = viewModel.exerciseState {
                Text("Ready (\(exercises.count) exercises)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                Text("Loading...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    // MARK: - Create Exercise Button
    private var createExerciseButton: some View {
        Button(action: onCreateExercise) {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager?.colors.onSurface)
                
                Text("Create Exercise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager?.colors.onSurface)
                
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    // 👇 This line was changed
                    .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager?.colors.outline ?? Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Exercise List
    private var exerciseList: some View {
        Group {
            switch viewModel.exerciseState {
            case .loading:
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading exercises...")
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? .secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .success(let exercises):
                if exercises.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No exercises found")
                            .font(.headline)
                            .foregroundColor(themeManager?.colors.onSurfaceVariant ?? .secondary)
                        
                        Text("Try adjusting your search or filter")
                            .font(.body)
                            .foregroundColor(themeManager?.colors.onSurfaceVariant ?? .secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: MaterialSpacing.xs) {
                            ForEach(exercises) { exercise in
                                ExerciseItemView(
                                    exercise: exercise,
                                    onTap: { 
                                        print("🎯 ExerciseSearchView: Exercise tapped: \(exercise.name)")
                                        
                                        // Send exercise through channel (similar to Kotlin ExerciseChannel.sendExercise)
                                        ExerciseChannel.shared.sendExercise(exercise)
                                        
                                        onExerciseSelected(exercise)
                                    }
                                )
                                .padding(.horizontal, MaterialSpacing.screenHorizontal)
                            }
                        }
                        .padding(.vertical, MaterialSpacing.sm)
                    }
                }
                
            case .error(let message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text("Error loading exercises")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? .secondary) // 👈 Changed here
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        viewModel.loadExercises()
                    }
                    .buttonStyle(.materialPrimary)
                    .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, MaterialSpacing.screenHorizontal)
                
            case .initial, .idle:
                EmptyView()
            }
        }
    }
}

// MARK: - Exercise Item View
struct ExerciseItemView: View {
    let exercise: Exercise
    let onTap: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkTheme: Bool {
        colorScheme == .dark
    }
    
    private var muscleGroupIcon: String {
        let group = exercise.muscleGroup.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Debug: Print the actual muscle group from database
        print("💪 Exercise: \(exercise.name) | Muscle Group: '\(exercise.muscleGroup)' | Processed: '\(group)'")
        
        // Helper function to pick light/dark image
        func pick(light: String, dark: String) -> String {
            return isDarkTheme ? dark : light
        }
        
        switch group {
        case "chest":
            let icon = pick(light: "chest", dark: "chest_dark")
            print("✅ Matched chest: \(icon)")
            return icon
        case "back", "middle back", "lower back":
            let icon = pick(light: "back", dark: "back_dark")
            print("✅ Matched back: \(icon)")
            return icon
        case "legs", "quadriceps", "hamstrings", "adductors", "hip flexors":
            let icon = pick(light: "leg", dark: "leg_dark")
            print("✅ Matched legs: \(icon)")
            return icon
        case "shoulders", "traps", "neck":
            let icon = pick(light: "shoulders", dark: "shoulders_dark")
            print("✅ Matched shoulders: \(icon)")
            return icon
        case "biceps", "arms":
            let icon = pick(light: "biceps", dark: "biceps_dark")
            print("✅ Matched biceps/arms: \(icon)")
            return icon
        case "triceps":
            let icon = pick(light: "triceps", dark: "triceps_dark")
            print("✅ Matched triceps: \(icon)")
            return icon
        case "core", "abs", "abdominals", "obliques":
            let icon = pick(light: "core", dark: "core_dark")
            print("✅ Matched core/abs: \(icon)")
            return icon
        case "calves":
            let icon = pick(light: "calves", dark: "calves_dark")
            print("✅ Matched calves: \(icon)")
            return icon
        case "forearms":
            let icon = pick(light: "forearms", dark: "forearms_dark")
            print("✅ Matched forearms: \(icon)")
            return icon
        case "glutes":
            let icon = pick(light: "glutes", dark: "glutes_dark")
            print("✅ Matched glutes: \(icon)")
            return icon
        case "full body":
            let icon = pick(light: "fullbody", dark: "fullbody_dark")
            print("🖼️ Selected icon: \(icon) for muscle group: \(group)")
            return icon
        default:
            let icon = pick(light: "fullbody", dark: "fullbody_dark")
            print("⚠️ No match found! Using default icon: \(icon) for muscle group: '\(group)'")
            return icon
        }
    }
    
    private var equipmentText: String {
        if exercise.equipment.isEmpty {
            return exercise.isBodyweight ? "Body Weight" : "Equipment"
        }
        return exercise.equipment
    }
    
    var body: some View {
        Button(action: {
            print("🔥 ExerciseItemView: Button tapped for \(exercise.name)")
            onTap()
        }) {
            HStack(spacing: 16) {
                // Exercise Icon
                Image(muscleGroupIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.primary)
                
                // Exercise Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.system(size: 18, weight: .medium))
                        // Use the theme's color for text on a surface
                        .foregroundColor(themeManager?.colors.onSurface ?? .primary)
                        .multilineTextAlignment(.leading)
                        
                    Text(equipmentText.lowercased())
                        .font(.system(size: 14))
                        // Use the theme's variant color for secondary text
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? .secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExerciseSearchView(
        exerciseRepository: ExerciseRepositoryImpl(authRepository: AuthRepositoryImpl(userPreferences: UserPreferences.shared, googleSignInHelper: GoogleSignInHelper())),
        onBack: {},
        onExerciseSelected: { _ in },
        onCreateExercise: {}
    )
}
