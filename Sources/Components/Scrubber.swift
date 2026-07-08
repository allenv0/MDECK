import SwiftUI

struct Scrubber: View {
    let value: Double
    let total: Double
    let onSeek: (Double) -> Void

    @State private var dragging = false
    @State private var dragLocation: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let frac = total > 0 ? CGFloat(min(1, max(0, value / total))) : 0
            let dots = max(1, Int(w / 9))
            ZStack(alignment: .top) {
                if dragging {
                    let dragFrac = min(1, max(0, dragLocation.x / w))
                    let dragTime = Double(dragFrac) * total
                    let previewW = DotText.width(formatTime(dragTime), dot: 2.2, gap: 1.2, spacing: 2.4)
                    let previewX = dragLocation.x - previewW / 2
                    DotText(text: formatTime(dragTime), dot: 2.2, gap: 1.2, spacing: 2.4, color: Theme.accent)
                        .offset(x: min(max(previewX, 0), w - previewW), y: -20)
                        .transition(.opacity)
                }

                Canvas { ctx, size in
                    let lit = Int(CGFloat(dots) * frac)
                    let dotW = size.width / CGFloat(dots)

                    if dragging {
                        let dx = min(w - 2, max(2, dragLocation.x))
                        for i in 0..<dots {
                            let dotX = (CGFloat(i) + 0.5) * dotW
                            let dist = abs(dotX - dx)
                            if dist < 40 {
                                let glow = max(0, 1 - dist / 40)
                                let d: CGFloat = 3.5 + glow * 3
                                ctx.fill(Path(ellipseIn: CGRect(x: dotX - d/2, y: size.height/2 - d/2, width: d, height: d)),
                                         with: .color(Theme.accent.opacity(glow * 0.2)))
                            }
                        }
                    }

                    for i in 0..<dots {
                        let x = (CGFloat(i) + 0.5) * dotW
                        let on = i <= lit
                        let d: CGFloat = on ? 5 : 3.5
                        ctx.fill(Path(ellipseIn: CGRect(x: x - d/2, y: size.height/2 - d/2, width: d, height: d)),
                                 with: .color(on ? Theme.dotOn : Theme.dotOff))
                    }
                    if dragging {
                        let dx = min(w - 2, max(2, dragLocation.x))
                        let cursorSize: CGFloat = 8
                        ctx.fill(Path(ellipseIn: CGRect(x: dx - cursorSize/2, y: size.height/2 - cursorSize/2, width: cursorSize, height: cursorSize)),
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
                    if !dragging { withAnimation(Anim.fade) { dragging = true } }
                    dragLocation = g.location
                    let f = min(1, max(0, g.location.x / w))
                    onSeek(Double(f) * total)
                }
                .onEnded { _ in
                    withAnimation(Anim.fastFade) { dragging = false }
                }
            )
        }
    }
}
