import SwiftUI

struct CounterCard: View {
    let counter: Counter
    let hasPendingChanges: Bool
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onTodayCountChanged: (Int) -> Void
    let onOptions: () -> Void
    let onStats: () -> Void
    
    @Environment(\.themeManager) private var themeManager
    @State private var todayCountText: String = ""
    @State private var isEditing = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: MaterialSpacing.md) {
            // Header with name and options (removed stats button)
            HStack {
                Text(counter.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                
                Spacer()
                
                Button(action: onOptions) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .font(.title3)
                }
            }
            
            // Total count (large, prominent like Android) - tappable for stats
            VStack(spacing: 2) {
                Text("\(counter.currentCount)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    .onTapGesture {
                        onStats()
                    }
            }
            
            // Today section with controls (matching Android layout exactly)
            VStack(spacing: MaterialSpacing.sm) {
                HStack(spacing: MaterialSpacing.lg) {
                    // Decrement button (circle with minus)
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1.5)
                            )
                    }
                    .disabled(counter.todayCount <= 0)
                    .opacity(counter.todayCount > 0 ? 1.0 : 0.3)
                    
                    // Today count (editable, matching Android styling)
                    VStack(spacing: 4) {
                        ZStack {
                            if isEditing {
                                TextField("", text: $todayCountText)
                                    .font(.system(size: 42, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .focused($isTextFieldFocused)
                                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                                    .onSubmit {
                                        commitEdit()
                                    }
                            } else {
                                Text("\(counter.todayCount)")
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                                    .onTapGesture {
                                        startEditing()
                                    }
                            }
                        }
                        .frame(minWidth: 80, minHeight: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themeManager?.colors.surfaceVariant ?? LightThemeColors.surfaceVariant)
                                .opacity(0.5)
                        )
                        
                        Text("Today (tap to edit)")
                            .font(.caption)
                            .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                    }
                    
                    // Increment button (filled circle with plus)
                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager?.colors.onPrimary ?? LightThemeColors.onPrimary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                            )
                    }
                }
                
                // Total display below (like Android)
                if counter.currentCount != counter.todayCount {
                    Text("Total: \(counter.currentCount)")
                        .font(.body)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                }
                
                // Loading indicator
                if hasPendingChanges {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager?.colors.primary ?? LightThemeColors.primary))
                        Text("Syncing...")
                            .font(.caption)
                            .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                    }
                }
            }
        }
        .padding(MaterialSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .stroke(
                    (themeManager?.colors.outline ?? LightThemeColors.outline).opacity(0.3),
                    lineWidth: 1
                )
        )
        .shadow(
            color: (themeManager?.colors.shadow ?? LightThemeColors.shadow).opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onStats()
        }
        .onAppear {
            todayCountText = "\(counter.todayCount)"
        }
        .onChange(of: counter.todayCount) { newValue in
            if !isEditing {
                todayCountText = "\(newValue)"
            }
        }
        .onChange(of: isTextFieldFocused) { focused in
            if !focused && isEditing {
                commitEdit()
            }
        }
    }
    
    private func startEditing() {
        todayCountText = "\(counter.todayCount)"
        isEditing = true
        isTextFieldFocused = true
    }
    
    private func commitEdit() {
        isEditing = false
        isTextFieldFocused = false
        
        if let newCount = Int(todayCountText), newCount >= 0 {
            onTodayCountChanged(newCount)
        } else {
            todayCountText = "\(counter.todayCount)"
        }
    }
}