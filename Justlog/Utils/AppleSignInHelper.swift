//
//  AppleSignInHelper.swift
//  Justlog
//
//  Created by Claude Code on 11/08/2025.
//

import Foundation
import AuthenticationServices
import FirebaseAuth
import CryptoKit

@MainActor
class AppleSignInHelper: NSObject, ObservableObject {
    private var currentNonce: String?
    private let logger = "AppleSignInHelper"
    
    func startSignIn() async throws {
        print("\(logger): Starting Apple sign in process")
        
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        authorizationController.performRequests()
        
        // Wait for the authentication to complete
        // We'll use a continuation to bridge the delegate callback to async/await
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.authContinuation = continuation
        }
    }
    
    func signOut() async throws {
        print("\(logger): Apple Sign In doesn't require explicit sign out")
        // Apple Sign In doesn't have a sign out method like Google
        // The sign out is handled by Firebase Auth
    }
    
    // MARK: - Private Properties
    private var authContinuation: CheckedContinuation<Void, Error>?
    
    // MARK: - Helper Methods
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInHelper: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("\(logger): Authorization completed successfully")
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                print("\(logger): Invalid state: A login callback was received, but no login request was sent.")
                authContinuation?.resume(throwing: AppleSignInError.invalidState)
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("\(logger): Unable to fetch identity token")
                authContinuation?.resume(throwing: AppleSignInError.missingIdentityToken)
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("\(logger): Unable to serialize token string from data")
                authContinuation?.resume(throwing: AppleSignInError.tokenSerializationFailed)
                return
            }
            
            // Initialize a Firebase credential
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
            
            // Sign in with Firebase
            Task {
                do {
                    let result = try await Auth.auth().signIn(with: credential)
                    print("\(logger): Successfully signed in with Apple: \(result.user.email ?? "no email")")
                    
                    // If this is the first time signing in, we might want to save additional user info
                    if let fullName = appleIDCredential.fullName {
                        let displayName = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        
                        if !displayName.isEmpty {
                            let changeRequest = result.user.createProfileChangeRequest()
                            changeRequest.displayName = displayName
                            try await changeRequest.commitChanges()
                            print("\(logger): Updated user display name: \(displayName)")
                        }
                    }
                    
                    authContinuation?.resume()
                } catch {
                    print("\(logger): Firebase sign in failed: \(error)")
                    authContinuation?.resume(throwing: error)
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("\(logger): Sign in with Apple failed: \(error)")
        
        // Provide more specific error messages for common setup issues
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                print("\(logger): User canceled Apple Sign In")
                authContinuation?.resume(throwing: AppleSignInError.userCanceled)
            case .unknown:
                print("\(logger): Apple Sign In configuration error - likely missing capability")
                authContinuation?.resume(throwing: AppleSignInError.configurationError)
            case .invalidResponse:
                print("\(logger): Invalid response from Apple Sign In")
                authContinuation?.resume(throwing: AppleSignInError.invalidResponse)
            case .notHandled:
                print("\(logger): Apple Sign In not handled")
                authContinuation?.resume(throwing: AppleSignInError.notHandled)
            case .failed:
                print("\(logger): Apple Sign In failed")
                authContinuation?.resume(throwing: AppleSignInError.authenticationFailed)
            @unknown default:
                print("\(logger): Unknown Apple Sign In error: \(authError.localizedDescription)")
                authContinuation?.resume(throwing: error)
            }
        } else {
            authContinuation?.resume(throwing: error)
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInHelper: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}

// MARK: - Error Types
enum AppleSignInError: LocalizedError {
    case invalidState
    case missingIdentityToken
    case tokenSerializationFailed
    case userCanceled
    case configurationError
    case invalidResponse
    case notHandled
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidState:
            return "Invalid state: A login callback was received, but no login request was sent."
        case .missingIdentityToken:
            return "Unable to fetch identity token"
        case .tokenSerializationFailed:
            return "Unable to serialize token string from data"
        case .userCanceled:
            return "Sign in was canceled"
        case .configurationError:
            return "Sign in with Apple is not properly configured. Please complete Apple Developer Program setup."
        case .invalidResponse:
            return "Invalid response from Apple"
        case .notHandled:
            return "Apple Sign In request was not handled"
        case .authenticationFailed:
            return "Apple Sign In authentication failed"
        }
    }
}