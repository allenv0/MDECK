import SwiftUI

struct EQPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let gains: [Float]
}

enum EQPresets {
    static let flat    = EQPreset(id: "flat",    name: "FLAT",   gains: [0,0,0,0,0,0,0,0,0,0])
    static let bass    = EQPreset(id: "bass",    name: "BASS",   gains: [8,6,4,2,0,0,0,0,0,0])
    static let treble  = EQPreset(id: "treble",  name: "TREBLE", gains: [0,0,0,0,0,0,2,4,6,8])
    static let vocal   = EQPreset(id: "vocal",   name: "VOCAL",  gains: [-2,-1,0,2,4,4,3,1,0,-1])
    static let loudness = EQPreset(id: "loudness", name: "LOUD",  gains: [6,4,0,-2,-2,0,2,4,6,8])

    static let all: [EQPreset] = [flat, bass, treble, vocal, loudness]
}

struct EqualizerView: View {
    @EnvironmentObject var engine: AudioEngine
    @State private var activeKnob: Int? = nil

    private var matchedPreset: String? {
        EQPresets.all.first { $0.gains == engine.eqGains }?.id
    }

    var body: some View {
        Panel(label: "Equalizer") {
            VStack(alignment: .leading, spacing: Spacing.sectionSpacing) {
                toolbar

                EQResponseCurve(
                    gains: engine.eqGains,
                    enabled: engine.eqEnabled,
                    activeIndex: activeKnob
                )
                .frame(maxWidth: .infinity)
                .frame(height: 104)

                bandRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .opacity(engine.eqEnabled ? 1 : 0.5)
        .animation(Anim.toggle, value: engine.eqEnabled)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        VStack(spacing: Spacing.controlSpacing) {
            HStack(spacing: Spacing.controlSpacing) {
                RetroToggle(isOn: $engine.eqEnabled, label: "EQ", icon: "slider.vertical.3")
                    .fixedSize()
                Spacer()
                Button {
                    applyPreset(EQPresets.flat)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.inkDim)
                        .frame(width: 22, height: 22)
                        .overlay(RoundedRectangle(cornerRadius: Radius.input).stroke(Theme.panelStroke))
                }
                .buttonStyle(.plain)
                .help("Reset to flat")
            }

            HStack(spacing: Spacing.buttonSpacing) {
                ForEach(EQPresets.all) { preset in
                    SelectableButton(
                        label: preset.name,
                        isSelected: matchedPreset == preset.id,
                        shape: .rectangle
                    ) {
                        applyPreset(preset)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func applyPreset(_ preset: EQPreset) {
        withAnimation(Anim.snap) { engine.eqGains = preset.gains }
    }

    // MARK: - Band row

    private var bandRow: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(AudioEngine.eqFrequencies.enumerated()), id: \.offset) { idx, freq in
                VStack(spacing: Spacing.snug) {
                    EQBandKnob(
                        value: bandBinding(idx),
                        label: freqLabel(freq),
                        index: idx,
                        total: AudioEngine.eqBandCount,
                        size: 22
                    )
                    Text(freqLabel(freq))
                        .font(.mono(Typography.badge, .medium))
                        .tracking(Tracking.tight)
                        .foregroundStyle(Theme.inkFaint)
                    Text(dbLabel(idx))
                        .font(.mono(Typography.badge))
                        .foregroundStyle(engine.eqGains[idx] == 0 ? Theme.inkFaint : Theme.dotOn)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func bandBinding(_ index: Int) -> Binding<Float> {
        Binding(
            get: { engine.eqGains[index] },
            set: { newValue in
                var gains = engine.eqGains
                gains[index] = newValue
                engine.eqGains = gains
            }
        )
    }

    private func freqLabel(_ freq: Float) -> String {
        if freq >= 1000 {
            let k = freq / 1000
            return k == k.rounded() ? "\(Int(k))K" : String(format: "%.1fK", k)
        }
        return "\(Int(freq))"
    }

    private func dbLabel(_ index: Int) -> String {
        let v = Double(engine.eqGains[index])
        if v == 0 { return "\u{00B7}" }
        let r = (v * 2).rounded() / 2
        return r == r.rounded() ? String(format: "%+.0f", r) : String(format: "%+.1f", r)
    }
}

// MARK: - Response Curve

private struct EQResponseCurve: View {
    let gains: [Float]
    let enabled: Bool
    var activeIndex: Int? = nil

    var body: some View {
        Canvas { ctx, size in
            let padX: CGFloat = 10
            let drawW = size.width - padX * 2
            let midY = size.height / 2
            let halfRange: CGFloat = 12
            let amp = size.height / 2 - 6

            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Theme.bg.opacity(0.3)))

            let dbMarks: [CGFloat] = [-12, -6, 0, 6, 12]
            for db in dbMarks {
                let y = midY - CGFloat(db) / halfRange * amp
                let isZero = db == 0
                let linePath = Path(CGRect(x: padX, y: y, width: drawW, height: 0.5))
                ctx.stroke(linePath,
                           with: .color(isZero ? Theme.inkFaint.opacity(0.32) : Theme.inkFaint.opacity(0.12)),
                           lineWidth: isZero ? 1 : 0.5)
            }

            guard gains.count > 1 else { return }
            let n = gains.count
            let pts: [CGPoint] = gains.enumerated().map { i, g in
                let x = padX + drawW * CGFloat(i) / CGFloat(n - 1)
                let v = enabled ? CGFloat(g) : 0
                let y = midY - (v / halfRange) * amp
                return CGPoint(x: x, y: y)
            }

            for i in 0..<n {
                let x = padX + drawW * CGFloat(i) / CGFloat(n - 1)
                let guide = Path(CGRect(x: x, y: 4, width: 0.5, height: size.height - 8))
                ctx.stroke(guide, with: .color(Theme.inkFaint.opacity(0.07)), lineWidth: 0.5)
            }

            let curve = Self.smoothPath(pts)

            var fillPath = curve
            fillPath.addLine(to: CGPoint(x: pts.last!.x, y: size.height))
            fillPath.addLine(to: CGPoint(x: pts.first!.x, y: size.height))
            fillPath.closeSubpath()
            ctx.fill(fillPath, with: .linearGradient(
                Gradient(colors: [Theme.accent.opacity(0.18), Theme.accent.opacity(0)]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: size.height)
            ))

            ctx.blendMode = .plusLighter
            ctx.stroke(curve, with: .color(Theme.accent2.opacity(0.22)), lineWidth: 3.5)
            ctx.blendMode = .normal

            let bandGrad = Gradient(colors: [Theme.bandLow, Theme.bandMid, Theme.bandHigh, Theme.bandPeak])
            ctx.stroke(curve, with: .linearGradient(bandGrad,
                       startPoint: CGPoint(x: padX, y: 0),
                       endPoint: CGPoint(x: size.width - padX, y: 0)),
                       lineWidth: 1.6)

            for (i, p) in pts.enumerated() {
                let c = Self.bandColor(at: i, total: n)
                let glow = CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)
                ctx.fill(Path(ellipseIn: glow), with: .color(c.opacity(activeIndex == i ? 0.35 : 0.16)))
                let core = CGRect(x: p.x - 2.25, y: p.y - 2.25, width: 4.5, height: 4.5)
                ctx.fill(Path(ellipseIn: core), with: .color(c))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .fill(Theme.bg.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .stroke(Color.white.opacity(OpacityToken.ghost), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.input, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.black.opacity(OpacityToken.panelBorder), lineWidth: 1)
                .offset(y: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.input, style: .continuous))
    }

    private static func bandColor(at index: Int, total: Int) -> Color {
        let t = Double(index) / Double(max(1, total - 1))
        switch t {
        case ..<0.34: return Theme.bandLow
        case ..<0.67: return Theme.bandMid
        case ..<0.84: return Theme.bandHigh
        default:      return Theme.bandPeak
        }
    }

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
