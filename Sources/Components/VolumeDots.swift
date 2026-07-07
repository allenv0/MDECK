import SwiftUI

struct VolumeDots: View {
    @Binding var value: Float

    private static let onHot  = Color(red: 0.96, green: 0.56, blue: 0.26)
    private static let onCool = Color(red: 0.86, green: 0.36, blue: 0.12)
    private static let off    = Color(red: 0.24, green: 0.12, blue: 0.05)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let segs = 7
            Canvas { ctx, size in
                let lit = Int((Float(segs) * value).rounded())
                let cell = size.width / CGFloat(segs)
                let bw = cell * 0.84
                let gap = cell - bw
                for i in 0..<segs {
                    let on = i < lit
                    let x = CGFloat(i) * cell + gap / 2
                    let rect = CGRect(x: x, y: 0, width: bw, height: size.height)
                    let color: Color
                    if on {
                        let t = lit > 1 ? Double(i) / Double(lit - 1) : 0
                        color = Self.lerp(Self.onHot, Self.onCool, t)
                    } else {
                        color = Self.off
                    }
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
            .contentShape(Rectangle())
            .accessibilityValue(Text("Volume \(Int(value * 100))%"))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: value = min(1, value + 0.1)
                case .decrement: value = max(0, value - 0.1)
                @unknown default: break
                }
            }
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                value = Float(min(1, max(0, g.location.x / w)))
            })
        }
    }

    private static func lerp(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let ca = NSColor(a).usingColorSpace(.sRGB) ?? .orange
        let cb = NSColor(b).usingColorSpace(.sRGB) ?? .orange
        let f = CGFloat(max(0, min(1, t)))
        return Color(red: Double(ca.redComponent + (cb.redComponent - ca.redComponent) * f),
                     green: Double(ca.greenComponent + (cb.greenComponent - ca.greenComponent) * f),
                     blue: Double(ca.blueComponent + (cb.blueComponent - ca.blueComponent) * f))
    }
}
