import Foundation
import SwiftUI
import Sentry

@MainActor
final class StripeManager: ObservableObject {
    static let shared = StripeManager()
    
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let supabaseURL = "https://lchudacxfedkylmjbdsz.supabase.co"
    private var checkPremiumTask: Task<Void, Never>?
    
    private init() {
        // Check premium status on init
        Task { await checkPremiumStatus() }
    }
    
    /// Check if the current user has an active subscription
    func checkPremiumStatus() async {
        guard let userId = AuthService.shared.userId else {
            isPremium = false
            return
        }
        
        do {
            // Query subscriptions table directly using Supabase client
            struct SubscriptionStatus: Codable {
                let status: String
            }
            
            let response: [SubscriptionStatus] = try await SupabaseService.shared.client
                .from("subscriptions")
                .select("status")
                .eq("user_id", value: userId)
                .in("status", values: ["active", "trialing"])
                .execute()
                .value
            
            isPremium = !response.isEmpty
            AppLog.info("✅ Premium status: \(isPremium) (found \(response.count) active/trialing subscriptions)", category: .network)
        } catch {
            AppLog.error("❌ Error checking premium status: \(error.localizedDescription)", category: .network)
            SentrySDK.capture(error: error)
            isPremium = false
        }
    }
    
    /// Create a Stripe Checkout session and open it in Safari
    func startCheckout() async throws -> Bool {
        guard let userId = AuthService.shared.userId?.uuidString else {
            throw StripeError.notAuthenticated
        }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            // Get session token
            let session = try await SupabaseService.shared.client.auth.session
            let accessToken = session.accessToken
            
            // Call create-checkout-session function
            let url = URL(string: "\(supabaseURL)/functions/v1/create-checkout-session")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "user_id": userId,
                "success_url": "mirrormate://payment-success",
                "cancel_url": "mirrormate://payment-cancel"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            AppLog.info("Creating Stripe checkout session...", category: .network)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StripeError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    AppLog.error("Checkout failed: \(errorResponse.error)", category: .network)
                    throw StripeError.checkoutFailed(errorResponse.error)
                } else {
                    throw StripeError.checkoutFailed("Status: \(httpResponse.statusCode)")
                }
            }
            
            let checkoutResponse = try JSONDecoder().decode(CheckoutResponse.self, from: data)
            
            guard let checkoutURL = URL(string: checkoutResponse.url) else {
                throw StripeError.invalidURL
            }
            
            AppLog.info("Opening Stripe Checkout in Safari", category: .network)
            
            // Open Safari for payment
            await UIApplication.shared.open(checkoutURL)
            
            return true
        } catch let error as StripeError {
            self.error = error.localizedDescription
            throw error
        } catch {
            self.error = error.localizedDescription
            SentrySDK.capture(error: error)
            throw StripeError.unknown(error.localizedDescription)
        }
    }
    
    /// Open Stripe Customer Portal for managing subscription
    func openCustomerPortal() async throws {
        guard let userId = AuthService.shared.userId?.uuidString else {
            throw StripeError.notAuthenticated
        }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseService.shared.client.auth.session
            let accessToken = session.accessToken
            
            let url = URL(string: "\(supabaseURL)/functions/v1/create-portal-session")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "user_id": userId,
                "return_url": "mirrormate://settings"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StripeError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw StripeError.portalFailed(errorResponse.error)
                } else {
                    throw StripeError.portalFailed("Status: \(httpResponse.statusCode)")
                }
            }
            
            let portalResponse = try JSONDecoder().decode(PortalResponse.self, from: data)
            
            guard let portalURL = URL(string: portalResponse.url) else {
                throw StripeError.invalidURL
            }
            
            await UIApplication.shared.open(portalURL)
        } catch let error as StripeError {
            self.error = error.localizedDescription
            throw error
        } catch {
            self.error = error.localizedDescription
            SentrySDK.capture(error: error)
            throw StripeError.unknown(error.localizedDescription)
        }
    }
    
    /// Handle deep link return from Stripe
    func handleDeepLink(url: URL) async {
        AppLog.info("Handling deep link: \(url.absoluteString)", category: .network)
        
        if url.absoluteString.contains("payment-success") {
            // Payment succeeded, refresh premium status
            AppLog.info("Payment succeeded, checking premium status...", category: .network)
            
            // Wait a moment for webhook to process
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await checkPremiumStatus()
            
            if isPremium {
                HapticFeedback.success.trigger()
            }
        } else if url.absoluteString.contains("payment-cancel") {
            AppLog.info("Payment cancelled", category: .network)
        }
    }
}

// MARK: - Response Models

struct CheckoutResponse: Codable {
    let url: String
}

struct PortalResponse: Codable {
    let url: String
}

struct ErrorResponse: Codable {
    let error: String
}

// MARK: - Errors

enum StripeError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case invalidURL
    case checkoutFailed(String)
    case portalFailed(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidURL:
            return "Invalid payment URL"
        case .checkoutFailed(let message):
            return "Payment setup failed: \(message)"
        case .portalFailed(let message):
            return "Portal failed: \(message)"
        case .unknown(let message):
            return "An error occurred: \(message)"
        }
    }
}

