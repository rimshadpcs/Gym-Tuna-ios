//
//  RoutineOptionsSheet.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 28/06/2025.
//

import SwiftUI

struct RoutineOptionsSheet: View {
    let routineName: String
    let onDismiss: () -> Void
    let onDuplicate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.themeManager) private var themeManager
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(themeManager?.colors.onSurface.opacity(0.3) ?? Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            
            // Title
            Text(routineName)
                .font(MaterialTypography.headline6)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                .padding(.horizontal, MaterialSpacing.lg)
                .padding(.top, MaterialSpacing.lg)
            
            // Options
            VStack(spacing: 0) {
                // Duplicate
                OptionButton(
                    icon: "doc.on.doc",
                    title: "Duplicate",
                    action: {
                        onDuplicate()
                        onDismiss()
                    }
                )
                
                // Edit
                OptionButton(
                    icon: "pencil",
                    title: "Edit",
                    action: {
                        onEdit()
                        onDismiss()
                    }
                )
                
                // Delete
                OptionButton(
                    icon: "trash",
                    title: "Delete",
                    titleColor: .red,
                    action: {
                        showDeleteConfirmation = true
                    }
                )
            }
            .padding(.top, MaterialSpacing.lg)
            
            // Bottom padding and fill remaining space
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager?.colors.surface ?? LightThemeColors.surface)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .presentationBackground(themeManager?.colors.surface ?? LightThemeColors.surface)
        .alert("Delete Routine", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
                onDismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(routineName)\"? This action cannot be undone.")
        }
    }
}

struct OptionButton: View {
    let icon: String
    let title: String
    var titleColor: Color?
    let action: () -> Void
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MaterialSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(titleColor ?? (themeManager?.colors.onSurface ?? LightThemeColors.onSurface))
                    .frame(width: 24)
                
                Text(title)
                    .font(MaterialTypography.body1)
                    .foregroundColor(titleColor ?? (themeManager?.colors.onSurface ?? LightThemeColors.onSurface))
                
                Spacer()
            }
            .padding(.horizontal, MaterialSpacing.lg)
            .padding(.vertical, MaterialSpacing.md)
            .background(themeManager?.colors.surface ?? LightThemeColors.surface)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Delete Confirmation Dialog

struct DeleteRoutineConfirmationDialog: View {
    let routineName: String
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(spacing: MaterialSpacing.sectionSpacing) {
            // Icon
            Image(systemName: "trash")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            // Title
            Text("Delete Routine")
                .font(MaterialTypography.headline6)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            
            // Message
            VStack(spacing: MaterialSpacing.sm) {
                Text("Are you sure you want to delete \"\(routineName)\"?")
                    .font(MaterialTypography.body1)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    .multilineTextAlignment(.center)
                
                Text("This action cannot be undone.")
                    .font(MaterialTypography.body2)
                    .foregroundColor(themeManager?.colors.onSurface.opacity(0.7) ?? LightThemeColors.onSurface.opacity(0.7))
            }
            
            // Buttons
            HStack(spacing: MaterialSpacing.lg) {
                // Cancel
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(MaterialTypography.button)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaterialSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                        )
                }
                
                // Delete
                Button(action: onConfirm) {
                    Text("Delete")
                        .font(MaterialTypography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaterialSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .fill(.red)
                        )
                }
            }
        }
        .padding(MaterialSpacing.sectionSpacing)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                .materialElevation(3)
        )
        .padding(.horizontal, MaterialSpacing.lg)
    }
}