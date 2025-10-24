import Foundation
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let client = SupabaseService.shared.client
    
    private init() {
        Task {
            await checkAuthState()
        }
    }
    
    // MARK: - Auth State
    
    func checkAuthState() async {
        AppLog.info("Checking authentication state", category: .general)
        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
            AppLog.info("User authenticated: \(session.user.id)", category: .general)
        } catch {
            currentUser = nil
            isAuthenticated = false
            AppLog.info("No active session", category: .general)
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, displayName: String?) async throws {
        AppLog.info("Attempting sign up for: \(email)", category: .general)
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: displayName != nil ? ["display_name": .string(displayName!)] : nil
            )
            
            currentUser = response.user
            isAuthenticated = response.session != nil
            
            AppLog.info("✓ Sign up successful: \(response.user.id)", category: .general)
            HapticFeedback.success.trigger()
        } catch {
            AppLog.error("Sign up failed: \(error.localizedDescription)", category: .general)
            HapticFeedback.error.trigger()
            throw error
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        AppLog.info("Attempting sign in for: \(email)", category: .general)
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            currentUser = session.user
            isAuthenticated = true
            
            AppLog.info("✓ Sign in successful: \(session.user.id)", category: .general)
            HapticFeedback.success.trigger()
        } catch {
            AppLog.error("Sign in failed: \(error.localizedDescription)", category: .general)
            HapticFeedback.error.trigger()
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        AppLog.info("Signing out user", category: .general)
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            AppLog.info("✓ Sign out successful", category: .general)
            HapticFeedback.light.trigger()
        } catch {
            AppLog.error("Sign out failed: \(error.localizedDescription)", category: .general)
        }
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        AppLog.info("Requesting password reset for: \(email)", category: .general)
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await client.auth.resetPasswordForEmail(email)
            AppLog.info("✓ Password reset email sent", category: .general)
            HapticFeedback.success.trigger()
        } catch {
            AppLog.error("Password reset failed: \(error.localizedDescription)", category: .general)
            HapticFeedback.error.trigger()
            throw error
        }
    }
    
    // MARK: - User Info
    
    var userId: UUID? {
        guard let user = currentUser else { return nil }
        return UUID(uuidString: user.id.uuidString)
    }
    
    var userEmail: String? {
        currentUser?.email
    }
    
    var displayName: String? {
        currentUser?.userMetadata["display_name"]?.stringValue
    }
}

