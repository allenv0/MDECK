import SwiftUI

struct PowerLED: View {
    @Environment(\.palette) private var palette
    var isActive: Bool = true

    var body: some View {
        let neon = Color(hex: palette.accent2)
        ZStack {
            Circle()
                .fill(neon.opacity(isActive ? 0.08 : 0.005))
                .frame(width: 22, height: 22)
                .blur(radius: 8)
            Circle()
                .fill(neon.opacity(isActive ? 0.2 : 0.02))
                .frame(width: 10, height: 10)
                .blur(radius: 3)
            Circle()
                .fill(isActive ? .clear : Color(white: 0.08))
                .frame(width: 4, height: 4)
            Circle()
                .fill(isActive ? neon : Color(white: 0.12))
                .frame(width: 4, height: 4)
            if isActive {
                Circle()
                    .fill(.white.opacity(0.8))
                    .frame(width: 1.5, height: 1.5)
                    .offset(x: -0.7, y: -0.7)
            }
        }
        .accessibilityLabel(isActive ? "Playing" : "Idle")
    }
}
