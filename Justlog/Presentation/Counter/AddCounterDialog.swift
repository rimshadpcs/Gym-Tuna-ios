import SwiftUI

struct AddCounterDialog: View {
    let onAdd: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @State private var counterName = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: MaterialSpacing.lg) {
                VStack(alignment: .leading, spacing: MaterialSpacing.sm) {
                    Text("Counter Name")
                        .font(.headline)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    
                    TextField("Enter counter name", text: $counterName)
                        .font(.body)
                        .padding(MaterialSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .fill(themeManager?.colors.surfaceVariant ?? LightThemeColors.surfaceVariant)
                        )
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            addCounter()
                        }
                }
                
                Spacer()
            }
            .padding(MaterialSpacing.lg)
            .background(themeManager?.colors.background ?? LightThemeColors.background)
            .navigationTitle("Add Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addCounter()
                    }
                    .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                    .disabled(counterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func addCounter() {
        let trimmedName = counterName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        onAdd(trimmedName)
        dismiss()
    }
}