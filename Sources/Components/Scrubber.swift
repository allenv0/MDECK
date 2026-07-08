import SwiftUI

struct Scrubber: View {
    let value: Double
    let total: Double
    let onSeek: (Double) -> Void

    @State private var dragging = false
    @State private var dragLocation: CGPoint = .zero

    private func fmt(_ t: Double) -> String {
        guard t.isFinite, t >= 0 else { return "00:00" }
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let frac = total > 0 ? CGFloat(min(1, max(0, value / total))) : 0
            let dots = max(1, Int(w / 9))
            ZStack(alignment: .top) {
                if dragging {
                    let dragFrac = min(1, max(0, dragLocation.x / w))
                    let dragTime = Double(dragFrac) * total
                    let previewW = DotText.width(fmt(dragTime), dot: 2.2, gap: 1.2, spacing: 2.4)
                    let previewX = dragLocation.x - previewW / 2
                    DotText(text: fmt(dragTime), dot: 2.2, gap: 1.2, spacing: 2.4, color: Theme.accent)
                        .offset(x: min(max(previewX, 0), w - previewW), y: -20)
                        .transition(.opacity)
                }

                Canvas { ctx, size in
                    let lit = Int(CGFloat(dots) * frac)
                    for i in 0..<dots {
                        let x = (CGFloat(i) + 0.5) * (size.width / CGFloat(dots))
                        let on = i <= lit
                        let d: CGFloat = on ? 5 : 3.5
                        ctx.fill(Path(ellipseIn: CGRect(x: x - d/2, y: size.height/2 - d/2, width: d, height: d)),
                                 with: .color(on ? Theme.dotOn : Theme.dotOff))
                    }
                    if dragging {
                        let dx = min(w - 2, max(2, dragLocation.x))
                        ctx.fill(Path(ellipseIn: CGRect(x: dx - 4, y: size.height/2 - 4, width: 8, height: 8)),
                                 with: .color(Theme.accent))
                    }
                }
            }
            .accessibilityLabel("Seek")
            .accessibilityValue(Text("\(Int(value)) of \(Int(total)) seconds"))
            .accessibilityAdjustableAction { direction in
                let step = total / 20
                switch direction {
                case .increment: onSeek(min(total, value + step))
                case .decrement: onSeek(max(0, value - step))
                @unknown default: break
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { g in
                    if !dragging { withAnimation(.easeOut(duration: 0.1)) { dragging = true } }
                    dragLocation = g.location
                    let f = min(1, max(0, g.location.x / w))
                    onSeek(Double(f) * total)
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.15)) { dragging = false }
                }
            )
        }
    }
}
