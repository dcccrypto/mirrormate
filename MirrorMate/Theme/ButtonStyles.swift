import SwiftUI

// MARK: - Primary Button Style
/// Used for main CTAs (Call-to-Action) - one per screen
/// Example: "Share Results", "Upload & Analyze", "Start Recording"
struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Fonts.bodyMedium())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                Group {
                    if isLoading {
                        Color.gray.opacity(0.5)
                    } else {
                        AppTheme.Colors.primaryGradient
                    }
                }
            )
            .cornerRadius(AppTheme.CornerRadius.md)
            .shadow(
                color: isLoading ? .clear : AppTheme.Colors.primary.opacity(0.3),
                radius: 10,
                y: 5
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
            .disabled(isLoading)
    }
}

// MARK: - Secondary Button Style
/// Used for secondary actions
/// Example: "Back to Home", "Cancel", navigation buttons
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Fonts.bodyMedium())
            .foregroundColor(AppTheme.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.primary.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style
/// Used for destructive actions
/// Example: "Sign Out", "Delete", "Clear Data"
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Fonts.bodyMedium())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.error)
            .cornerRadius(AppTheme.CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Tertiary Button Style
/// Used for text-only buttons, less emphasis
/// Example: "Skip", "Learn More", "Not Now"
struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Fonts.body())
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.vertical, AppTheme.Spacing.sm)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style
/// Used for circular icon buttons (toolbar, header)
/// Example: Settings icon, Close button, Navigation icons
struct IconButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppTheme.Colors.secondaryBackground
    var foregroundColor: Color = AppTheme.Colors.contrast
    var size: CGFloat = 44
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(AppTheme.Colors.glassBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Convenience Extensions
extension View {
    func primaryButtonStyle(isLoading: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
    }
    
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func destructiveButtonStyle() -> some View {
        self.buttonStyle(DestructiveButtonStyle())
    }
    
    func tertiaryButtonStyle() -> some View {
        self.buttonStyle(TertiaryButtonStyle())
    }
    
    func iconButtonStyle(
        backgroundColor: Color = AppTheme.Colors.secondaryBackground,
        foregroundColor: Color = AppTheme.Colors.contrast,
        size: CGFloat = 44
    ) -> some View {
        self.buttonStyle(IconButtonStyle(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            size: size
        ))
    }
}

