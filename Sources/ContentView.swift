import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var engine: AudioEngine

    var body: some View {
        VStack(spacing: Theme.grid) {
            header
            HStack(spacing: Theme.grid) {
                VStack(spacing: Theme.grid) {
                    nowPlaying
                    transport
                }
                playlistPanel
                    .frame(width: 320)
            }
        }
        .padding(Theme.grid)
        .background(Theme.bg)
        .focusEffectDisabled()
        .onReceive(NotificationCenter.default.publisher(for: .openFiles)) { _ in openFiles() }
        .onAppear { NSWindow.allowsAutomaticWindowTabbing = false }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            DotText(text: "DOTMP3", dot: 1.8, gap: 1.1, spacing: 2.4, color: Theme.dotOn)
            // brand red, exactly once — blinks while playing
            TimelineView(.periodic(from: .now, by: 0.45)) { tl in
                let on = Int(tl.date.timeIntervalSinceReferenceDate / 0.45) % 2 == 0
                Rectangle()
                    .fill(Theme.red)
                    .frame(width: 4, height: 4)
                    .opacity(engine.isPlaying ? (on ? 1 : 0.12) : 1)
            }
            Spacer()
            Text("AUDIO · TELEMETRY")
                .font(.mono(9)).tracking(3).foregroundStyle(Theme.inkFaint)
            statusDot
        }
        .frame(height: 28)
    }

    private var statusDot: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(engine.isPlaying ? Theme.dotOn : Theme.inkFaint)
                .frame(width: 6, height: 6)
            Text(engine.isPlaying ? "RUN" : "IDLE")
                .font(.mono(9)).tracking(2).foregroundStyle(Theme.inkDim)
        }
    }

    // MARK: Now playing

    private var nowPlaying: some View {
        Panel(label: "Now Playing") {
            VStack(alignment: .leading, spacing: 12) {
                MarqueeDotText(text: (engine.currentTrack?.title ?? "NO SIGNAL").uppercased(),
                               dot: 3.6, gap: 1.8, spacing: 4, color: Theme.dotOn)
                    .id(engine.currentIndex ?? -1)
                Text((engine.currentTrack?.artist ?? "—").uppercased())
                    .font(.grotesk(13, .semibold)).foregroundStyle(Theme.ink)
                Text((engine.currentTrack?.album ?? "—").uppercased())
                    .font(.mono(10)).tracking(1).foregroundStyle(Theme.inkDim)
                Spacer()
                SpectrumView(bands: engine.bands, rows: 14, active: engine.isPlaying)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: Transport

    private var transport: some View {
        Panel(label: "Transport") {
            VStack(spacing: 16) {
                HStack(alignment: .bottom) {
                    DotText(text: fmt(engine.currentTime), dot: 3, gap: 1.5, color: Theme.dotOn)
                    Spacer()
                    DotText(text: fmt(engine.duration), dot: 3, gap: 1.5, color: Theme.inkDim)
                }
                Scrubber(value: engine.currentTime, total: max(engine.duration, 0.01)) { t in
                    engine.seek(to: t)
                }
                .frame(height: 16)
                HStack(spacing: 14) {
                    GlyphButton(kind: .prev) { engine.prev() }
                    GlyphButton(kind: engine.isPlaying ? .pause : .play, accent: true, size: 56) {
                        engine.togglePlay()
                    }
                    GlyphButton(kind: .next) { engine.next() }
                    Spacer()
                    volume
                }
            }
        }
        .frame(height: 190)
    }

    private var volume: some View {
        HStack(spacing: 10) {
            Text("VOL").font(.mono(9)).tracking(2).foregroundStyle(Theme.inkFaint)
            VolumeDots(value: $engine.volume)
                .frame(width: 168, height: 14)
        }
    }

    // MARK: Playlist

    private var playlistPanel: some View {
        Panel(label: "Queue · \(engine.playlist.count)") {
            if engine.playlist.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    DotText(text: "EMPTY", dot: 4, gap: 2, color: Theme.inkFaint)
                    Button(action: openFiles) {
                        Text("+ ADD FILES").font(.mono(11)).tracking(2)
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.panelStroke))
                    }.buttonStyle(.plain)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(engine.playlist.enumerated()), id: \.element.id) { idx, track in
                            row(idx: idx, track: track)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func row(idx: Int, track: Track) -> some View {
        let isCur = engine.currentIndex == idx
        return Button {
            engine.load(index: idx, autoplay: true)
        } label: {
            HStack(spacing: 10) {
                if isCur {
                    Rectangle().fill(Theme.red).frame(width: 3, height: 26)
                } else {
                    Text(String(format: "%02d", idx + 1))
                        .font(.mono(10)).foregroundStyle(Theme.inkFaint).frame(width: 18)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(.grotesk(12, .medium)).lineLimit(1)
                        .foregroundStyle(isCur ? Theme.dotOn : Theme.ink)
                    Text(track.artist.uppercased()).font(.mono(9)).tracking(1)
                        .foregroundStyle(Theme.inkDim).lineLimit(1)
                }
                Spacer()
                Text(fmt(track.duration)).font(.mono(10)).foregroundStyle(Theme.inkFaint)
            }
            .padding(.horizontal, 8).padding(.vertical, 7)
            .background(isCur ? Theme.bg : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private func fmt(_ t: Double) -> String {
        guard t.isFinite, t >= 0 else { return "00:00" }
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
    private func shortened(_ s: String, _ n: Int) -> String {
        let up = s.uppercased()
        return up.count <= n ? up : String(up.prefix(n - 1)) + "…"
    }

    private func openFiles() {
        let p = NSOpenPanel()
        p.allowsMultipleSelection = true
        p.canChooseDirectories = false
        if #available(macOS 11, *) {
            p.allowedContentTypes = [UTType.mp3, UTType.audio].compactMap { $0 }
        }
        if p.runModal() == .OK { engine.add(urls: p.urls) }
    }
}

// Dotted scrub bar with draggable position.
struct Scrubber: View {
    let value: Double
    let total: Double
    let onSeek: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let frac = total > 0 ? CGFloat(min(1, max(0, value / total))) : 0
            let dots = max(1, Int(w / 9))
            Canvas { ctx, size in
                let lit = Int(CGFloat(dots) * frac)
                for i in 0..<dots {
                    let x = (CGFloat(i) + 0.5) * (size.width / CGFloat(dots))
                    let on = i <= lit
                    let d: CGFloat = on ? 5 : 3.5
                    ctx.fill(Path(ellipseIn: CGRect(x: x - d/2, y: size.height/2 - d/2, width: d, height: d)),
                             with: .color(on ? Theme.dotOn : Theme.dotOff))
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                let f = min(1, max(0, g.location.x / w))
                onSeek(Double(f) * total)
            })
        }
    }
}

struct VolumeDots: View {
    @Binding var value: Float

    // Warm segment palette: bright orange (left) fading to dark brown (right/unlit).
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
                        let t = lit > 1 ? Double(i) / Double(lit - 1) : 0   // bright → cool across active region
                        color = Self.lerp(Self.onHot, Self.onCool, t)
                    } else {
                        color = Self.off
                    }
                    ctx.fill(Path(rect), with: .color(color))   // sharp corners, no radius
                }
            }
            .contentShape(Rectangle())
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
