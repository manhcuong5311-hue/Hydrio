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

@MainActor
final class StoreManager: ObservableObject {

    // ── Product ID — must match App Store Connect exactly ─────────
    static let lifetimeProductID = "com.hydrio.premium.lifetime"

    // ── Published ──────────────────────────────────────────────────
    @Published private(set) var product: Product?
    @Published private(set) var isPremium: Bool
    @Published var purchaseState: PurchaseState = .idle

    // ── Private ────────────────────────────────────────────────────
    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        // Read persisted state so UI is correct before network call
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")

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

    // MARK: - Load Product

    func loadProduct() async {
        do {
            let results = try await Product.products(for: [Self.lifetimeProductID])
            product = results.first
        } catch {
            print("[StoreManager] loadProduct error: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    func purchase() async {
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
                await deliver(transaction)
                await transaction.finish()
                purchaseState = .idle

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                // awaiting Ask-to-Buy or similar — no action needed
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
            purchaseState = isPremium
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
        var hasActive = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? verified(result),
               transaction.productID == Self.lifetimeProductID,
               transaction.revocationDate == nil {
                hasActive = true
            }
        }
        persist(isPremium: hasActive)
    }

    // MARK: - Internal Helpers

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard let transaction = try? verified(result) else { return }
        await deliver(transaction)
        await transaction.finish()
    }

    private func deliver(_ transaction: StoreKit.Transaction) async {
        guard transaction.productID == Self.lifetimeProductID else { return }
        persist(isPremium: transaction.revocationDate == nil)
    }

    private func persist(isPremium value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: "isPremium")
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let payload): return payload
        }
    }
}
