import SwiftUI

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
            let bw = cw * 0.82
            let bh = min(rh * 0.34, 4)
            let radius = bh / 2
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color.black.opacity(0.25)))
            for c in 0..<cols {
                let lit = Int((CGFloat(bands[c]) * CGFloat(rows)).rounded())
                let bandColor = self.bandColor(at: c, total: cols)
                for r in 0..<rows {
                    let on = (rows - 1 - r) < lit && active
                    let cx = cw * (CGFloat(c) + 0.5)
                    let cy = rh * (CGFloat(r) + 0.5)
                    let rect = CGRect(x: cx - bw/2, y: cy - bh/2, width: bw, height: bh)
                    let color: Color = on ? bandColor : Theme.pixelOff
                    ctx.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
                }
            }
        }
    }

    private func bandColor(at column: Int, total: Int) -> Color {
        let t = Double(column) / Double(total)
        switch t {
        case ..<0.25: return Theme.bandLow
        case ..<0.5:  return Theme.bandMid
        case ..<0.75: return Theme.bandHigh
        default:      return Theme.bandPeak
        }
    }
}

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


