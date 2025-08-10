import SwiftUI

struct CounterCard: View {
    let counter: Counter
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
            
            // Today count (large, prominent display) - editable
            VStack(spacing: 2) {
                ZStack {
                    if isEditing {
                        TextField("", text: $todayCountText)
                            .font(.system(size: 48, weight: .bold))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($isTextFieldFocused)
                            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                            .onSubmit {
                                commitEdit()
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        commitEdit()
                                    }
                                    .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                                }
                            }
                    } else {
                        Text("\(counter.todayCount)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                            .onTapGesture {
                                startEditing()
                            }
                            .onLongPressGesture {
                                onStats() // Long press for stats
                            }
                    }
                }
                
                Text(isEditing ? "Enter count" : "Today (tap to edit)")
                    .font(.caption)
                    .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
            }
            
            // Control buttons section - simplified layout
            HStack(spacing: MaterialSpacing.xl) {
                // Decrement button (circle with minus)
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1.5)
                        )
                }
                .disabled(counter.todayCount <= 0)
                .opacity(counter.todayCount > 0 ? 1.0 : 0.3)
                
                Spacer()
                
                // Increment button (filled circle with plus)
                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager?.colors.onPrimary ?? LightThemeColors.onPrimary)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                        )
                }
            }
            
            // Total count display (always show for reference)
            Text("All Time: \(counter.currentCount)")
                .font(.caption)
                .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
            
            // Removed syncing indicator for better UX
            // Background sync happens silently without UI feedback
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
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                if isEditing {
                    commitEdit() // Dismiss keyboard when tapping outside
                }
            }
        )
        .onTapGesture {
            if !isEditing {
                onStats() // Only show stats if not editing
            }
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
        print("🔢 Started editing counter, current value: \(counter.todayCount)")
    }
    
    private func commitEdit() {
        print("🔢 Committing edit: '\(todayCountText)' (was: \(counter.todayCount))")
        isEditing = false
        isTextFieldFocused = false
        
        if let newCount = Int(todayCountText), newCount >= 0 {
            print("🔢 Valid input: \(newCount), calling onTodayCountChanged")
            onTodayCountChanged(newCount)
        } else {
            print("🔢 Invalid input: '\(todayCountText)', reverting to \(counter.todayCount)")
            todayCountText = "\(counter.todayCount)"
        }
    }
}