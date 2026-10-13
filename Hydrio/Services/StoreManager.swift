import StoreKit
import SwiftUI
import Combine

// MARK: - Purchase State

enum PurchaseState: Equatable {
    case idle
    case purchasing
    case restoring
    case failed(String)

    var isLoading: Bool { self == .purchasing || self == .restoring }

    var errorMessage: String? {
        guard case .failed(let msg) = self else { return nil }
        return msg
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.purchasing, .purchasing), (.restoring, .restoring): return true
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Store Manager

/// Every feature in Hydrio is free. The only In-App Purchase is a one-time,
/// non-consumable "Remove Ads" unlock.
@MainActor
final class StoreManager: ObservableObject {

    // ── Product ID — must match App Store Connect exactly ─────────
    /// Reuses the original "Lifetime Premium" product (now sold as "Remove Ads"),
    /// so everyone who bought Premium in 1.0 is automatically ad-free.
    static let removeAdsProductID = "com.hydrio.premium.lifetime"

    // ── Published ──────────────────────────────────────────────────
    @Published private(set) var product: Product?
    @Published private(set) var isLoadingProduct = false
    /// True when the user owns the Remove Ads product (verified, not revoked).
    @Published private(set) var isAdFree: Bool
    @Published var purchaseState: PurchaseState = .idle

    // ── Private ────────────────────────────────────────────────────
    private enum Keys {
        static let isAdFree = "isAdFree"
        /// Cache key used by 1.0 when the product unlocked "Premium".
        static let legacyIsPremium = "isPremium"
    }

    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        // Read persisted state so the UI (and ads) are correct before StoreKit answers.
        isAdFree = Self.migratedCachedAdFree()

        // Listener MUST be created before the first `await`
        transactionListenerTask = Task { [weak self] in
            for await verificationResult in StoreKit.Transaction.updates {
                await self?.handle(verificationResult)
            }
        }

        Task {
            await loadProduct()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    /// Moves the 1.0 "isPremium" cache to the new "isAdFree" key, so existing
    /// buyers never see an ad — not even before StoreKit re-verifies them.
    private static func migratedCachedAdFree() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.legacyIsPremium) != nil {
            if defaults.bool(forKey: Keys.legacyIsPremium) {
                defaults.set(true, forKey: Keys.isAdFree)
            }
            defaults.removeObject(forKey: Keys.legacyIsPremium)
        }
        return defaults.bool(forKey: Keys.isAdFree)
    }

    // MARK: - Load Product

    func loadProduct() async {
        guard product == nil, !isLoadingProduct else { return }
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        do {
            let results = try await Product.products(for: [Self.removeAdsProductID])
            product = results.first
        } catch {
            print("[StoreManager] loadProduct error: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    func purchase() async {
        if product == nil { await loadProduct() }
        guard let product else {
            purchaseState = .failed("Product unavailable. Check your connection and try again.")
            return
        }

        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                deliver(transaction)
                await transaction.finish()
                purchaseState = .idle

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                // Awaiting Ask-to-Buy or similar — `Transaction.updates` delivers it later.
                purchaseState = .idle

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Restore

    func restore() async {
        purchaseState = .restoring
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseState = isAdFree
                ? .idle
                : .failed("No previous purchases found for this Apple ID.")
        } catch {
            purchaseState = .failed("Restore failed. Please try again.")
        }
    }

    func resetState() {
        purchaseState = .idle
    }

    // MARK: - Check Current Entitlements

    func refreshEntitlements() async {
        var ownsRemoveAds = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? verified(result),
               transaction.productID == Self.removeAdsProductID,
               transaction.revocationDate == nil {
                ownsRemoveAds = true
            }
        }
        persist(isAdFree: ownsRemoveAds)
    }

    // MARK: - Internal Helpers

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard let transaction = try? verified(result) else { return }
        deliver(transaction)
        await transaction.finish()
    }

    private func deliver(_ transaction: StoreKit.Transaction) {
        guard transaction.productID == Self.removeAdsProductID else { return }
        persist(isAdFree: transaction.revocationDate == nil)
    }

    private func persist(isAdFree value: Bool) {
        if isAdFree != value { isAdFree = value }
        UserDefaults.standard.set(value, forKey: Keys.isAdFree)
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let payload): return payload
        }
    }
}
