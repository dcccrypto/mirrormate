import Foundation
import StoreKit

enum StoreError: LocalizedError {
    case productNotFound
    case userCancelled
    case purchasePending
    case noPreviousPurchases
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not available. Please try again later."
        case .userCancelled:
            return "Purchase cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .noPreviousPurchases:
            return "No previous purchases found for this Apple ID"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published var isPremium: Bool = false
    @Published var products: [Product] = []
    @Published var purchasing: Bool = false

    // Replace with your real product identifier
    private let plusProductId = "mm_plus_monthly"

    private init() {
        Task { await refreshEntitlements(); await loadProducts() }
        Task { await observeTransactions() }
    }

    func loadProducts() async {
        do { products = try await Product.products(for: [plusProductId]) } catch { products = [] }
    }

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == plusProductId {
                isPremium = true
                return
            }
        }
        isPremium = false
    }

    func purchasePlus() async throws {
        guard let product = products.first(where: { $0.id == plusProductId }) else {
            throw StoreError.productNotFound
        }
        purchasing = true
        defer { purchasing = false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                isPremium = true
                await transaction.finish()
            }
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.purchasePending
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    func restorePurchases() async throws {
        purchasing = true
        defer { purchasing = false }
        
        // Sync with App Store
        try await AppStore.sync()
        
        // Refresh entitlements after sync
        await refreshEntitlements()
        
        if !isPremium {
            throw StoreError.noPreviousPurchases
        }
    }

    private func observeTransactions() async {
        for await verification in Transaction.updates {
            if case .verified(let transaction) = verification {
                if transaction.productID == plusProductId { isPremium = true }
                await transaction.finish()
            }
        }
    }
}


