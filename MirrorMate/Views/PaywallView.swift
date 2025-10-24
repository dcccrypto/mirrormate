import SwiftUI
import PostHog

struct PaywallView: View {
    @StateObject private var stripe = StripeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.accentGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: AppTheme.Colors.accent.opacity(0.4), radius: 20)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .padding(.top, AppTheme.Spacing.xl)
                        
                        Text("MirrorMate Premium")
                            .font(AppTheme.Fonts.largeTitle())
                            .foregroundColor(AppTheme.Colors.contrast)
                        
                        Text("Unlock unlimited analyses and advanced insights")
                            .font(AppTheme.Fonts.body())
                            .foregroundColor(AppTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                    
                    // Features List
                    VStack(spacing: AppTheme.Spacing.md) {
                        PaywallFeatureRow(
                            icon: "infinity",
                            title: "Unlimited Analyses",
                            description: "Record and analyze as many videos as you want"
                        )
                        
                        PaywallFeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Advanced Analytics",
                            description: "Deep insights into your communication patterns"
                        )
                        
                        PaywallFeatureRow(
                            icon: "waveform.badge.magnifyingglass",
                            title: "Detailed Feedback",
                            description: "AI-powered recommendations for improvement"
                        )
                        
                        PaywallFeatureRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Progress Tracking",
                            description: "Watch your confidence grow over time"
                        )
                        
                        PaywallFeatureRow(
                            icon: "sparkles",
                            title: "Priority Support",
                            description: "Get help when you need it most"
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    
                    // Pricing
                    VStack(spacing: AppTheme.Spacing.lg) {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Text("$9.99")
                                .font(AppTheme.Fonts.title())
                                .foregroundColor(AppTheme.Colors.contrast)
                            
                            Text("per month")
                                .font(AppTheme.Fonts.subheadline())
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        .padding(.vertical, AppTheme.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.secondaryBackground)
                        .cornerRadius(AppTheme.CornerRadius.lg)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        
                        // Subscribe Button
                        Button(action: {
                            Task { await handlePurchase() }
                        }) {
                            HStack {
                                if stripe.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "crown.fill")
                                    Text("Start Premium")
                                }
                            }
                        }
                        .primaryButtonStyle(isLoading: stripe.isLoading)
                        .disabled(stripe.isLoading)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        
                        // Manage Subscription Button (if premium)
                        if stripe.isPremium {
                            Button(action: {
                                Task { await handleManageSubscription() }
                            }) {
                                Text("Manage Subscription")
                                    .font(AppTheme.Fonts.subheadline())
                                    .foregroundColor(AppTheme.Colors.primary)
                            }
                            .disabled(stripe.isLoading)
                        }
                        
                        // Fine Print
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("Cancel anytime from your subscription settings")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.tertiaryText)
                            
                            Text("Subscription auto-renews unless cancelled 24 hours before period ends")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.tertiaryText)
                            
                            Text("Secure payment powered by Stripe")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.tertiaryText)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.bottom, AppTheme.Spacing.xxl)
                    }
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                        HapticFeedback.light.trigger()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.Colors.contrast)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                Task {
                    await stripe.checkPremiumStatus()
                }
                
                // Track paywall shown
                PostHogSDK.shared.capture("paywall_shown", properties: [
                    "is_premium": stripe.isPremium
                ])
            }
        }
    }
    
    private func handlePurchase() async {
        do {
            let success = try await stripe.startCheckout()
            if success {
                HapticFeedback.light.trigger()
                
                // Track subscription purchase initiated
                PostHogSDK.shared.capture("subscription_purchased", properties: [
                    "product_id": "mirrormate_premium_monthly",
                    "price": 9.99,
                    "currency": "USD"
                ])
                
                // Don't dismiss yet - wait for payment completion
                // User will be redirected back via deep link
            }
        } catch {
            HapticFeedback.error.trigger()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleManageSubscription() async {
        do {
            try await stripe.openCustomerPortal()
            HapticFeedback.light.trigger()
        } catch {
            HapticFeedback.error.trigger()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primary.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Fonts.bodyMedium())
                    .foregroundColor(AppTheme.Colors.contrast)
                
                Text(description)
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.lg)
    }
}
