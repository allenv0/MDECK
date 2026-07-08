import SwiftUI

struct RotaryKnob: View {
    var size: CGFloat = 20
    var snaps: Int = 12

    @State private var currentAngle: Angle = .degrees(-45)
    @State private var dragStart: CGFloat? = nil

    @Environment(\.palette) private var palette

    private let knobMin: Double = -135
    private let knobMax: Double = 45

    private var snappedAngle: Angle {
        let step = (knobMax - knobMin) / Double(snaps - 1)
        let deg = max(knobMin, min(knobMax, currentAngle.degrees))
        let snapped = knobMin + round((deg - knobMin) / step) * step
        return .degrees(max(knobMin, min(knobMax, snapped)))
    }

    var body: some View {
        let neon = Color(hex: palette.accent2)
        let displayAngle = dragStart != nil ? currentAngle : snappedAngle

        ZStack {
            Circle()
                .fill(Color.black.opacity(0.45))
                .frame(width: size + 6, height: size + 6)
                .blur(radius: 4)
                .offset(y: 2.5)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.62),
                            Color(white: 0.85),
                            Color(white: 0.48),
                            Color(white: 0.30),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size, height: size)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(white: 0.22),
                            Color(white: 0.12),
                            Color(white: 0.06),
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size - 4, height: size - 4)

            Circle()
                .stroke(neon.opacity(dragStart != nil ? 0.4 : 0.1), lineWidth: 1)
                .frame(width: size - 2, height: size - 2)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.06),
                            Color.clear,
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size - 4, height: size - 4)

            RoundedRectangle(cornerRadius: 0.8)
                .fill(Color(white: 0.72))
                .frame(width: 1.5, height: size * 0.26)
                .offset(y: -size * 0.22)
                .rotationEffect(displayAngle)
        }
        .frame(width: size + 6, height: size + 6)
        .gesture(
            DragGesture()
                .onChanged { g in
                    if dragStart == nil { dragStart = g.location.x }
                    let delta = g.location.x - dragStart!
                    let range = knobMax - knobMin
                    let degrees = Double(delta) * (range / 120)
                    let mid = knobMin + range / 2
                    let newDeg = max(knobMin, min(knobMax, mid + degrees))
                    currentAngle = .degrees(newDeg)
                }
                .onEnded { _ in
                    dragStart = nil
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        currentAngle = snappedAngle
                    }
                }
        )
        .accessibilityLabel("Rotary control")
        .accessibilityValue("\(Int((snappedAngle.degrees - knobMin) / (knobMax - knobMin) * 100))%")
        .accessibilityAdjustableAction { direction in
            let step = (knobMax - knobMin) / Double(snaps)
            switch direction {
            case .increment: currentAngle = .degrees(max(knobMin, min(knobMax, currentAngle.degrees + step)))
            case .decrement: currentAngle = .degrees(max(knobMin, min(knobMax, currentAngle.degrees - step)))
            @unknown default: break
            }
        }
    }
}
