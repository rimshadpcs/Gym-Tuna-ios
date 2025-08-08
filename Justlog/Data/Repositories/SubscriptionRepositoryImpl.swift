import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import StoreKit
import os.log

@MainActor
class SubscriptionRepositoryImpl: SubscriptionRepository {
    
    // MARK: - Constants
    private static let PREFS_SUITE = "com.justlog.subscription"
    private static let KEY_SUBSCRIPTION_TIER = "subscription_tier"
    private static let KEY_IS_ACTIVE = "is_active"
    private static let KEY_PURCHASE_DATE = "purchase_date"
    private static let KEY_EXPIRATION_DATE = "expiration_date"
    private static let KEY_PURCHASE_TOKEN = "purchase_token"
    private static let COLLECTION_SUBSCRIPTIONS = "subscriptions"
    
    // StoreKit Product IDs - these should match your App Store Connect setup
    private static let MONTHLY_PREMIUM_ID = "com.justlog.premium.monthly"
    private static let YEARLY_PREMIUM_ID = "com.justlog.premium.yearly"
    
    // MARK: - Properties
    private let firestore: Firestore
    private let auth: Auth
    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "com.justlog.app", category: "SubscriptionRepository")
    
    // Combine subjects
    private let subscriptionSubject: CurrentValueSubject<UserSubscription, Never>
    
    // StoreKit
    private var updateListenerTask: Task<Void, Error>?
    private var products: [Product] = []
    
    // MARK: - Initialization
    init(
        firestore: Firestore = Firestore.firestore(),
        auth: Auth = Auth.auth(),
        userDefaults: UserDefaults = UserDefaults(suiteName: SubscriptionRepositoryImpl.PREFS_SUITE) ?? .standard
    ) {
        self.firestore = firestore
        self.auth = auth
        self.userDefaults = userDefaults
        
        // Load subscription from UserDefaults using static method approach
        let tierString = userDefaults.string(forKey: Self.KEY_SUBSCRIPTION_TIER) ?? SubscriptionTier.free.rawValue
        let isActive = userDefaults.bool(forKey: Self.KEY_IS_ACTIVE)
        let purchaseDate = userDefaults.object(forKey: Self.KEY_PURCHASE_DATE) as? Double
        let expirationDate = userDefaults.object(forKey: Self.KEY_EXPIRATION_DATE) as? Double
        let tier = SubscriptionTier(rawValue: tierString) ?? .free
        
        let initialSubscription = UserSubscription(
            tier: tier,
            isActive: isActive,
            purchaseDate: purchaseDate,
            expirationDate: expirationDate
        )
        
        self.subscriptionSubject = CurrentValueSubject(initialSubscription)
        
        // Setup StoreKit
        setupStoreKit()
        
        // Load from Firestore if user is authenticated
        if let currentUser = auth.currentUser {
            Task {
                await loadSubscriptionFromFirestore(userId: currentUser.uid)
            }
        }
    }
    
    // MARK: - Repository Protocol Implementation
    func getUserSubscription() async throws -> AnyPublisher<UserSubscription, Error> {
        return subscriptionSubject
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func updateSubscription(_ subscription: UserSubscription) async throws {
        logger.info("Updating subscription: \(subscription.tier.rawValue), active: \(subscription.isActive)")
        
        // 1. Save to UserDefaults immediately
        saveSubscriptionToUserDefaults(subscription)
        
        // 2. Update local state
        subscriptionSubject.send(subscription)
        
        // 3. Save to Firestore (if user is authenticated)
        if let currentUser = auth.currentUser {
            await saveSubscriptionToFirestore(userId: currentUser.uid, subscription: subscription)
        }
        
        logger.info("Subscription updated successfully")
    }
    
    func purchaseMonthly() async throws -> Result<UserSubscription, Error> {
        return await performPurchase(productId: Self.MONTHLY_PREMIUM_ID)
    }
    
    func purchaseYearly() async throws -> Result<UserSubscription, Error> {
        return await performPurchase(productId: Self.YEARLY_PREMIUM_ID)
    }
    
    func restorePurchases() async throws -> Result<UserSubscription, Error> {
        do {
            logger.info("Restoring purchases...")
            
            // Get all transactions for the user
            var activeSubscription: UserSubscription?
            
            for await result in StoreKit.Transaction.currentEntitlements {
                do {
                    let transaction = try verifyTransaction(result)
                    
                    // Check if this is one of our subscription products
                    if transaction.productID == Self.MONTHLY_PREMIUM_ID || transaction.productID == Self.YEARLY_PREMIUM_ID {
                        let restoredSubscription = UserSubscription(
                            tier: .premium,
                            isActive: true,
                            purchaseDate: transaction.purchaseDate.timeIntervalSince1970,
                            expirationDate: transaction.expirationDate?.timeIntervalSince1970
                        )
                        
                        activeSubscription = restoredSubscription
                        break
                    }
                } catch {
                    logger.error("Transaction verification failed: \(error.localizedDescription)")
                }
            }
            
            if let activeSubscription = activeSubscription {
                try await updateSubscription(activeSubscription)
                return .success(activeSubscription)
            } else {
                return .failure(SubscriptionError.noActivePurchases)
            }
        } catch {
            logger.error("Error restoring purchases: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func cancelSubscription() async throws -> Result<Void, Error> {
        do {
            logger.info("Canceling subscription...")
            
            // Note: For App Store subscriptions, users cancel through Settings > Apple ID > Subscriptions
            // This method updates local state and guides users to the proper cancellation flow
            
            let canceledSubscription = UserSubscription(
                tier: .free,
                isActive: false,
                purchaseDate: nil,
                expirationDate: nil
            )
            
            try await updateSubscription(canceledSubscription)
            
            // In a real app, you might want to show instructions to the user
            // on how to cancel through iOS Settings
            
            return .success(())
        } catch {
            logger.error("Error canceling subscription: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // MARK: - StoreKit Setup
    private func setupStoreKit() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
        }
    }
    
    private func requestProducts() async {
        do {
            let productIds = [Self.MONTHLY_PREMIUM_ID, Self.YEARLY_PREMIUM_ID]
            self.products = try await Product.products(for: productIds)
            logger.info("Loaded \(self.products.count) products from App Store")
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self = self else { continue }
                do {
                    let transaction: StoreKit.Transaction
                    switch result {
                    case .unverified:
                        throw SubscriptionError.failedVerification
                    case .verified(let verifiedTransaction):
                        transaction = verifiedTransaction
                    }
                    
                    await self.handleTransaction(transaction)
                    await transaction.finish()
                } catch {
                    self.logger.error("Transaction update error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleTransaction(_ transaction: StoreKit.Transaction) async {
        guard transaction.productID == Self.MONTHLY_PREMIUM_ID || transaction.productID == Self.YEARLY_PREMIUM_ID else {
            return
        }
        
        let subscription = UserSubscription(
            tier: .premium,
            isActive: true,
            purchaseDate: transaction.purchaseDate.timeIntervalSince1970,
            expirationDate: transaction.expirationDate?.timeIntervalSince1970
        )
        
        do {
            try await updateSubscription(subscription)
        } catch {
            logger.error("Failed to update subscription after transaction: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Purchase Flow
    private func performPurchase(productId: String) async -> Result<UserSubscription, Error> {
        do {
            guard let product = products.first(where: { $0.id == productId }) else {
                logger.error("Product not found: \(productId)")
                return .failure(SubscriptionError.productNotFound)
            }
            
            logger.info("Launching purchase flow for: \(productId)")
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try verifyTransaction(verification)
                
                let purchasedSubscription = UserSubscription(
                    tier: .premium,
                    isActive: true,
                    purchaseDate: transaction.purchaseDate.timeIntervalSince1970,
                    expirationDate: transaction.expirationDate?.timeIntervalSince1970
                )
                
                try await updateSubscription(purchasedSubscription)
                await transaction.finish()
                
                return .success(purchasedSubscription)
                
            case .userCancelled:
                logger.info("User cancelled purchase")
                return .failure(SubscriptionError.userCancelled)
                
            case .pending:
                logger.info("Purchase is pending")
                return .failure(SubscriptionError.purchasePending)
                
            @unknown default:
                logger.error("Unknown purchase result")
                return .failure(SubscriptionError.unknownError)
            }
            
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    private func verifyTransaction<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - UserDefaults Persistence
    private func saveSubscriptionToUserDefaults(_ subscription: UserSubscription) {
        do {
            logger.debug("💾 Saving to UserDefaults: \(subscription.tier.rawValue), active: \(subscription.isActive)")
            
            userDefaults.set(subscription.tier.rawValue, forKey: Self.KEY_SUBSCRIPTION_TIER)
            userDefaults.set(subscription.isActive, forKey: Self.KEY_IS_ACTIVE)
            
            if let purchaseDate = subscription.purchaseDate {
                userDefaults.set(purchaseDate, forKey: Self.KEY_PURCHASE_DATE)
            } else {
                userDefaults.removeObject(forKey: Self.KEY_PURCHASE_DATE)
            }
            
            if let expirationDate = subscription.expirationDate {
                userDefaults.set(expirationDate, forKey: Self.KEY_EXPIRATION_DATE)
            } else {
                userDefaults.removeObject(forKey: Self.KEY_EXPIRATION_DATE)
            }
            
            userDefaults.synchronize()
            logger.debug("💾 Successfully saved to UserDefaults")
        } catch {
            logger.error("❌ Error saving to UserDefaults: \(error.localizedDescription)")
        }
    }
    
    private func loadSubscriptionFromUserDefaults() -> UserSubscription {
        do {
            let tierString = userDefaults.string(forKey: Self.KEY_SUBSCRIPTION_TIER) ?? SubscriptionTier.free.rawValue
            let isActive = userDefaults.bool(forKey: Self.KEY_IS_ACTIVE)
            
            let purchaseDate = userDefaults.object(forKey: Self.KEY_PURCHASE_DATE) as? Double
            let expirationDate = userDefaults.object(forKey: Self.KEY_EXPIRATION_DATE) as? Double
            
            let tier = SubscriptionTier(rawValue: tierString) ?? .free
            
            let subscription = UserSubscription(
                tier: tier,
                isActive: isActive,
                purchaseDate: purchaseDate,
                expirationDate: expirationDate
            )
            
            logger.debug("📱 Loaded from UserDefaults: \(subscription.tier.rawValue), active: \(subscription.isActive)")
            return subscription
            
        } catch {
            logger.error("❌ Error loading from UserDefaults: \(error.localizedDescription)")
            return UserSubscription()
        }
    }
    
    // MARK: - Firestore Sync
    private func saveSubscriptionToFirestore(userId: String, subscription: UserSubscription) async {
        do {
            logger.debug("☁️ Saving to Firestore for user: \(userId)")
            
            let subscriptionData: [String: Any] = [
                "tier": subscription.tier.rawValue,
                "isActive": subscription.isActive,
                "purchaseDate": subscription.purchaseDate as Any,
                "expirationDate": subscription.expirationDate as Any,
                "lastUpdated": Date().millisecondsSince1970
            ]
            
            try await firestore.collection(Self.COLLECTION_SUBSCRIPTIONS)
                .document(userId)
                .setData(subscriptionData)
            
            logger.debug("☁️ Successfully saved to Firestore")
        } catch {
            logger.error("❌ Error saving to Firestore (non-critical): \(error.localizedDescription)")
        }
    }
    
    private func loadSubscriptionFromFirestore(userId: String) async {
        do {
            logger.debug("☁️ Loading from Firestore for user: \(userId)")
            
            let document = try await firestore.collection(Self.COLLECTION_SUBSCRIPTIONS)
                .document(userId)
                .getDocument()
            
            if document.exists, let data = document.data() {
                let tierString = data["tier"] as? String ?? SubscriptionTier.free.rawValue
                let isActive = data["isActive"] as? Bool ?? false
                let purchaseDate = data["purchaseDate"] as? Double
                let expirationDate = data["expirationDate"] as? Double
                
                let tier = SubscriptionTier(rawValue: tierString) ?? .free
                
                let subscription = UserSubscription(
                    tier: tier,
                    isActive: isActive,
                    purchaseDate: purchaseDate,
                    expirationDate: expirationDate
                )
                
                saveSubscriptionToUserDefaults(subscription)
                subscriptionSubject.send(subscription)
                
                logger.debug("☁️ Loaded from Firestore: \(subscription.tier.rawValue), active: \(subscription.isActive)")
            } else {
                logger.debug("☁️ No subscription document in Firestore")
            }
        } catch {
            logger.error("❌ Error loading from Firestore: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cleanup
    deinit {
        updateListenerTask?.cancel()
    }
}

// MARK: - Error Types
enum SubscriptionError: LocalizedError {
    case productNotFound
    case failedVerification
    case userCancelled
    case purchasePending
    case noActivePurchases
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found in App Store"
        case .failedVerification:
            return "Failed to verify purchase"
        case .userCancelled:
            return "User cancelled the purchase"
        case .purchasePending:
            return "Purchase is pending approval"
        case .noActivePurchases:
            return "No active purchases found to restore"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}