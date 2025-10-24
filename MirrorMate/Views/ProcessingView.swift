import SwiftUI

struct ProcessingView: View {
    let sessionId: String
    @State private var progress: Double = 0
    @State private var errorMessage: String? = nil
    @State private var navigateToResults = false
    @State private var report: AnalysisReport? = nil
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background.ignoresSafeArea()
            
            // Subtle gradient
            AppTheme.Colors.mirrorGradient
                .opacity(0.2)
                .ignoresSafeArea()
                .blur(radius: 80)
            
            VStack(spacing: AppTheme.Spacing.xxl) {
                Spacer()
                
                // AI Pulse Animation
                ZStack {
                    // Outer ripples
                    RippleEffect()
                        .frame(width: 200, height: 200)
                    
                    // Main pulse circle
                    Circle()
                        .fill(AppTheme.Colors.primaryGradient)
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                        .shadow(color: AppTheme.Colors.primary.opacity(0.5), radius: 30, x: 0, y: 15)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.Colors.glassBorder, lineWidth: 2)
                                .scaleEffect(pulseScale)
                        )
                    
                    // AI Icon
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.white)
                            .symbolEffect(.pulse, options: .repeating)
                        
                        Text("AI")
                            .font(AppTheme.Fonts.title2())
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .onAppear {
                    withAnimation(AppTheme.Animation.smooth.repeatForever(autoreverses: true)) {
                        pulseScale = 1.08
                    }
                }
                
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Analyzing your reflection")
                        .font(AppTheme.Fonts.title2())
                        .foregroundColor(AppTheme.Colors.contrast)
                        .multilineTextAlignment(.center)
                    
                    Text(statusMessage)
                        .font(AppTheme.Fonts.body())
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                }
                
                // Progress indicator
                VStack(spacing: AppTheme.Spacing.sm) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .fill(AppTheme.Colors.tertiaryBackground)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .fill(AppTheme.Colors.primaryGradient)
                            .frame(width: max(40, UIScreen.main.bounds.width * 0.7 * progress), height: 8)
                            .animation(AppTheme.Animation.smooth, value: progress)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.7)
                    
                    Text("\(Int(progress * 100))%")
                        .font(AppTheme.Fonts.caption())
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .monospacedDigit()
                }
                
                if let error = errorMessage {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text(error)
                            .foregroundColor(AppTheme.Colors.error)
                            .font(AppTheme.Fonts.body())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                        
                        Button(action: { /* Retry logic */ }) {
                            Text("Try Again")
                                .font(AppTheme.Fonts.bodyMedium())
                                .foregroundColor(.white)
                                .padding(.horizontal, AppTheme.Spacing.xl)
                                .padding(.vertical, AppTheme.Spacing.sm)
                                .background(AppTheme.Colors.primary)
                                .cornerRadius(AppTheme.CornerRadius.md)
                        }
                        .bounceButton()
                    }
                }
                
                Spacer()
            }
        }
        .task { await pollUntilComplete() }
        .navigationDestination(isPresented: $navigateToResults) {
            if let report { ResultsView(report: report) }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                    HapticFeedback.light.trigger()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
    }
    
    private var statusMessage: String {
        if progress < 0.3 {
            return "Processing video..."
        } else if progress < 0.6 {
            return "Analyzing tone and speech..."
        } else if progress < 0.9 {
            return "Generating insights..."
        } else {
            return "Almost done!"
        }
    }

    private func pollUntilComplete() async {
        AppLog.info("⏳ Starting analysis polling for session: \(sessionId)", category: .analysis)
        let startTime = Date()
        
        do {
            var attempts = 0
            while attempts < 240 { // up to ~2 minutes (4 minutes total)
                let status = try await ApiClient.shared.status(sessionId: sessionId)
                progress = status.progress
                
                let elapsed = Int(Date().timeIntervalSince(startTime))
                AppLog.debug("Poll #\(attempts + 1): \(status.status) (\(Int(status.progress * 100))%) - elapsed: \(elapsed)s", category: .analysis)
                
                if status.state == .complete {
                    AppLog.info("✓ Analysis complete! Fetching report...", category: .analysis)
                    let r = try await ApiClient.shared.report(sessionId: sessionId)
                    report = r
                    
                    AppLog.info("Saving report to CoreData...", category: .storage)
                    await MainActor.run { SessionStore.shared.saveReport(r) }
                    
                    let totalTime = Int(Date().timeIntervalSince(startTime))
                    AppLog.info("🎉 Full analysis flow completed in \(totalTime)s", category: .analysis)
                    navigateToResults = true
                    return
                }
                
                if status.state == .error {
                    AppLog.error("Analysis failed with error state", category: .analysis)
                    throw URLError(.badServerResponse)
                }
                
                try await Task.sleep(nanoseconds: 1_000_000_000)
                attempts += 1
            }
            
            let totalTime = Int(Date().timeIntervalSince(startTime))
            AppLog.warning("⏰ Analysis timeout after \(totalTime)s (\(attempts) polls)", category: .analysis)
            errorMessage = "Analysis is taking longer than expected. Please check back in a few minutes."
        } catch {
            let totalTime = Int(Date().timeIntervalSince(startTime))
            AppLog.error("Analysis polling error after \(totalTime)s: \(error.localizedDescription)", category: .analysis)
            errorMessage = "We encountered an issue analyzing your video. Please try again."
        }
    }
}


