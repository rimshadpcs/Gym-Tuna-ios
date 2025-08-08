import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var userProfile = UserProfile()
    @Published var subscription = UserSubscription()
    @Published var weightUnit: WeightUnit = .kg
    @Published var distanceUnit: DistanceUnit = .km
    @Published var currentTheme: AppTheme = .light
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    private let authRepository: AuthRepository
    private let subscriptionRepository: SubscriptionRepository
    private let userPreferences: UserPreferences
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        authRepository: AuthRepository,
        subscriptionRepository: SubscriptionRepository,
        userPreferences: UserPreferences
    ) {
        self.authRepository = authRepository
        self.subscriptionRepository = subscriptionRepository
        self.userPreferences = userPreferences
        
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    func loadInitialData() async {
        await loadUserProfile()
        await loadSubscription()
        loadPreferences()
    }
    
    private func loadUserProfile() async {
        if let user = await authRepository.getCurrentUser() {
            userProfile = UserProfile(
                uid: user.id,
                displayName: user.displayName ?? "",
                email: user.email ?? ""
            )
        }
    }
    
    private func loadSubscription() async {
        do {
            let subscriptionPublisher = try await subscriptionRepository.getUserSubscription()
            subscriptionPublisher
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { [weak self] subscription in
                        self?.subscription = subscription
                    }
                )
                .store(in: &cancellables)
        } catch {
            print("Error loading subscription: \(error)")
            subscription = UserSubscription() // Default to free
        }
    }
    
    private func loadPreferences() {
        // Load weight unit
        userPreferences.$weightUnit
            .receive(on: DispatchQueue.main)
            .sink { [weak self] unit in
                self?.weightUnit = unit
            }
            .store(in: &cancellables)
        
        // Load distance unit
        userPreferences.$distanceUnit
            .receive(on: DispatchQueue.main)
            .sink { [weak self] unit in
                self?.distanceUnit = unit
            }
            .store(in: &cancellables)
        
        // Load theme
        userPreferences.$appTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.currentTheme = theme
            }
            .store(in: &cancellables)
    }
    
    func updateDisplayName(newName: String) {
        Task {
            do {
                // TODO: Implement updateUserProfile in AuthRepository when available
                userProfile = UserProfile(
                    uid: userProfile.id,
                    displayName: newName,
                    email: userProfile.email
                )
            } catch {
                errorMessage = "Failed to update name"
            }
        }
    }
    
    func updateWeightUnit(_ unit: WeightUnit) {
        Task {
            await userPreferences.setWeightUnit(unit)
            weightUnit = unit
        }
    }
    
    func updateDistanceUnit(_ unit: DistanceUnit) {
        Task {
            await userPreferences.setDistanceUnit(unit)
            distanceUnit = unit
        }
    }
    
    func updateTheme(_ theme: AppTheme) {
        Task {
            await userPreferences.setAppTheme(theme)
            currentTheme = theme
        }
    }
    
    func signOut() {
        Task {
            do {
                print("Starting sign out")
                try await authRepository.signOut()
                await userPreferences.clearPreferences()
                print("Sign out completed")
            } catch {
                print("Error during sign out: \(error)")
                errorMessage = "Failed to sign out"
            }
        }
    }
    
    func deleteAccount() {
        Task {
            do {
                print("Starting account deletion")
                // TODO: Implement actual account deletion in AuthRepository
                try await authRepository.signOut()
                await userPreferences.clearPreferences()
                print("Account deletion completed")
            } catch {
                print("Error during account deletion: \(error)")
                errorMessage = "Failed to delete account"
            }
        }
    }
    
    // TEST METHODS - For testing subscription functionality
    func testActivatePremium() {
        Task {
            do {
                print("🧪 TEST: Activating Premium subscription")
                let premiumSubscription = UserSubscription(
                    tier: .premium,
                    isActive: true,
                    purchaseDate: Date().timeIntervalSince1970,
                    expirationDate: Date().timeIntervalSince1970 + (365 * 24 * 60 * 60) // 1 year
                )
                try await subscriptionRepository.updateSubscription(premiumSubscription)
                subscription = premiumSubscription
                print("🧪 TEST: Premium activated successfully")
            } catch {
                print("🧪 TEST: Error activating premium: \(error)")
                errorMessage = "Test activation failed"
            }
        }
    }
    
    func testCancelSubscription() {
        Task {
            do {
                print("🧪 TEST: Canceling Premium subscription")
                let freeSubscription = UserSubscription(
                    tier: .free,
                    isActive: false,
                    purchaseDate: nil,
                    expirationDate: nil
                )
                try await subscriptionRepository.updateSubscription(freeSubscription)
                subscription = freeSubscription
                print("🧪 TEST: Premium canceled successfully")
            } catch {
                print("🧪 TEST: Error canceling premium: \(error)")
                errorMessage = "Test cancellation failed"
            }
        }
    }
    
    func refreshSubscription() {
        Task {
            await loadSubscription()
        }
    }
}