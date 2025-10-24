import SwiftUI

struct AppTheme {
    struct Colors {
        // Primary palette
        static let primary = Color(hex: "#4E8DF5")
        static let primaryLight = Color(hex: "#6FA3FF")
        static let accent = Color(hex: "#FFC857")
        static let accentLight = Color(hex: "#FFD574")
        
        // Semantic colors
        static var background: Color { Color(.systemBackground) }
        static var secondaryBackground: Color { Color(.secondarySystemBackground) }
        static var tertiaryBackground: Color { Color(.tertiarySystemBackground) }
        static var contrast: Color { Color(.label) }
        static var secondaryText: Color { Color(.secondaryLabel) }
        static var tertiaryText: Color { Color(.tertiaryLabel) }
        
        static let success = Color(hex: "#00D47E")
        static let successLight = Color(hex: "#1FE794")
        static let error = Color(hex: "#E45865")
        static let warning = Color(hex: "#FF9F40")
        
        // Mirror theme - calm, reflective
        static let mirrorGlow = Color(hex: "#E0F2FE")
        static let mirrorShimmer = Color(hex: "#BAE6FD")
        
        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [primary, primaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            colors: [accent, accentLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let successGradient = LinearGradient(
            colors: [success, successLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let mirrorGradient = LinearGradient(
            colors: [mirrorGlow, mirrorShimmer.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Glass effect colors
        static let glassFrost = Color.white.opacity(0.08)
        static let glassBorder = Color.white.opacity(0.2)
    }

    struct Fonts {
        // Using SF Pro (system) with refined weights
        static func largeTitle() -> Font { .system(size: 34, weight: .bold, design: .rounded) }
        static func title() -> Font { .system(size: 28, weight: .semibold, design: .rounded) }
        static func title2() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
        static func headline() -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
        static func body() -> Font { .system(size: 17, weight: .regular, design: .rounded) }
        static func bodyMedium() -> Font { .system(size: 17, weight: .medium, design: .rounded) }
        static func callout() -> Font { .system(size: 16, weight: .regular, design: .rounded) }
        static func subheadline() -> Font { .system(size: 15, weight: .regular, design: .rounded) }
        static func footnote() -> Font { .system(size: 13, weight: .regular, design: .rounded) }
        static func caption() -> Font { .system(size: 12, weight: .regular, design: .rounded) }
        static func caption2() -> Font { .system(size: 11, weight: .regular, design: .rounded) }
        
        // Special fonts
        static func aiText() -> Font { .system(size: 17, weight: .regular, design: .serif) }
        static func number() -> Font { .system(size: 48, weight: .bold, design: .rounded).monospacedDigit() }
    }
    
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.65)
    }
    
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let round: CGFloat = 999
    }
}

extension Color {
    init(hex: String) {
        let r, g, b, a: Double
        var hexString = hex
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            switch hexString.count {
            case 8:
                r = Double((hexNumber & 0xff000000) >> 24) / 255
                g = Double((hexNumber & 0x00ff0000) >> 16) / 255
                b = Double((hexNumber & 0x0000ff00) >> 8) / 255
                a = Double(hexNumber & 0x000000ff) / 255
            case 6:
                r = Double((hexNumber & 0xff0000) >> 16) / 255
                g = Double((hexNumber & 0x00ff00) >> 8) / 255
                b = Double(hexNumber & 0x0000ff) / 255
                a = 1.0
            default:
                r = 0; g = 0; b = 0; a = 1
            }
        } else {
            r = 0; g = 0; b = 0; a = 1
        }
        self = Color(.displayP3, red: r, green: g, blue: b, opacity: a)
    }
}

struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
    }
}

extension View {
    func glassBackground() -> some View { modifier(GlassBackground()) }
}


