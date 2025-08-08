import SwiftUI

struct CounterOptionsDialog: View {
    let counter: Counter
    let onRename: (String) -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @State private var showRenameDialog = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Option buttons
                VStack(spacing: 0) {
                    Button(action: {
                        showRenameDialog = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                                .frame(width: 24)
                            
                            Text("Rename")
                                .font(.body)
                                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                            
                            Spacer()
                        }
                        .padding(MaterialSpacing.md)
                        .frame(maxWidth: .infinity)
                        .background(themeManager?.colors.surface ?? LightThemeColors.surface)
                    }
                    
                    Divider()
                        .background(themeManager?.colors.outline ?? LightThemeColors.outline)
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(themeManager?.colors.error ?? LightThemeColors.error)
                                .frame(width: 24)
                            
                            Text("Delete")
                                .font(.body)
                                .foregroundColor(themeManager?.colors.error ?? LightThemeColors.error)
                            
                            Spacer()
                        }
                        .padding(MaterialSpacing.md)
                        .frame(maxWidth: .infinity)
                        .background(themeManager?.colors.surface ?? LightThemeColors.surface)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                        .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                )
                
                Spacer()
            }
            .padding(MaterialSpacing.lg)
            .background(themeManager?.colors.background ?? LightThemeColors.background)
            .navigationTitle(counter.name)
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
        .sheet(isPresented: $showRenameDialog) {
            RenameCounterDialog(
                currentName: counter.name,
                onRename: { newName in
                    onRename(newName)
                    dismiss()
                }
            )
        }
        .alert("Delete Counter", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(counter.name)\"? This action cannot be undone.")
        }
    }
}

struct RenameCounterDialog: View {
    let currentName: String
    let onRename: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @State private var newName: String
    @FocusState private var isTextFieldFocused: Bool
    
    init(currentName: String, onRename: @escaping (String) -> Void) {
        self.currentName = currentName
        self.onRename = onRename
        self._newName = State(initialValue: currentName)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: MaterialSpacing.lg) {
                VStack(alignment: .leading, spacing: MaterialSpacing.sm) {
                    Text("Counter Name")
                        .font(.headline)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    
                    TextField("Enter counter name", text: $newName)
                        .font(.body)
                        .padding(MaterialSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .fill(themeManager?.colors.surfaceVariant ?? LightThemeColors.surfaceVariant)
                        )
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            renameCounter()
                        }
                }
                
                Spacer()
            }
            .padding(MaterialSpacing.lg)
            .background(themeManager?.colors.background ?? LightThemeColors.background)
            .navigationTitle("Rename Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager?.colors.onSurfaceVariant ?? LightThemeColors.onSurfaceVariant)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        renameCounter()
                    }
                    .foregroundColor(themeManager?.colors.primary ?? LightThemeColors.primary)
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func renameCounter() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        onRename(trimmedName)
        dismiss()
    }
}