import SwiftUI
import AppKit

struct EQBandKnob: View {
    @Binding var value: Float
    var label: String = ""
    var index: Int = 0
    var total: Int = 10
    var size: CGFloat = 34
    @Environment(\.palette) private var palette  // force re-render on theme change

    @State private var dragStart: CGFloat? = nil
    @State private var dragStartValue: Float = 0
    @State private var hovering: Bool = false

    private let minGain: Double = -12
    private let maxGain: Double = 12
    private let knobMin: Double = -135
    private let knobMax: Double = 45

    private var angle: Double {
        let t = (Double(value) - minGain) / (maxGain - minGain)
        return knobMin + t * (knobMax - knobMin)
    }

    private var bandColor: Color {
        let t = Double(index) / Double(max(1, total - 1))
        switch t {
        case ..<0.34: return Theme.bandLow
        case ..<0.67: return Theme.bandMid
        case ..<0.84: return Theme.bandHigh
        default:      return Theme.bandPeak
        }
    }

    private var atCenter: Bool { abs(Double(value)) < 0.25 }

    var body: some View {
        let _ = palette  // read to register environment dependency
        let neon = Theme.accent2
        let active = dragStart != nil

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
                .stroke(neon.opacity(active ? 0.4 : 0.1), lineWidth: 1)
                .frame(width: size - 2, height: size - 2)

            Circle()
                .stroke(bandColor.opacity(active ? 0.6 : (hovering ? 0.4 : 0.22)),
                        lineWidth: 1.5)
                .frame(width: size - 8, height: size - 8)

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
                .fill(bandColor)
                .frame(width: 1.5, height: size * 0.26)
                .offset(y: -size * 0.22)
                .rotationEffect(.degrees(angle))
                .shadow(color: bandColor.opacity(active ? 0.7 : 0.3), radius: active ? 3 : 1.5)

            Circle()
                .fill(Theme.inkFaint.opacity(atCenter ? 0.8 : 0.2))
                .frame(width: 2, height: 2)
                .offset(y: size * 0.22)
        }
        .frame(width: size + 6, height: size + 6)
        .onHover { hovering = $0 }
        .onTapGesture(count: 2) {
            if !atCenter {
                value = 0
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    if dragStart == nil {
                        dragStart = g.startLocation.x
                        dragStartValue = value
                    }
                    let delta = g.location.x - dragStart!
                    let range = maxGain - minGain
                    let gainDelta = Double(delta) * (range / 130)
                    var newGain = Double(dragStartValue) + gainDelta
                    newGain = max(minGain, min(maxGain, newGain))
                    if abs(newGain) < 0.6 {
                        newGain = 0
                    } else {
                        newGain = (newGain * 2).rounded() / 2
                    }
                    value = Float(newGain)
                }
                .onEnded { _ in
                    let prev = dragStartValue
                    dragStart = nil
                    if abs(Double(value)) < 0.6, abs(Double(prev)) >= 0.6 {
                        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                    }
                }
        )
        .accessibilityLabel("Equalizer \(label)")
        .accessibilityValue("\(formattedValue) decibels")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = Float(min(maxGain, Double(value) + 0.5))
            case .decrement: value = Float(max(minGain, Double(value) - 0.5))
            @unknown default: break
            }
        }
    }

    private var formattedValue: String {
        let v = Double(value)
        let r = (v * 2).rounded() / 2
        if r == r.rounded() {
            return String(format: "%+.0f", r)
        }
        return String(format: "%+.1f", r)
    }
}
