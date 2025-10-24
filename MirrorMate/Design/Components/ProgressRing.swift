import SwiftUI

struct ProgressRing: View {
    var progress: Double // 0.0 ... 1.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.08), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [
                        AppTheme.Colors.primary,
                        AppTheme.Colors.accent
                    ]), center: .center),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)
        }
        .frame(width: 64, height: 64)
        .accessibilityLabel("Progress")
    }
}


