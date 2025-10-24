import SwiftUI

// MARK: - Haptic Feedback
enum HapticFeedback {
    case light, medium, heavy, soft, rigid
    case success, warning, error
    case selection
    
    func trigger() {
        switch self {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .soft:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        case .rigid:
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 2.0
    var delay: Double = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: -300 + phase * 600)
                .mask(content)
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(Animation.linear(duration: duration).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 2.0, delay: Double = 0) -> some View {
        modifier(ShimmerEffect(duration: duration, delay: delay))
    }
}

// MARK: - Pulse Animation
struct PulseEffect: ViewModifier {
    @State private var scale: CGFloat = 1.0
    var minScale: CGFloat = 0.95
    var maxScale: CGFloat = 1.05
    var duration: Double = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    scale = maxScale
                }
            }
    }
}

extension View {
    func pulse(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        modifier(PulseEffect(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Ripple Effect
struct RippleEffect: View {
    @State private var ripples: [Ripple] = []
    @State private var timer: Timer?
    
    struct Ripple: Identifiable {
        let id = UUID()
        var scale: CGFloat = 0
        var opacity: Double = 1
    }
    
    var body: some View {
        ZStack {
            ForEach(ripples) { ripple in
                Circle()
                    .stroke(AppTheme.Colors.primary.opacity(ripple.opacity), lineWidth: 2)
                    .scaleEffect(ripple.scale)
            }
        }
        .onAppear {
            startRipples()
        }
        .onDisappear {
            stopRipples()
        }
    }
    
    private func startRipples() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [self] _ in
            let newRipple = Ripple()
            ripples.append(newRipple)
            
            withAnimation(.easeOut(duration: 2.0)) {
                if let index = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                    ripples[index].scale = 1.5
                    ripples[index].opacity = 0
                }
            }
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                ripples.removeAll { $0.id == newRipple.id }
            }
        }
    }
    
    private func stopRipples() {
        timer?.invalidate()
        timer = nil
        ripples.removeAll()
    }
}

// MARK: - Breathing Animation
struct BreathingEffect: ViewModifier {
    @State private var scale: CGFloat = 1.0
    var minScale: CGFloat = 0.92
    var maxScale: CGFloat = 1.0
    var duration: Double = 3.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    scale = minScale
                }
            }
    }
}

extension View {
    func breathing(minScale: CGFloat = 0.92, maxScale: CGFloat = 1.0, duration: Double = 3.0) -> some View {
        modifier(BreathingEffect(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Bounce Button
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(AppTheme.Animation.spring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticFeedback.light.trigger()
                }
            }
    }
}

extension View {
    func bounceButton() -> some View {
        self.buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Progress Ring Animation
struct AnimatedProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var color: Color = AppTheme.Colors.primary
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.Animation.smooth, value: animatedProgress)
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = newValue
        }
        .onAppear {
            animatedProgress = progress
        }
    }
}

