import SwiftUI

struct VolumeDots: View {
    @Binding var value: Float
    @Environment(\.palette) private var palette

    @State private var litAt: [Int: Date] = [:]
    @State private var prevLit: Int = 0

    var body: some View {
        let _ = palette  // register environment dependency for theme sync
        return GeometryReader { geo in
            let w = geo.size.width
            let segs = 7
            Canvas { ctx, size in
                let lit = Int((Float(segs) * value).rounded())
                let cell = size.width / CGFloat(segs)
                let bw = cell * 0.84
                let gap = cell - bw
                let now = Date()
                for i in 0..<segs {
                    let on = i < lit
                    let x = CGFloat(i) * cell + gap / 2
                    var rect = CGRect(x: x, y: 0, width: bw, height: size.height)
                    let color: Color
                    if on {
                        let t = lit > 1 ? Double(i) / Double(lit - 1) : 0
                        color = Theme.accent.opacity(1 - t * 0.6)
                        if let litTime = litAt[i], now.timeIntervalSince(litTime) < 0.2 {
                            let bloom = CGFloat(1 - now.timeIntervalSince(litTime) / 0.2)
                            rect = rect.insetBy(dx: -bw * 0.1 * bloom, dy: -2 * bloom)
                            ctx.fill(Path(roundedRect: rect, cornerRadius: 1),
                                     with: .color(Theme.accent.opacity(0.15 * bloom)))
                        }
                    } else {
                        color = Theme.dotOff.opacity(OpacityToken.medium)
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
            .onChange(of: value) { newValue in
                let segs = 7
                let newLit = Int((Float(segs) * newValue).rounded())
                if newLit > prevLit {
                    for i in prevLit..<newLit {
                        litAt[i] = Date()
                    }
                }
                prevLit = newLit
            }
        }
    }
}
