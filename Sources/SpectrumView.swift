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
            let bw = cw * 0.82                      // wide, thin horizontal lines
            let bh = min(rh * 0.34, 4)              // thin line height
            let radius = bh / 2                     // pill ends
            for c in 0..<cols {
                let lit = Int((CGFloat(bands[c]) * CGFloat(rows)).rounded())
                for r in 0..<rows {
                    let on = (rows - 1 - r) < lit && active
                    let cx = cw * (CGFloat(c) + 0.5)
                    let cy = rh * (CGFloat(r) + 0.5)
                    let rect = CGRect(x: cx - bw/2, y: cy - bh/2, width: bw, height: bh)
                    let color: Color = on ? Theme.dotOn : Theme.pixelOff
                    ctx.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
                }
            }
        }
    }
}

// Rolling waveform of level history — vertical bars, newest at the right (orange playhead).
struct WaveHistory: View {
    let levels: [Float]
    let capacity: Int

    var body: some View {
        Canvas { ctx, size in
            guard capacity > 0 else { return }
            let cw = size.width / CGFloat(capacity)
            let bw = cw * 0.62
            let radius = bw * 0.45
            let offset = capacity - levels.count        // right-align newest
            for (idx, lv) in levels.enumerated() {
                let i = offset + idx
                let x = (CGFloat(i) + 0.5) * cw
                let h = max(2, CGFloat(min(1, lv)) * size.height)
                let last = idx == levels.count - 1
                let rect = CGRect(x: x - bw/2, y: (size.height - h) / 2, width: bw, height: h)
                ctx.fill(Path(roundedRect: rect, cornerRadius: radius),
                         with: .color(last ? Theme.orange : Theme.dotOn))
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
        // Render an 8-wide x 8-tall bitmap, centered on its FILLED pixels (not the full grid).
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
