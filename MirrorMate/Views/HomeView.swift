import SwiftUI

/// ⚠️ NOTE: This view is NOT currently used in the app.
/// The app now uses MainTabView as the root navigation.
/// This view is kept for potential future use as an onboarding/welcome screen.
/// Last used: Before TabView implementation (Phase 1)

struct HomeView: View {
    @State private var showMirrorGlow = false
    @State private var showProfile = false
    @StateObject private var sessionStore = SessionStore.shared
    @StateObject private var authService = AuthService.shared
    
    // Get real recent session data (no fake data!)
    private var recentSession: SessionRecord? {
        sessionStore.sessions.first
    }
    
    private var recentTags: [String] {
        recentSession?.impressionTags ?? []
    }
    
    private var recentConfidence: Int {
        recentSession?.confidenceScore ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background with subtle gradient
                AppTheme.Colors.background.ignoresSafeArea()
                
                AppTheme.Colors.mirrorGradient
                    .opacity(0.15)
                    .ignoresSafeArea()
                    .blur(radius: 60)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MirrorMate")
                                    .font(AppTheme.Fonts.largeTitle())
                                    .foregroundColor(AppTheme.Colors.contrast)
                                Text("Your digital reflection")
                                    .font(AppTheme.Fonts.subheadline())
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                            }
                            Spacer()
                            HStack(spacing: AppTheme.Spacing.sm) {
                                NavigationLink(destination: HistoryView()) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.contrast)
                                        .frame(width: 44, height: 44)
                                        .background(AppTheme.Colors.secondaryBackground)
                                        .clipShape(Circle())
                                }
                                .bounceButton()
                                
                                Button(action: {
                                    showProfile = true
                                    HapticFeedback.light.trigger()
                                }) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.contrast)
                                        .frame(width: 44, height: 44)
                                        .background(AppTheme.Colors.secondaryBackground)
                                        .clipShape(Circle())
                                }
                                .bounceButton()
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.md)
                        
                        // Recent Score Card (if available)
                        if recentConfidence > 0 {
                            RecentScoreCard(confidence: recentConfidence, tags: recentTags)
                                .padding(.horizontal, AppTheme.Spacing.lg)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer().frame(height: AppTheme.Spacing.xxl)
                        
                        // Mirror Record Button
                        VStack(spacing: AppTheme.Spacing.lg) {
                            NavigationLink(destination: RecordView()) {
                                ZStack {
                                    // Glow effect
                                    Circle()
                                        .fill(AppTheme.Colors.primary.opacity(showMirrorGlow ? 0.3 : 0.1))
                                        .frame(width: 200, height: 200)
                                        .blur(radius: 30)
                                        .scaleEffect(showMirrorGlow ? 1.2 : 1.0)
                                        .animation(AppTheme.Animation.smooth.repeatForever(autoreverses: true), value: showMirrorGlow)
                                    
                                    // Main button
                                    Circle()
                                        .fill(AppTheme.Colors.primaryGradient)
                                        .frame(width: 160, height: 160)
                                        .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 20, x: 0, y: 10)
                                        .overlay(
                                            Circle()
                                                .stroke(AppTheme.Colors.glassBorder, lineWidth: 1.5)
                                        )
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "video.fill")
                                            .font(.system(size: 40, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Record")
                                            .font(AppTheme.Fonts.headline())
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .bounceButton()
                            
                            VStack(spacing: AppTheme.Spacing.xxs) {
                                Text("Your reflection is ready")
                                    .font(AppTheme.Fonts.headline())
                                    .foregroundColor(AppTheme.Colors.contrast)
                                Text("Small tweaks. Big impact.")
                                    .font(AppTheme.Fonts.subheadline())
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                            }
                        }
                        
                        Spacer().frame(height: AppTheme.Spacing.xl)
                        
                        // Stats or Tips Section
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("💡 Quick Tip")
                                .font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.contrast)
                            
                            Text("Maintain eye contact with the camera — it helps you appear more confident and engaged.")
                                .font(AppTheme.Fonts.body())
                                .foregroundColor(AppTheme.Colors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(AppTheme.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.Colors.secondaryBackground)
                        .cornerRadius(AppTheme.CornerRadius.xl)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        
                        Spacer().frame(height: AppTheme.Spacing.xxl)
                    }
                }
            }
            .onAppear {
                showMirrorGlow = true
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }
    
}

struct RecentScoreCard: View {
    let confidence: Int
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Last Session")
                    .font(AppTheme.Fonts.headline())
                    .foregroundColor(AppTheme.Colors.contrast)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            HStack(spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(confidence)")
                        .font(AppTheme.Fonts.number())
                        .foregroundColor(AppTheme.Colors.primary)
                    Text("Confidence")
                        .font(AppTheme.Fonts.caption())
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                
                Divider()
                    .frame(height: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    TagCloudView(tags: tags)
                    Text("Impressions")
                        .font(AppTheme.Fonts.caption())
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                .fill(AppTheme.Colors.secondaryBackground)
                .shadow(color: AppTheme.Colors.primary.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}


