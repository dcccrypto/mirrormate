import SwiftUI

struct OnboardingView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showSignIn = false
    @State private var showSignUp = false
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background.ignoresSafeArea()
            
            AppTheme.Colors.mirrorGradient
                .opacity(0.2)
                .ignoresSafeArea()
                .blur(radius: 80)
            
            VStack(spacing: AppTheme.Spacing.xxl) {
                Spacer()
                
                // Hero Section
                VStack(spacing: AppTheme.Spacing.lg) {
                    // App Icon/Logo
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.primaryGradient)
                            .frame(width: 120, height: 120)
                            .shadow(color: AppTheme.Colors.primary.opacity(0.4), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .breathing()
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Welcome to MirrorMate")
                            .font(AppTheme.Fonts.largeTitle())
                            .foregroundColor(AppTheme.Colors.contrast)
                            .multilineTextAlignment(.center)
                        
                        Text("Your AI-powered reflection coach")
                            .font(AppTheme.Fonts.body())
                            .foregroundColor(AppTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Features
                VStack(spacing: AppTheme.Spacing.md) {
                    FeatureRow(icon: "video.fill", title: "Record & Analyze", description: "Get instant AI feedback")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Track Progress", description: "See your improvement over time")
                    FeatureRow(icon: "crown.fill", title: "Premium Access", description: "Unlimited analyses & insights")
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: AppTheme.Spacing.md) {
                    Button(action: {
                        showSignUp = true
                        HapticFeedback.light.trigger()
                    }) {
                        Text("Get Started")
                            .font(AppTheme.Fonts.headline())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .background(AppTheme.Colors.primaryGradient)
                            .cornerRadius(AppTheme.CornerRadius.md)
                    }
                    .bounceButton()
                    
                    Button(action: {
                        showSignIn = true
                        HapticFeedback.light.trigger()
                    }) {
                        Text("I already have an account")
                            .font(AppTheme.Fonts.bodyMedium())
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 44, height: 44)
                .background(AppTheme.Colors.primary.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.md)
            
            VStack(alignment: .leading, spacing: 2) {
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

