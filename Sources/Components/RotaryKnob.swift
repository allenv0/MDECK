import SwiftUI

struct RotaryKnob: View {
    var size: CGFloat = 20
    var snaps: Int = 12

    @State private var currentAngle: Angle = .degrees(-45)
    @State private var dragStart: CGFloat? = nil

    private let knobMin: Double = -135
    private let knobMax: Double = 45

    private var snappedAngle: Angle {
        let step = (knobMax - knobMin) / Double(snaps - 1)
        let deg = max(knobMin, min(knobMax, currentAngle.degrees))
        let snapped = knobMin + round((deg - knobMin) / step) * step
        return .degrees(max(knobMin, min(knobMax, snapped)))
    }

    var body: some View {
        let neon = Theme.accent2
        let displayAngle = dragStart != nil ? currentAngle : snappedAngle

        ZStack {
            Circle()
                .fill(Color.black.opacity(Elevation.shadowOpacity))
                .frame(width: size + 6, height: size + 6)
                .blur(radius: Elevation.shadowBlur)
                .offset(y: Elevation.shadowOffset)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: Elevation.rimLight),
                            Color(white: Elevation.rimMid),
                            Color(white: Elevation.rimShadow),
                            Color(white: Elevation.rimDark),
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
                            Color(white: Elevation.innerLight),
                            Color(white: Elevation.innerMid),
                            Color(white: Elevation.innerDark),
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
                .fill(Color(white: Elevation.indicator))
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
                    let prevSnap = snappedAngle
                    dragStart = nil
                    withAnimation(Anim.snap) {
                        currentAngle = snappedAngle
                    }
                    if prevSnap.degrees != snappedAngle.degrees {
                        NSHapticFeedbackManager.defaultPerformer.perform(
                            .alignment, performanceTime: .default)
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
