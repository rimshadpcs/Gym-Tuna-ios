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
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            
            // Title
            Text(routineName)
                .font(MaterialTypography.headline6)
                .foregroundColor(MaterialColors.onSurface)
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
            
            // Bottom padding
            Spacer().frame(height: MaterialSpacing.lg)
        }
        .background(MaterialColors.surface)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
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
    var titleColor: Color = MaterialColors.onSurface
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MaterialSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(titleColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(MaterialTypography.body1)
                    .foregroundColor(titleColor)
                
                Spacer()
            }
            .padding(.horizontal, MaterialSpacing.lg)
            .padding(.vertical, MaterialSpacing.md)
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
    
    var body: some View {
        VStack(spacing: MaterialSpacing.sectionSpacing) {
            // Icon
            Image(systemName: "trash")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            // Title
            Text("Delete Routine")
                .font(MaterialTypography.headline6)
                .foregroundColor(MaterialColors.onSurface)
            
            // Message
            VStack(spacing: MaterialSpacing.sm) {
                Text("Are you sure you want to delete \"\(routineName)\"?")
                    .font(MaterialTypography.body1)
                    .foregroundColor(MaterialColors.onSurface)
                    .multilineTextAlignment(.center)
                
                Text("This action cannot be undone.")
                    .font(MaterialTypography.body2)
                    .foregroundColor(MaterialColors.onSurface.opacity(0.7))
            }
            
            // Buttons
            HStack(spacing: MaterialSpacing.lg) {
                // Cancel
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(MaterialTypography.button)
                        .foregroundColor(MaterialColors.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaterialSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .stroke(MaterialColors.outline, lineWidth: 1)
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
                .fill(MaterialColors.surface)
                .materialElevation(3)
        )
        .padding(.horizontal, MaterialSpacing.lg)
    }
}