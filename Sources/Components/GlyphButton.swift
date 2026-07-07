import SwiftUI

struct GlyphButton: View {
    enum Kind { case play, pause, next, prev }
    let kind: Kind
    var accent: Bool = false
    var size: CGFloat = 44
    let action: () -> Void
    @State private var down = false

    var body: some View {
        Button(action: action) {
            Canvas { ctx, sz in drawGlyph(ctx: ctx, size: sz) }
                .frame(width: size, height: size)
                .background(accent ? Theme.orange.opacity(0.65) : Theme.panel)
                .clipShape(RoundedRectangle(cornerRadius: Radius.art, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.art, style: .continuous)
                    .stroke(accent ? Color.clear : Theme.panelStroke, lineWidth: 1))
                .scaleEffect(down ? 0.9 : 1)
                .animation(.spring(response: 0.18, dampingFraction: 0.45), value: down)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .onLongPressGesture(minimumDuration: 0, pressing: { down = $0 }, perform: {})
    }

    private func drawGlyph(ctx: GraphicsContext, size: CGSize) {
        let grid = bitmap()
        let g = grid.count
        let cw = size.width * 0.5 / CGFloat(g)
        let d = cw * 0.74

        var minC = g, maxC = -1, minR = g, maxR = -1
        for (r, row) in grid.enumerated() {
            for (c, bit) in row.enumerated() where bit == 1 {
                minC = min(minC, c); maxC = max(maxC, c)
                minR = min(minR, r); maxR = max(maxR, r)
            }
        }
        guard maxC >= 0 else { return }
        let contentW = CGFloat(maxC - minC + 1) * cw
        let contentH = CGFloat(maxR - minR + 1) * cw
        let originX = (size.width - contentW) / 2 + cw/2 - CGFloat(minC) * cw
        let originY = (size.height - contentH) / 2 + cw/2 - CGFloat(minR) * cw
        let col: Color = accent ? Theme.dotOn : Theme.ink
        for (r, row) in grid.enumerated() {
            for (c, bit) in row.enumerated() where bit == 1 {
                let cx = originX + CGFloat(c) * cw
                let cy = originY + CGFloat(r) * cw
                ctx.fill(Path(ellipseIn: CGRect(x: cx - d/2, y: cy - d/2, width: d, height: d)),
                         with: .color(col))
            }
        }
    }

    private var accessibilityLabel: String {
        switch kind {
        case .play:  return "Play"
        case .pause: return "Pause"
        case .next:  return "Next Track"
        case .prev:  return "Previous Track"
        }
    }

    private func bitmap() -> [[Int]] {
        switch kind {
        case .play:
            return [
                [0,1,0,0,0,0,0,0],
                [0,1,1,0,0,0,0,0],
                [0,1,1,1,0,0,0,0],
                [0,1,1,1,1,0,0,0],
                [0,1,1,1,1,0,0,0],
                [0,1,1,1,0,0,0,0],
                [0,1,1,0,0,0,0,0],
                [0,1,0,0,0,0,0,0],
            ]
        case .pause:
            return [
                [0,1,1,0,0,1,1,0],
                [0,1,1,0,0,1,1,0],
                [0,1,1,0,0,1,1,0],
                [0,1,1,0,0,1,1,0],
                [0,1,1,0,0,1,1,0],
                [0,1,1,0,0,1,1,0],
                [0,1,1,0,0,1,1,0],
                [0,1,1,0,0,1,1,0],
            ]
        case .next:
            return [
                [1,0,0,0,1,0,0,0],
                [1,1,0,0,1,0,0,0],
                [1,1,1,0,1,0,0,0],
                [1,1,1,1,1,0,0,0],
                [1,1,1,1,1,0,0,0],
                [1,1,1,0,1,0,0,0],
                [1,1,0,0,1,0,0,0],
                [1,0,0,0,1,0,0,0],
            ]
        case .prev:
            return [
                [0,0,0,1,0,0,0,1],
                [0,0,0,1,0,0,1,1],
                [0,0,0,1,0,1,1,1],
                [0,0,0,1,1,1,1,1],
                [0,0,0,1,1,1,1,1],
                [0,0,0,1,0,1,1,1],
                [0,0,0,1,0,0,1,1],
                [0,0,0,1,0,0,0,1],
            ]
        }
    }
}
