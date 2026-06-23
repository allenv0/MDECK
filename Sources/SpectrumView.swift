import SwiftUI

// Dot-matrix spectrum: a grid of dots that light from the bottom up per band.
struct SpectrumView: View {
    let bands: [Float]
    var rows: Int = 9
    var active: Bool = true

    var body: some View {
        Canvas { ctx, size in
            let cols = bands.count
            guard cols > 0 else { return }
            let cw = size.width / CGFloat(cols)
            let rh = size.height / CGFloat(rows)
            let d = min(cw, rh) * 0.52
            for c in 0..<cols {
                let lit = Int((CGFloat(bands[c]) * CGFloat(rows)).rounded())
                for r in 0..<rows {
                    let on = (rows - 1 - r) < lit && active
                    let cx = cw * (CGFloat(c) + 0.5)
                    let cy = rh * (CGFloat(r) + 0.5)
                    let rect = CGRect(x: cx - d/2, y: cy - d/2, width: d, height: d)
                    let color: Color = on ? Theme.dotOn : Theme.dotOff
                    ctx.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
    }
}

// A small dot-matrix glyph button (play/pause/next/prev) drawn on a dot grid.
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
                .background(accent ? Theme.red : Theme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(accent ? Color.clear : Theme.panelStroke, lineWidth: 1))
                .scaleEffect(down ? 0.9 : 1)            // "slam and settle"
                .animation(.spring(response: 0.18, dampingFraction: 0.45), value: down)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { down = $0 }, perform: {})
    }

    private func drawGlyph(ctx: GraphicsContext, size: CGSize) {
        // Render an 8-wide x 8-tall bitmap into the button as dots.
        let grid = bitmap()
        let g = grid.count
        let cw = size.width * 0.5 / CGFloat(g)
        let d = cw * 0.74
        let originX = (size.width - cw * CGFloat(g)) / 2 + cw/2
        let originY = (size.height - cw * CGFloat(g)) / 2 + cw/2
        let col: Color = accent ? .white : Theme.ink
        for (r, row) in grid.enumerated() {
            for (c, bit) in row.enumerated() where bit == 1 {
                let cx = originX + CGFloat(c) * cw
                let cy = originY + CGFloat(r) * cw
                ctx.fill(Path(ellipseIn: CGRect(x: cx - d/2, y: cy - d/2, width: d, height: d)),
                         with: .color(col))
            }
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
