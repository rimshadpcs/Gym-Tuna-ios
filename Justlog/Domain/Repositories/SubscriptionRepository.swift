import Foundation
import Combine

protocol SubscriptionRepository {
    func getUserSubscription() async throws -> AnyPublisher<UserSubscription, Error>
    func updateSubscription(_ subscription: UserSubscription) async throws
    func purchaseMonthly() async throws -> Result<UserSubscription, Error>
    func purchaseYearly() async throws -> Result<UserSubscription, Error>
    func restorePurchases() async throws -> Result<UserSubscription, Error>
    func cancelSubscription() async throws -> Result<Void, Error>
    
    // MARK: - Cleanup
    func onCleared()
    func clearCache()
}