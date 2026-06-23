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
        .onReceive(NotificationCenter.default.publisher(for: .openFiles)) { _ in openFiles() }
        .onAppear { NSWindow.allowsAutomaticWindowTabbing = false }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            DotText(text: "DOTMP3", dot: 4, gap: 2, color: Theme.dotOn)
            Rectangle().fill(Theme.red).frame(width: 7, height: 7)   // brand red, exactly once
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
            HStack(spacing: 16) {
                artwork
                VStack(alignment: .leading, spacing: 12) {
                    DotText(text: shortened(engine.currentTrack?.title ?? "NO SIGNAL", 14),
                            dot: 5, gap: 2, color: Theme.dotOn)
                    Text((engine.currentTrack?.artist ?? "—").uppercased())
                        .font(.grotesk(13, .semibold)).foregroundStyle(Theme.ink)
                    Text((engine.currentTrack?.album ?? "—").uppercased())
                        .font(.mono(10)).tracking(1).foregroundStyle(Theme.inkDim)
                    Spacer()
                    SpectrumView(bands: engine.bands, rows: 8, active: engine.isPlaying)
                        .frame(height: 76)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
    }

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.bg)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.panelStroke))
            if let img = engine.currentTrack?.artwork {
                Image(nsImage: img).resizable().aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                // dot-grid placeholder
                Canvas { ctx, size in
                    let step: CGFloat = 12
                    var y: CGFloat = step/2
                    while y < size.height { var x: CGFloat = step/2
                        while x < size.width {
                            ctx.fill(Path(ellipseIn: CGRect(x: x-1.5, y: y-1.5, width: 3, height: 3)),
                                     with: .color(Theme.dotOff))
                            x += step }
                        y += step }
                }
            }
        }
        .frame(width: 150, height: 150)
    }

    // MARK: Transport

    private var transport: some View {
        Panel(label: "Transport") {
            VStack(spacing: 16) {
                HStack(alignment: .bottom) {
                    DotText(text: fmt(engine.currentTime), dot: 6, gap: 3, color: Theme.dotOn)
                    Spacer()
                    DotText(text: fmt(engine.duration), dot: 4, gap: 2, color: Theme.inkDim)
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
                .frame(width: 120, height: 16)
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
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let dots = 10
            Canvas { ctx, size in
                let lit = Int((Float(dots) * value).rounded())
                for i in 0..<dots {
                    let x = (CGFloat(i) + 0.5) * (size.width / CGFloat(dots))
                    let on = i < lit
                    let d: CGFloat = 5
                    ctx.fill(Path(ellipseIn: CGRect(x: x-d/2, y: size.height/2 - d/2, width: d, height: d)),
                             with: .color(on ? Theme.dotOn : Theme.dotOff))
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                value = Float(min(1, max(0, g.location.x / w)))
            })
        }
    }
}
