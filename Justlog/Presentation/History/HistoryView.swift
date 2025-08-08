import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @Environment(\.themeManager) private var themeManager
    @State private var selectedWorkout: WorkoutHistory? = nil
    
    init(
        historyRepository: WorkoutHistoryRepository,
        authRepository: AuthRepository,
        userPreferences: UserPreferences
    ) {
        self._viewModel = StateObject(wrappedValue: HistoryViewModel(
            historyRepository: historyRepository,
            authRepository: authRepository,
            userPreferences: userPreferences
        ))
    }
    
    var body: some View {
        ZStack {
            (themeManager?.colors.background ?? LightThemeColors.background)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Month navigator
                    monthNavigator
                        .padding(.horizontal, MaterialSpacing.md)
                        .padding(.vertical, MaterialSpacing.sm)
                    
                    Spacer().frame(height: 24)
                    
                    // Calendar
                    monthlyCalendar
                        .padding(.horizontal, MaterialSpacing.md)
                    
                    Spacer().frame(height: 24)
                    
                    // Workouts section header
                    workoutsHeader
                        .padding(.horizontal, MaterialSpacing.md)
                    
                    Spacer().frame(height: MaterialSpacing.md)
                    
                    // Workout cards
                    ForEach(viewModel.monthWorkouts) { workout in
                        WorkoutCard(
                            workout: workout,
                            weightUnit: viewModel.weightUnit,
                            onTap: {
                                selectedWorkout = workout
                            }
                        )
                        .padding(.horizontal, MaterialSpacing.md)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.bottom, MaterialSpacing.md)
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager?.colors.primary ?? LightThemeColors.primary))
            }
        }
        .navigationTitle("Workout History")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(
                workout: workout,
                weightUnit: viewModel.weightUnit
            )
        }
    }
    
    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            ArrowButton(
                iconName: "chevron.left",
                action: viewModel.pagePrev
            )
            
            Spacer()
            
            Text(monthDisplayName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            
            Spacer()
            
            ArrowButton(
                iconName: "chevron.right",
                action: viewModel.pageNext
            )
        }
    }
    
    private var monthDisplayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewModel.currentMonth)
    }
    
    // MARK: - Monthly Calendar
    private var monthlyCalendar: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 8) {
            // Day headers
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    .frame(height: 20)
            }
            
            // Calendar days
            ForEach(viewModel.calendarDays) { day in
                CalendarDayView(
                    day: day,
                    themeManager: themeManager
                )
            }
        }
    }
    
    // MARK: - Workouts Header
    private var workoutsHeader: some View {
        HStack {
            Text("Workouts")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            
            Spacer()
            
            Text("\(viewModel.monthWorkouts.count) workouts")
                .font(.body)
                .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
        }
    }
}

// MARK: - Arrow Button
struct ArrowButton: View {
    let iconName: String
    let action: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                )
        }
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let day: MonthlyCalendarDay
    let themeManager: ThemeManager?
    
    var body: some View {
        let hasWorkout = day.colorHex != nil
        let routineColor = day.colorHex != nil ? Color(hex: day.colorHex!) : nil
        
        ZStack {
            Circle()
                .fill(hasWorkout ? (routineColor?.opacity(0.35) ?? Color.clear) : Color.clear)
                .overlay(
                    Circle()
                        .stroke(hasWorkout ? (routineColor ?? Color.clear) : (themeManager?.colors.outline ?? LightThemeColors.outline), lineWidth: 1)
                )
            
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.body)
                .fontWeight(hasWorkout ? .semibold : .regular)
                .foregroundColor(hasWorkout ? 
                    (themeManager?.colors.onSurface ?? LightThemeColors.onSurface) : 
                    (themeManager?.colors.onSurface ?? LightThemeColors.onSurface))
        }
        .frame(width: 40, height: 40)
    }
}

