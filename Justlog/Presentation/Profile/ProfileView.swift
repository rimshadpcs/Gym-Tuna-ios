//
//  ProfileView.swift
//  Justlog
//
//  Created by Claude on 10/08/2025.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.themeManager) private var themeManager
    @State private var showSignOutDialog = false
    @State private var showDeleteDialog = false
    
    let onBack: () -> Void
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void
    
    init(
        authRepository: AuthRepository,
        subscriptionRepository: SubscriptionRepository,
        userPreferences: UserPreferences,
        onBack: @escaping () -> Void,
        onSignOut: @escaping () -> Void,
        onDeleteAccount: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(
            authRepository: authRepository,
            subscriptionRepository: subscriptionRepository,
            userPreferences: userPreferences
        ))
        self.onBack = onBack
        self.onSignOut = onSignOut
        self.onDeleteAccount = onDeleteAccount
    }
    
    private var isDarkTheme: Bool {
        themeManager?.currentTheme == .dark
    }
    
    var body: some View {
        ZStack {
            (themeManager?.colors.background ?? LightThemeColors.background)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    IOSBackButton(action: onBack)
                    
                    Spacer()
                    
                    Text("Profile")
                        .vagFont(size: 20, weight: .semibold)
                        .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                    
                    Spacer()
                    
                    // Empty space to balance the back button
                    Color.clear
                        .frame(width: 48, height: 48)
                }
                .padding(.horizontal, MaterialSpacing.screenHorizontal)
                .padding(.top, MaterialSpacing.lg)
                
                // Main Content
                VStack(spacing: MaterialSpacing.xl) {
                    Spacer()
                        .frame(height: 32)
                    
                    // Profile Avatar
                    profileAvatar
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // User Info
                    userInfoSection
                    
                    Spacer()
                        .frame(height: 48)
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    Spacer()
                }
                .padding(.horizontal, MaterialSpacing.lg)
            }
            
            // Sign Out Confirmation Dialog
            if showSignOutDialog {
                confirmationOverlay
                signOutDialog
            }
            
            // Delete Account Confirmation Dialog
            if showDeleteDialog {
                confirmationOverlay
                deleteAccountDialog
            }
        }
    }
    
    // MARK: - Profile Avatar
    
    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                .frame(width: 100, height: 100)
                .shadow(
                    color: (themeManager?.colors.shadow ?? LightThemeColors.shadow).opacity(0.2),
                    radius: 4,
                    x: 0,
                    y: 2
                )
            
            Image(isDarkTheme ? "profile" : "profile_dark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - User Info Section
    
    private var userInfoSection: some View {
        VStack(spacing: MaterialSpacing.sm) {
            Text(viewModel.userProfile.displayName.isEmpty ? "User" : viewModel.userProfile.displayName)
                .vagFont(size: 28, weight: .bold)
                .foregroundColor(themeManager?.colors.onBackground ?? LightThemeColors.onBackground)
                .multilineTextAlignment(.center)
            
            Text(viewModel.userProfile.email)
                .font(MaterialTypography.body1)
                .foregroundColor((themeManager?.colors.onBackground ?? LightThemeColors.onBackground).opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: MaterialSpacing.lg) {
            // Sign Out Button
            signOutButton
            
            // Delete Account Button
            deleteAccountButton
        }
    }
    
    private var signOutButton: some View {
        Button(action: { showSignOutDialog = true }) {
            HStack(spacing: MaterialSpacing.md) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                
                Text("Sign Out")
                    .vagFont(size: 16, weight: .semibold)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MaterialSpacing.lg)
            .background(themeManager?.colors.surface ?? LightThemeColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var deleteAccountButton: some View {
        Button(action: { showDeleteDialog = true }) {
            HStack(spacing: MaterialSpacing.md) {
                Image(systemName: "trash")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.red)
                
                Text("Delete Account")
                    .vagFont(size: 16, weight: .semibold)
                    .foregroundColor(.red)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MaterialSpacing.lg)
            .background(themeManager?.colors.surface ?? LightThemeColors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.red, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Confirmation Overlay
    
    private var confirmationOverlay: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
                showSignOutDialog = false
                showDeleteDialog = false
            }
    }
    
    // MARK: - Sign Out Dialog
    
    private var signOutDialog: some View {
        VStack(spacing: MaterialSpacing.lg) {
            // Title
            Text("Sign Out")
                .vagFont(size: 20, weight: .semibold)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
            
            // Message
            Text("Are you sure you want to sign out?")
                .font(MaterialTypography.body1)
                .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                .multilineTextAlignment(.center)
            
            // Buttons
            HStack(spacing: MaterialSpacing.lg) {
                // Cancel Button
                Button(action: { showSignOutDialog = false }) {
                    Text("Cancel")
                        .vagFont(size: 16, weight: .medium)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaterialSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                // Confirm Button
                Button(action: {
                    showSignOutDialog = false
                    onSignOut()
                }) {
                    Text("Sign Out")
                        .vagFont(size: 16, weight: .medium)
                        .foregroundColor(themeManager?.colors.onPrimary ?? .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaterialSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .fill(themeManager?.colors.primary ?? LightThemeColors.primary)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MaterialSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                .shadow(
                    color: (themeManager?.colors.shadow ?? LightThemeColors.shadow).opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, MaterialSpacing.lg)
    }
    
    // MARK: - Delete Account Dialog
    
    private var deleteAccountDialog: some View {
        VStack(spacing: MaterialSpacing.lg) {
            // Title
            Text("Delete Account")
                .vagFont(size: 20, weight: .semibold)
                .foregroundColor(.red)
            
            // Message
            VStack(spacing: MaterialSpacing.sm) {
                Text("Are you sure you want to delete your account?")
                    .font(MaterialTypography.body1)
                    .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                    .multilineTextAlignment(.center)
                
                Text("This action cannot be undone and all your data will be permanently lost.")
                    .font(MaterialTypography.body2)
                    .foregroundColor((themeManager?.colors.onSurface ?? LightThemeColors.onSurface).opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Buttons
            HStack(spacing: MaterialSpacing.lg) {
                // Cancel Button
                Button(action: { showDeleteDialog = false }) {
                    Text("Cancel")
                        .vagFont(size: 16, weight: .medium)
                        .foregroundColor(themeManager?.colors.onSurface ?? LightThemeColors.onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaterialSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .stroke(themeManager?.colors.outline ?? LightThemeColors.outline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                // Confirm Button
                Button(action: {
                    showDeleteDialog = false
                    onDeleteAccount()
                }) {
                    Text("Delete Account")
                        .vagFont(size: 16, weight: .medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MaterialSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MaterialCornerRadius.medium)
                                .fill(.red)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MaterialSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: MaterialCornerRadius.large)
                .fill(themeManager?.colors.surface ?? LightThemeColors.surface)
                .shadow(
                    color: (themeManager?.colors.shadow ?? LightThemeColors.shadow).opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, MaterialSpacing.lg)
    }
}
