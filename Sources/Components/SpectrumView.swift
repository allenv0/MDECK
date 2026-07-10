import SwiftUI

struct SpectrumView: View {
    let bands: [Float]
    var levels: [Float] = []
    var waveformSamples: [Float] = []
    var rows: Int = 9
    var active: Bool = true
    var style: SpectrumStyle = .bars
    @Environment(\.palette) private var palette

    var body: some View {
        let _ = palette  // register environment dependency for theme sync
        Canvas { ctx, size in
            switch style {
            case .bars:
                drawBars(ctx: &ctx, size: size)
            case .waveform:
                drawWaveform(ctx: &ctx, size: size)
            }
        }
    }

    // MARK: - Bars

    private func drawBars(ctx: inout GraphicsContext, size: CGSize) {
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
                let color: Color
                if active {
                    color = on ? bandColor : Theme.pixelOff
                } else {
                    let ghost = ((c * 7 + 3) % rows) > 1
                    color = on ? bandColor : (ghost ? Theme.pixelOff.opacity(0.3) : Theme.pixelOff)
                }
                ctx.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
            }
        }
    }

    // MARK: - Oscilloscope Waveform

    private func drawWaveform(ctx: inout GraphicsContext, size: CGSize) {
        guard active else { return }

        // Use real waveform samples if available, fall back to old levels data
        let samples: [Float]
        if !waveformSamples.isEmpty {
            samples = Array(waveformSamples.suffix(512))
        } else if levels.count > 1 {
            samples = levels
        } else {
            return
        }

        let count = samples.count
        guard count > 2 else { return }

        let midY = size.height / 2
        let amp = size.height * 0.44
        let padX: CGFloat = 2
        let drawW = size.width - padX * 2

        // --- Grid ---
        let gridColor = Theme.inkFaint.opacity(0.08)
        // Horizontal center line
        var gridPath = Path()
        gridPath.move(to: CGPoint(x: padX, y: midY))
        gridPath.addLine(to: CGPoint(x: size.width - padX, y: midY))
        ctx.stroke(gridPath, with: .color(gridColor), lineWidth: 0.5)
        // Horizontal quarter lines
        for q in [-0.5, 0.5] {
            let y = midY + q * amp
            var p = Path()
            p.move(to: CGPoint(x: padX, y: y))
            p.addLine(to: CGPoint(x: size.width - padX, y: y))
            ctx.stroke(p, with: .color(gridColor.opacity(0.5)), lineWidth: 0.5)
        }
        // Vertical tick marks
        for i in 0..<8 {
            let x = padX + drawW * CGFloat(i) / 7
            var p = Path()
            p.move(to: CGPoint(x: x, y: midY - 3))
            p.addLine(to: CGPoint(x: x, y: midY + 3))
            ctx.stroke(p, with: .color(gridColor), lineWidth: 0.5)
        }

        // --- Build waveform path ---
        var wavePath = Path()
        let step = max(1, count / Int(drawW * 1.2))
        let displayCount = count / step
        guard displayCount > 2 else { return }

        let points: [CGPoint] = stride(from: 0, to: count, by: step).enumerated().map { i, idx in
            let x = padX + drawW * CGFloat(i) / CGFloat(displayCount - 1)
            let y = midY - CGFloat(samples[idx]) * amp
            return CGPoint(x: x, y: y)
        }

        // --- Glow (phosphor bloom behind the trace) ---
        let glowPath = Self.smoothPath(points)
        ctx.drawLayer { layer in
            layer.addFilter(.shadow(color: Theme.accent.opacity(0.3), radius: 8, x: 0, y: 0))
            layer.stroke(glowPath, with: .color(Theme.accent.opacity(0.15)), lineWidth: 5)
        }

        // --- Fill under the curve ---
        var fillPath = Self.smoothPath(points)
        guard let lastPt = points.last, let firstPt = points.first else { return }
        fillPath.addLine(to: CGPoint(x: lastPt.x, y: midY))
        fillPath.addLine(to: CGPoint(x: firstPt.x, y: midY))
        fillPath.closeSubpath()
        ctx.fill(fillPath, with: .linearGradient(
            Gradient(colors: [Theme.accent.opacity(0.15), Theme.accent.opacity(0.03), Theme.accent.opacity(0)]),
            startPoint: CGPoint(x: 0, y: midY - amp),
            endPoint: CGPoint(x: 0, y: midY)
        ))

        // --- Main trace line ---
        let traceGrad = Gradient(colors: [Theme.bandMid, Theme.accent, Theme.accent2])
        ctx.stroke(Self.smoothPath(points), with: .linearGradient(traceGrad,
                   startPoint: CGPoint(x: padX, y: 0),
                   endPoint: CGPoint(x: size.width - padX, y: 0)),
                   lineWidth: 1.6)

        // --- End dot ---
        if let last = points.last {
            let dotR: CGFloat = 3
            ctx.fill(Path(ellipseIn: CGRect(x: last.x - dotR, y: last.y - dotR, width: dotR * 2, height: dotR * 2)),
                     with: .color(Theme.accent2))
            let glowR: CGFloat = 7
            ctx.fill(Path(ellipseIn: CGRect(x: last.x - glowR, y: last.y - glowR, width: glowR * 2, height: glowR * 2)),
                     with: .color(Theme.accent2.opacity(0.2)))
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

    /// Smooth Catmull-Rom spline through points.
    private static func smoothPath(_ pts: [CGPoint]) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: first)
        if pts.count < 3 {
            for p in pts.dropFirst() { path.addLine(to: p) }
            return path
        }
        for i in 0..<(pts.count - 1) {
            let p0 = i == 0 ? pts[0] : pts[i - 1]
            let p1 = pts[i]
            let p2 = pts[i + 1]
            let p3 = i + 2 < pts.count ? pts[i + 2] : pts[pts.count - 1]
            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        return path
    }
}
