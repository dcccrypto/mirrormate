import SwiftUI

struct TagCloudView: View {
    var tags: [String]
    var alignment: HorizontalAlignment = .center

    var body: some View {
        FlowLayout(alignment: alignment, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag.capitalized)
                    .font(AppTheme.Fonts.caption())
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(AppTheme.Colors.primary.opacity(0.08))
                    .foregroundColor(AppTheme.Colors.contrast)
                    .clipShape(Capsule())
            }
        }
    }
}

// Simple flexible flow layout for wrapping content
struct FlowLayout<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(alignment: HorizontalAlignment = .leading, spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            var x: CGFloat = 0
            var y: CGFloat = 0

            ZStack(alignment: .topLeading) {
                content()
                    .fixedSize()
                    .alignmentGuide(.leading) { d in
                        if x + d.width > width {
                            x = 0
                            y -= d.height + spacing
                        }
                        let result = x
                        x += d.width + spacing
                        return -result
                    }
                    .alignmentGuide(.top) { d in
                        let result = y
                        return -result
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }
}


