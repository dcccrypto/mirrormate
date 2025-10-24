import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var stripe = StripeManager.shared
    @State private var showSignOut = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Profile Header
                    VStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.primaryGradient)
                                .frame(width: 100, height: 100)
                            
                            Text(initials)
                                .font(AppTheme.Fonts.largeTitle())
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: AppTheme.Spacing.xs) {
                            if let name = authService.displayName {
                                Text(name)
                                    .font(AppTheme.Fonts.title2())
                                    .foregroundColor(AppTheme.Colors.contrast)
                            }
                            
                            Text(authService.userEmail ?? "")
                                .font(AppTheme.Fonts.body())
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            
                            // Premium Badge
                            if stripe.isPremium {
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                    Text("Premium")
                                }
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.accent)
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, AppTheme.Spacing.xxs)
                                .background(AppTheme.Colors.accent.opacity(0.15))
                                .cornerRadius(AppTheme.CornerRadius.sm)
                            }
                        }
                    }
                    .padding(.top, AppTheme.Spacing.xl)
                    
                    // Menu Items
                    VStack(spacing: AppTheme.Spacing.sm) {
                        if !stripe.isPremium {
                            NavigationLink(destination: PaywallView()) {
                                MenuRow(
                                    icon: "crown.fill",
                                    title: "Upgrade to Premium",
                                    subtitle: "Unlimited analyses",
                                    color: AppTheme.Colors.accent,
                                    showChevron: true
                                )
                            }
                            .shimmer(duration: 3, delay: 1)
                        } else {
                            Button(action: {
                                Task {
                                    do {
                                        try await stripe.openCustomerPortal()
                                    } catch {
                                        AppLog.error("Failed to open portal: \(error)", category: .network)
                                    }
                                }
                            }) {
                                MenuRow(
                                    icon: "creditcard.fill",
                                    title: "Manage Subscription",
                                    subtitle: "View billing & cancel",
                                    color: AppTheme.Colors.primary,
                                    showChevron: true
                                )
                            }
                        }
                        
                        MenuRow(
                            icon: "chart.bar.fill",
                            title: "Usage Stats",
                            subtitle: "View your quota",
                            color: AppTheme.Colors.primary,
                            showChevron: false
                        )
                        
                        MenuRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            subtitle: "Manage preferences",
                            color: AppTheme.Colors.success,
                            showChevron: false
                        )
                        
                        MenuRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            subtitle: "Get assistance",
                            color: AppTheme.Colors.primary,
                            showChevron: false
                        )
                        
                        MenuRow(
                            icon: "doc.text.fill",
                            title: "Terms & Privacy",
                            subtitle: "Legal information",
                            color: AppTheme.Colors.secondaryText,
                            showChevron: false
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    
                    // Sign Out Button
                    Button(action: {
                        showSignOut = true
                        HapticFeedback.light.trigger()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                            Text("Sign Out")
                        }
                    }
                    .destructiveButtonStyle()
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)
                    
                    // Version Info
                    Text("MirrorMate v1.0.0")
                        .font(AppTheme.Fonts.caption())
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                        .padding(.bottom, AppTheme.Spacing.xxl)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Refresh premium status when profile is viewed
            Task {
                await stripe.checkPremiumStatus()
            }
        }
        .alert("Sign Out", isPresented: $showSignOut) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await authService.signOut()
                    // User will be automatically taken to OnboardingView by MirrorMateApp
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private var initials: String {
        if let name = authService.displayName, !name.isEmpty {
            let components = name.components(separatedBy: " ")
            if components.count >= 2 {
                let first = String(components[0].prefix(1))
                let last = String(components[1].prefix(1))
                return (first + last).uppercased()
            } else {
                return String(name.prefix(2)).uppercased()
            }
        } else if let email = authService.userEmail {
            return String(email.prefix(2)).uppercased()
        }
        return "??"
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let showChevron: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.md)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Fonts.bodyMedium())
                    .foregroundColor(AppTheme.Colors.contrast)
                
                Text(subtitle)
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.lg)
    }
}
