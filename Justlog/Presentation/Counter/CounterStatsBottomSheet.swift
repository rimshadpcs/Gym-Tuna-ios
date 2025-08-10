import SwiftUI

struct CounterStatsBottomSheet: View {
    let counter: Counter
    let stats: CounterStats?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: MaterialSpacing.md) {
                if let stats = stats {
                    // Stats grid with reduced spacing
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: MaterialSpacing.sm) {
                        StatCard(title: "Yesterday", value: stats.yesterday)
                        StatCard(title: "Today", value: stats.today)
                        StatCard(title: "This Week", value: stats.thisWeek)
                        StatCard(title: "This Month", value: stats.thisMonth)
                        StatCard(title: "This Year", value: stats.thisYear)
                        StatCard(title: "All Time", value: stats.allTime)
                    }
                } else {
                    VStack(spacing: MaterialSpacing.sm) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager?.colors.primary ?? LightThemeColors.primary))
                        
                        Text("Loading stats...")
                            .font(.caption)
                            .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(MaterialSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager?.colors.background ?? LightThemeColors.background)
            .navigationTitle("\(counter.name) Stats")
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
        .background(themeManager?.colors.background ?? LightThemeColors.background)
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(spacing: MaterialSpacing.xs) {
            Text(title)
                .font(.caption2)
                .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                .multilineTextAlignment(.center)
            
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(MaterialSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                .shadow(
                    color: (themeManager?.colors.shadow ?? LightThemeColors.shadow).opacity(0.05),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        )
    }
}