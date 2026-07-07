import SwiftUI

struct RotaryKnob: View {
    var size: CGFloat = 20
    var tickAngle: Angle = .degrees(-45)

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.35))
                .frame(width: size + 2, height: size + 2)
                .blur(radius: 2)
                .offset(y: 1)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.55),
                            Color(white: 0.70),
                            Color(white: 0.45),
                            Color(white: 0.35),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: size, height: size)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(white: 0.22),
                            Color(white: 0.12),
                            Color(white: 0.08),
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size - 5, height: size - 5)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.clear,
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size - 5, height: size - 5)

            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.65))
                .frame(width: 2, height: size * 0.3)
                .offset(y: -size * 0.22)
                .rotationEffect(tickAngle)
        }
        .frame(width: size + 4, height: size + 4)
    }
}
