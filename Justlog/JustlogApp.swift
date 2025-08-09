//
//  JustlogApp.swift
//  Justlog
//
//  Created by Mohmed Rimshad on 27/06/2025.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct JustLogApp: App {  // ← This matches your project name "JustLog"
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var themeManager: ThemeManager
    @StateObject private var userPreferences = UserPreferences.shared
    
    init() {
        _themeManager = StateObject(wrappedValue: ThemeManager(userPreferences: UserPreferences.shared))
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environment(\.themeManager, themeManager)
                    .environmentObject(userPreferences)
            }
        }
    }
}
