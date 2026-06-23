import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var engine: AudioEngine
    @State private var dropTargeted = false
    @State private var draggingIndex: Int? = nil
    @State private var showPlaylist = true

    var body: some View {
        VStack(spacing: Theme.grid) {
            header
            HStack(spacing: Theme.grid) {
                VStack(spacing: Theme.grid) {
                    nowPlaying
                    transport
                }
                if showPlaylist {
                    playlistPanel
                        .frame(width: 320)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: showPlaylist)
        .padding(Theme.grid)
        .background(Theme.bg)
        .focusEffectDisabled()
        .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
            engine.add(providers: providers)
            return true
        }
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
            statusDot
            Text("PLAYLIST")
                .font(.mono(9)).tracking(2).foregroundStyle(Theme.inkDim)
                .padding(.leading, 8)
            GridToggle(on: $showPlaylist)
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
                HStack(spacing: 12) {
                    GlyphButton(kind: .prev) { engine.prev() }
                    GlyphButton(kind: engine.isPlaying ? .pause : .play, accent: true, size: 56) {
                        engine.togglePlay()
                    }
                    GlyphButton(kind: .next) { engine.next() }
                    ModeButton(label: "SHUF", active: engine.shuffle) { engine.shuffle.toggle() }
                    ModeButton(label: repeatLabel, active: engine.repeatMode != .off) { engine.cycleRepeat() }
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
                .frame(width: 124, height: 8)
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
                                .onDrag {
                                    draggingIndex = idx
                                    return NSItemProvider(object: String(idx) as NSString)
                                }
                                .onDrop(of: [UTType.text], delegate: ReorderDelegate(
                                    target: idx, dragging: $draggingIndex, engine: engine))
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.orange, lineWidth: dropTargeted ? 2 : 0)
        )
        .onDrop(of: [UTType.fileURL], isTargeted: $dropTargeted) { providers in
            engine.add(providers: providers)
            return true
        }
    }

    private func row(idx: Int, track: Track) -> some View {
        let isCur = engine.currentIndex == idx
        let isSel = engine.selectedIndex == idx
        return HStack(spacing: 10) {
            if isCur {
                Rectangle().fill(Theme.red).frame(width: 3, height: 26)
            } else {
                Text(String(format: "%02d", idx + 1))
                    .font(.mono(10)).foregroundStyle(Theme.inkFaint).frame(width: 18)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title).font(.grotesk(12, .medium)).lineLimit(1)
                    .foregroundStyle(isCur || isSel ? Theme.dotOn : Theme.ink)
                Text(track.artist.uppercased()).font(.mono(9)).tracking(1)
                    .foregroundStyle(Theme.inkDim).lineLimit(1)
            }
            Spacer()
            Text(fmt(track.duration)).font(.mono(10)).foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 8).padding(.vertical, 7)
        .background(isSel ? Theme.bg : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6)
            .stroke(Theme.panelStroke, lineWidth: isSel ? 1 : 0))
        .overlay(alignment: .top) {
            if draggingIndex != nil && draggingIndex == idx {
                Rectangle().fill(Theme.orange).frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { engine.play(index: idx) }
        .onTapGesture(count: 1) { engine.select(idx) }
    }

    // MARK: Helpers

    private var repeatLabel: String { engine.repeatMode == .one ? "LOOP·1" : "LOOP" }

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

// Compact mono-text toggle for shuffle / repeat modes.
struct ModeButton: View {
    let label: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.mono(8, .bold)).tracking(0.5)
                .foregroundStyle(active ? .white : Theme.inkFaint)
                .padding(.horizontal, 7).padding(.vertical, 6)
                .background((active ? Theme.orange : Color.clear).opacity(active ? 0.18 : 0))
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(active ? Theme.orange : Theme.panelStroke, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// Nothing-style pixel switch (port of nullframe's Toggle): sharp track that turns
// orange when on, with a 3x3 white-pixel-grid knob that slides left↔right.
struct GridToggle: View {
    @Binding var on: Bool
    private let trackW: CGFloat = 36
    private let trackH: CGFloat = 17
    private let thumb: CGFloat = 13

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.28)) { on.toggle() }
        } label: {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(on ? Theme.orange : Theme.trackOff)   // #f26522 / #333
                pixelKnob
                    .frame(width: thumb, height: thumb)
                    .offset(x: on ? trackW - thumb - 2 : 2)
            }
            .frame(width: trackW, height: trackH)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(on ? "Hide queue" : "Show queue")
    }

    private var pixelKnob: some View {
        Canvas { ctx, size in
            let n = 3
            let gap: CGFloat = 1
            let cell = (size.width - gap * CGFloat(n - 1)) / CGFloat(n)
            for r in 0..<n {
                for c in 0..<n {
                    let x = CGFloat(c) * (cell + gap)
                    let y = CGFloat(r) * (cell + gap)
                    ctx.fill(Path(CGRect(x: x, y: y, width: cell, height: cell)),
                             with: .color(.white))
                }
            }
        }
    }
}

// Live row reorder while dragging within the queue.
struct ReorderDelegate: DropDelegate {
    let target: Int
    @Binding var dragging: Int?
    let engine: AudioEngine

    func dropEntered(info: DropInfo) {
        guard let from = dragging, from != target else { return }
        engine.move(from: from, to: target)
        dragging = target
    }
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func performDrop(info: DropInfo) -> Bool { dragging = nil; return true }
    func dropExited(info: DropInfo) {}
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
