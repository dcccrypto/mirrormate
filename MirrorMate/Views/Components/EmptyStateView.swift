import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(AppTheme.Colors.primaryGradient)
                    .symbolEffect(.bounce, value: UUID())
            }
            
            // Text
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Fonts.title2())
                    .foregroundColor(AppTheme.Colors.contrast)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(AppTheme.Fonts.body())
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
            
            // Optional Action Button
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    action()
                    HapticFeedback.light.trigger()
                }) {
                    Text(actionTitle)
                }
                .primaryButtonStyle()
                .padding(.horizontal, AppTheme.Spacing.xxl)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Predefined Empty States
extension EmptyStateView {
    /// Empty history state
    static func noHistory(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "clock.arrow.circlepath",
            title: "No Recordings Yet",
            message: "Your practice sessions will appear here. Start recording to see your progress over time.",
            actionTitle: "Start Recording",
            action: action
        )
    }
    
    /// First time recording state
    static func firstTimeRecording(action: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "video.badge.plus",
            title: "Ready to Practice?",
            message: "Record yourself and get AI-powered feedback on your communication skills, body language, and tone.",
            actionTitle: action != nil ? "Learn How" : nil,
            action: action
        )
    }
    
    /// No search results
    static func noSearchResults() -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search or filters to find what you're looking for."
        )
    }
    
    /// Network error
    static func networkError(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "Connection Error",
            message: "Unable to connect to the server. Please check your internet connection and try again.",
            actionTitle: "Try Again",
            action: action
        )
    }
    
    /// Generic error
    static func genericError(message: String = "Something went wrong. Please try again.", action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "Oops!",
            message: message,
            actionTitle: "Try Again",
            action: action
        )
    }
}

#Preview {
    VStack {
        EmptyStateView.noHistory {
            print("Start recording tapped")
        }
    }
    .background(AppTheme.Colors.background)
}

