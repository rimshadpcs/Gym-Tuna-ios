
import SwiftUI

// Debug: Print available fonts
func printAvailableFonts() {
    for family in UIFont.familyNames.sorted() {
        let names = UIFont.fontNames(forFamilyName: family)
        print("Family: \(family) Font names: \(names)")
        // Look specifically for VAG fonts
        if family.lowercased().contains("vag") {
            print("🎯 FOUND VAG FONT: \(family) - \(names)")
        }
    }
}

struct AuthScreen: View {
    @StateObject private var viewModel: AuthViewModel
    let onNavigateToHome: () -> Void
    
    init(viewModel: AuthViewModel, onNavigateToHome: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onNavigateToHome = onNavigateToHome
    }
    
    var body: some View {
        ZStack {
            // Handle navigation events
            Color.clear
                .onReceive(viewModel.navigationEvent) { _ in
                    print("AuthScreen: 🎯 Navigation event received, navigating to home")
                    onNavigateToHome()
                }
            
            // Main content based on auth state
            Group {
                switch viewModel.authState {
                case .initial:
                    SignInScreen {
                        Task {
                            await viewModel.startGoogleSignIn()
                        }
                    }
                case .loading:
                    SplashScreen()
                case .success:
                    SplashScreen()
                case .error(let message):
                    SignInErrorScreen(
                        errorMessage: message,
                        onGoogleSignInClick: {
                            Task {
                                await viewModel.startGoogleSignIn()
                            }
                        }
                    )
                }
            }
        }
        .onChange(of: viewModel.authState) { newState in
            print("AuthScreen: 🎯 Auth state changed to: \(newState)")
        }
    }
}

struct SplashScreen: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 48) {
            // Theme-aware image (you'll need to add these assets)
            Image(colorScheme == .dark ? "gymlogauthpage_dark" : "gymlogauthpage")
                .resizable()
                .scaledToFit()
                .frame(width: 360, height: 360)
            
            Text("JUST LOG")
                .vagFont(size: 28, weight: .bold)
                .foregroundColor(.primary)
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SignInScreen: View {
    let onGoogleSignInClick: () -> Void
    
    var body: some View {
        VStack(spacing: 48) {
            // App logo
            Image("gymlogauthpage")
                .resizable()
                .scaledToFit()
                .frame(width: 360, height: 360)
            
            Text("JUST LOG")
                .vagFont(size: 32, weight: .bold)
                .foregroundColor(.primary)
                .onAppear {
                    printAvailableFonts()
                }
            
            VStack(spacing: 16) {
                SignInWithAppleButton()
                SignInButton(onClick: onGoogleSignInClick)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SignInErrorScreen: View {
    let errorMessage: String?
    let onGoogleSignInClick: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            SignInScreen(onGoogleSignInClick: onGoogleSignInClick)
            
            if let errorMessage = errorMessage,
               !errorMessage.lowercased().contains("cancelled") {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

struct SignInButton: View {
    let onClick: () -> Void
    
    var body: some View {
        Button(action: {
            print("AuthScreen: Sign in button clicked")
            onClick()
        }) {
            HStack(spacing: 8) {
                Image("google_ic")
                    .resizable()
                    .frame(width: 24, height: 24)
                
                Text("Sign in with Google")
                    .vagFont(size: 16, weight: .semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(.systemBackground))
            .foregroundColor(.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SignInWithAppleButton: View {
    var body: some View {
        Button(action: {
            print("AuthScreen: Sign in with Apple clicked")
            // TODO: Implement Apple Sign-In
        }) {
            HStack(spacing: 8) {
                Image(systemName: "applelogo")
                    .resizable()
                    .frame(width: 24, height: 24)
                
                Text("Sign in with Apple")
                    .vagFont(size: 16, weight: .semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
