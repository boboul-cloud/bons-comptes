//
//  PremiumManager.swift
//  Bons Comptes
//

import Foundation
import StoreKit
import Combine

@MainActor
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    static let productID = "com.bonscomptes.premium"
    static let maxFreeCampaigns = 2

    @Published private(set) var isPremium: Bool = false
    @Published private(set) var product: Product?
    @Published private(set) var purchaseError: String?

    private var transactionListener: Task<Void, Never>?

    init() {
        // Check persisted state first for instant UI
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        transactionListener = listenForTransactions()
        Task { await loadProduct(); await updatePurchaseStatus() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load product from App Store

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase() async {
        if product == nil {
            await loadProduct()
        }
        guard let product else {
            purchaseError = NSLocalizedString("premium_product_unavailable", comment: "")
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                setPremium(true)
            case .userCancelled:
                break
            case .pending:
                purchaseError = NSLocalizedString("premium_purchase_pending", comment: "")
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Restore

    func restore() async {
        await verifyAndSync()
    }

    // MARK: - Transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? await self.checkVerified(result) {
                    await transaction.finish()
                    await MainActor.run { self.setPremium(true) }
                }
            }
        }
    }

    // MARK: - Verify purchase status

    /// Check entitlements: only upgrade to premium, never auto-downgrade
    /// (sandbox may lose transactions on restart). Use verifyAndSync for explicit restore.
    func updatePurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                setPremium(true)
                return
            }
            // Revoked transaction found
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID,
               transaction.revocationDate != nil {
                setPremium(false)
                return
            }
        }
        // No entitlements found — don't downgrade (sandbox may have lost them)
    }

    /// Full sync with App Store — used for explicit "Restore" action
    func verifyAndSync() async {
        try? await AppStore.sync()
        var found = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                found = true
                break
            }
        }
        setPremium(found)
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }

    private func setPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: "isPremium")
    }
}
