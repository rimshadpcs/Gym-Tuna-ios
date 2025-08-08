import Foundation
import Combine

@MainActor
class SubscriptionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var subscription = UserSubscription()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let subscriptionRepository: SubscriptionRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var error: String? { errorMessage }
    var isPremium: Bool { 
        subscription.tier == .premium && subscription.isActive 
    }
    
    // MARK: - Initialization
    init(subscriptionRepository: SubscriptionRepository) {
        self.subscriptionRepository = subscriptionRepository
        loadSubscription()
    }
    
    // MARK: - Private Methods
    private func loadSubscription() {
        Task {
            do {
                let publisher = try await subscriptionRepository.getUserSubscription()
                publisher
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { [weak self] completion in
                            if case .failure(let error) = completion {
                                print("Error loading subscription: \(error)")
                                self?.errorMessage = "Failed to load subscription: \(error.localizedDescription)"
                            }
                        },
                        receiveValue: { [weak self] subscription in
                            self?.subscription = subscription
                            print("Subscription loaded: \(subscription.tier), active: \(subscription.isActive)")
                        }
                    )
                    .store(in: &cancellables)
            } catch {
                print("Error loading subscription: \(error)")
                errorMessage = "Failed to load subscription: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Public Methods
    
    // For the main "Claim Launch Offer" button - defaults to yearly
    func purchasePremium() {
        purchaseYearly()
    }
    
    // For monthly subscription purchases
    func purchaseMonthly() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
                print("Starting monthly premium purchase...")
                
                let result = try await subscriptionRepository.purchaseMonthly()
                
                switch result {
                case .success(let subscription):
                    self.subscription = subscription
                    print("Monthly premium purchase successful")
                case .failure(let error):
                    errorMessage = "Monthly purchase failed: \(error.localizedDescription)"
                    print("Monthly premium purchase failed: \(error)")
                }
            } catch {
                errorMessage = "Monthly purchase failed: \(error.localizedDescription)"
                print("Monthly premium purchase error: \(error)")
            }
            
            isLoading = false
        }
    }
    
    // For yearly subscription purchases
    func purchaseYearly() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
                print("Starting yearly premium purchase...")
                
                let result = try await subscriptionRepository.purchaseYearly()
                
                switch result {
                case .success(let subscription):
                    self.subscription = subscription
                    print("Yearly premium purchase successful")
                case .failure(let error):
                    errorMessage = "Yearly purchase failed: \(error.localizedDescription)"
                    print("Yearly premium purchase failed: \(error)")
                }
            } catch {
                errorMessage = "Yearly purchase failed: \(error.localizedDescription)"
                print("Yearly premium purchase error: \(error)")
            }
            
            isLoading = false
        }
    }
    
    // For the "Restore Purchases" button
    func restorePurchases() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
                print("Restoring purchases...")
                
                let result = try await subscriptionRepository.restorePurchases()
                
                switch result {
                case .success(let subscription):
                    self.subscription = subscription
                    print("Purchases restored successfully")
                case .failure:
                    errorMessage = "No purchases to restore"
                    print("No purchases found to restore")
                }
            } catch {
                errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
                print("Error restoring purchases: \(error)")
            }
            
            isLoading = false
        }
    }
    
    // For subscription cancellation
    func cancelSubscription() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
                print("Canceling subscription...")
                
                let result = try await subscriptionRepository.cancelSubscription()
                
                switch result {
                case .success:
                    // Reload subscription to get updated state
                    loadSubscription()
                    print("Subscription canceled successfully")
                case .failure(let error):
                    errorMessage = "Failed to cancel subscription: \(error.localizedDescription)"
                    print("Failed to cancel subscription: \(error)")
                }
            } catch {
                errorMessage = "Failed to cancel subscription: \(error.localizedDescription)"
                print("Error canceling subscription: \(error)")
            }
            
            isLoading = false
        }
    }
    
    // TEST METHODS - For development and testing
    func testActivatePremium() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
                print("🧪 TEST: Activating Premium subscription")
                
                let premiumSubscription = UserSubscription(
                    tier: .premium,
                    isActive: true,
                    purchaseDate: Date().timeIntervalSince1970,
                    expirationDate: Date().addingTimeInterval(365 * 24 * 60 * 60).timeIntervalSince1970 // 1 year
                )
                
                try await subscriptionRepository.updateSubscription(premiumSubscription)
                subscription = premiumSubscription
                
                print("🧪 TEST: Premium activated successfully")
            } catch {
                errorMessage = "Test activation failed: \(error.localizedDescription)"
                print("🧪 TEST: Error activating premium: \(error)")
            }
            
            isLoading = false
        }
    }
    
    func testCancelPremium() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
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
                errorMessage = "Test cancellation failed: \(error.localizedDescription)"
                print("🧪 TEST: Error canceling premium: \(error)")
            }
            
            isLoading = false
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func refreshSubscription() {
        loadSubscription()
    }
}