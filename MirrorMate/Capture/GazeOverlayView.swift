import SwiftUI

struct GazeOverlayView: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(AppTheme.Colors.primary.opacity(0.25), lineWidth: 2)
                .frame(width: 140, height: 140)
            Circle()
                .strokeBorder(AppTheme.Colors.primary.opacity(0.15), lineWidth: 2)
                .frame(width: 220, height: 220)
        }
        .accessibilityHidden(true)
    }
}


