import SwiftUI

struct RecordButton: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(gradient: Gradient(colors: [
                        AppTheme.Colors.primary.opacity(0.9),
                        AppTheme.Colors.accent.opacity(0.9),
                        AppTheme.Colors.primary.opacity(0.9)
                    ]), center: .center)
                )
                .blur(radius: 10)
                .overlay(
                    Circle()
                        .fill(.ultraThinMaterial)
                )

            Circle()
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 2)

            VStack(spacing: 8) {
                Image(systemName: "record.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.Colors.primary)
                Text("Record")
                    .font(AppTheme.Fonts.headline())
                    .foregroundColor(AppTheme.Colors.contrast)
            }
        }
        .frame(width: 180, height: 180)
        .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 16, x: 0, y: 10)
        .padding()
        .accessibilityLabel("Record a new reflection")
    }
}


