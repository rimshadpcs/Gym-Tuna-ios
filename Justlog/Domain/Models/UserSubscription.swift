import Foundation

struct UserSubscription {
    let tier: SubscriptionTier
    let isActive: Bool
    let purchaseDate: TimeInterval?
    let expirationDate: TimeInterval?
    
    init(
        tier: SubscriptionTier = .free,
        isActive: Bool = false,
        purchaseDate: TimeInterval? = nil,
        expirationDate: TimeInterval? = nil
    ) {
        self.tier = tier
        self.isActive = isActive
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
    }
}