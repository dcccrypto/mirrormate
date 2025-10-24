//
//  MirrorMateApp.swift
//  MirrorMate
//
//  Created by Khubair Nasir M Nazir on 15/10/2025.
//

import SwiftUI
import Sentry
import PostHog

@main
struct MirrorMateApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var stripe = StripeManager.shared
    
    init() {
        // Initialize Sentry for crash reporting
        SentrySDK.start { options in
            // Replace with your actual Sentry DSN
            options.dsn = "https://7d0005bc0b05dd9764e83b784d61b732@o4510225747738624.ingest.de.sentry.io/4510225752653904"
            options.debug = false // Set to true for development
            options.tracesSampleRate = 1.0
            
            // Capture breadcrumbs for better debugging
            options.enableAutoSessionTracking = true
            options.enableCaptureFailedRequests = true
        }
        
        AppLog.info("Sentry initialized for crash reporting", category: .general)
        
        // Initialize PostHog for analytics
        let config = PostHogConfig(apiKey: "phc_e8y5oYeF4FVQqIDla7u3MLxHmkESq96AFGjGYSFAIwk", host: "https://app.posthog.com")
        PostHogSDK.shared.setup(config)
        
        AppLog.info("PostHog initialized for analytics", category: .general)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .environmentObject(authService)
                } else {
                    OnboardingView()
                        .environmentObject(authService)
                }
            }
            .onAppear {
                AppLog.info("MirrorMate app launched", category: .general)
                
                // Track app opened
                PostHogSDK.shared.capture("app_opened", properties: [
                    "is_authenticated": authService.isAuthenticated,
                    "is_premium": stripe.isPremium
                ])
            }
            .onOpenURL { url in
                Task {
                    await stripe.handleDeepLink(url: url)
                }
            }
        }
    }
}
