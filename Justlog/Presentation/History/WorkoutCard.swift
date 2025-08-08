import SwiftUI

struct WorkoutCard: View {
    let workout: WorkoutHistory
    let weightUnit: WeightUnit
    let onTap: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: MaterialSpacing.md) {
                // Header Row
                HStack {
                    HStack(spacing: MaterialSpacing.sm) {
                        // Routine color indicator
                        Circle()
                            .fill(routineColor.opacity(0.45))
                            .overlay(
                                Circle()
                                    .stroke(routineColor, lineWidth: 1)
                            )
                            .frame(width: 14, height: 14)
                        
                        // Workout name
                        Text(workout.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Arrow icon
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                }
                
                // Date and Time Row
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                        
                        Text(dateTimeText)
                            .font(.body)
                            .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    }
                    
                    Spacer()
                    
                    Text(durationText)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                }
                
                // Stats Row
                HStack {
                    StatItem(
                        icon: "star",
                        label: "Exercises",
                        value: "\(workout.exercises.count)"
                    )
                    
                    Spacer()
                    
                    StatItem(
                        icon: nil,
                        label: "Sets",
                        value: "\(workout.totalSets)"
                    )
                    
                    Spacer()
                    
                    StatItem(
                        icon: nil,
                        label: "Volume",
                        value: formatWeight(workout.totalVolume)
                    )
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
            .shadow(
                color: (themeManager?.colors.shadow ?? LightThemeColors.shadow).opacity(0.1),
                radius: 2,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(PlainButtonStyle())
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
            converted = weightInKg * 2.20462 // kg to lbs conversion
            unitLabel = "lb"
        }
        
        if converted == converted.rounded() {
            return "\(Int(converted.rounded())) \(unitLabel)"
        } else {
            return String(format: "%.1f", converted).replacingOccurrences(of: ".0", with: "") + " \(unitLabel)"
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String?
    let label: String
    let value: String
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                }
                
                Text(value)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
        }
    }
}