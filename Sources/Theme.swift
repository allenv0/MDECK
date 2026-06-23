import SwiftUI

// Nothing / nullframe design language.
// Pure black panel, off-white dots, "brand red exactly once".
enum Theme {
    static let bg          = Color(red: 0.04, green: 0.04, blue: 0.045)   // near-black panel
    static let panel       = Color(red: 0.07, green: 0.07, blue: 0.078)   // raised card
    static let panelStroke = Color.white.opacity(0.06)
    static let dotOn       = Color(red: 0.92, green: 0.92, blue: 0.93)     // lit dot
    static let dotOff      = Color.white.opacity(0.055)                    // unlit dot ghost
    static let ink         = Color(red: 0.86, green: 0.86, blue: 0.87)
    static let inkDim      = Color.white.opacity(0.42)
    static let inkFaint    = Color.white.opacity(0.22)
    static let red         = Color(red: 0.86, green: 0.12, blue: 0.10)     // used exactly once: the active accent
    static let grid: CGFloat = 16                                          // 16px base grid
}

extension Font {
    // Space Mono / Space Grotesk if installed; otherwise a clean monospace fallback.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        if NSFont(name: "Space Mono", size: size) != nil {
            return .custom("Space Mono", size: size)
        }
        return .system(size: size, weight: weight, design: .monospaced)
    }
    static func grotesk(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        if NSFont(name: "Space Grotesk", size: size) != nil {
            return .custom("Space Grotesk", size: size)
        }
        return .system(size: size, weight: weight, design: .default)
    }
}

// A panel card on the bento grid.
struct Panel<Content: View>: View {
    var label: String? = nil
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let label {
                Text(label.uppercased())
                    .font(.mono(9, .regular))
                    .tracking(2.2)
                    .foregroundStyle(Theme.inkFaint)
            }
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.panelStroke, lineWidth: 1)
        )
    }
}
