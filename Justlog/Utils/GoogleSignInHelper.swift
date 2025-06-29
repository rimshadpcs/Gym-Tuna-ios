
import Foundation
import GoogleSignIn
import FirebaseAuth

class GoogleSignInHelper: ObservableObject {
    private let webClientId = "856612400371-d11ud795jtpq5nj4h6o3sbt3vr5luqd0.apps.googleusercontent.com"
    private let logger = "GoogleSignInHelper"
    
    init() {
        print("\(logger): Initializing GoogleSignInHelper with client ID: \(webClientId)")
        configureGoogleSignIn()
    }
    
    private func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientId = dict["CLIENT_ID"] as? String else {
            print("\(logger): Error: GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        let config = GIDConfiguration(clientID: clientId)
        
        GIDSignIn.sharedInstance.configuration = config
    }
    
    @MainActor
    func startSignIn() async throws {
        print("\(logger): Attempting to start sign-in")
        
        guard let presentingViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            throw GoogleSignInError.noPresentingViewController
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            print("\(logger): Got sign-in result")
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("\(logger): Error: No ID token in result")
                throw GoogleSignInError.noIDToken
            }
            
            let accessToken = result.user.accessToken.tokenString
            print("\(logger): Got ID token, creating auth credential")
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Sign in with Firebase
            try await Auth.auth().signIn(with: credential)
            print("\(logger): Successfully signed in with Firebase")
            
        } catch {
            print("\(logger): Error during sign-in: \(error)")
            throw error
        }
    }
    
    func signOut() async throws {
        print("\(logger): Signing out of Google")
        do {
            GIDSignIn.sharedInstance.signOut()
            print("\(logger): Successfully signed out of Google")
        } catch {
            print("\(logger): Error signing out of Google: \(error)")
            throw error
        }
    }
}

enum GoogleSignInError: LocalizedError {
    case noPresentingViewController
    case noIDToken
    case signInCancelled
    
    var errorDescription: String? {
        switch self {
        case .noPresentingViewController:
            return "No presenting view controller found"
        case .noIDToken:
            return "No ID token received from Google"
        case .signInCancelled:
            return "Sign in was cancelled"
        }
    }
}
