import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var engine: AudioEngine
    @StateObject private var theme = ThemeManager()
    @ObservedObject private var settings = AppSettings.shared
    @State private var dropTargeted = false
    @State private var artDropTargeted = false
    @State private var draggingIndex: Int? = nil
    @State private var showPlaylist = true
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: AppSettings.shared.layoutDensity.spacing) {
            header
            HStack(spacing: AppSettings.shared.layoutDensity.spacing) {
                VStack(spacing: AppSettings.shared.layoutDensity.spacing) {
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
        .padding(AppSettings.shared.layoutDensity.spacing)
        .background(Theme.bg)
        .overlay(alignment: .top) {
            LinearGradient(
                gradient: Gradient(colors: [
                    .white.opacity(0.07),
                    .white.opacity(0.03),
                    .clear,
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 160)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [.white.opacity(0.04), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 2)
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.35), lineWidth: 2)
                .offset(y: 1)
        )
        .environment(\.palette, theme.selected)
        .focusEffectDisabled()
        .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
            engine.add(providers: providers)
            return true
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFiles)) { _ in openFiles() }
        .onAppear { NSWindow.allowsAutomaticWindowTabbing = false }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            DotText(text: "MDeck", dot: 1.8, gap: 1.1, spacing: 2.4, color: Theme.dotOn)
            modelBadge

            controlStrip

            Spacer()
            statusLED
            Text("PLAYLIST")
                .font(.mono(Typography.label)).tracking(2).foregroundStyle(Theme.inkDim)
                .padding(.leading, 8)
            GridToggle(on: $showPlaylist)
            Button { showSettings.toggle() } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.inkDim)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettings) {
                SettingsView(theme: theme)
            }
            .padding(.leading, Spacing.snug)
        }
        .frame(height: 40)
    }

    private var controlStrip: some View {
        HStack(spacing: 6) {
            RotaryKnob(size: 18)
            RotaryKnob(size: 18)
            PowerLED()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Theme.bg.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }

    private var modelBadge: some View {
        Text("Fontier-Systems")
            .font(.mono(8, .bold))
            .tracking(1.5)
            .foregroundStyle(Theme.inkFaint.opacity(0.7))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.inkFaint.opacity(0.25), lineWidth: 1)
            )
            .padding(.leading, 6)
    }

    private struct PowerLED: View {
        @Environment(\.palette) private var palette
        var body: some View {
            ZStack {
                Circle()
                    .fill(Color(hex: palette.accent2).opacity(0.2))
                    .frame(width: 12, height: 12)
                    .blur(radius: 2)
                Circle()
                    .fill(Color(hex: palette.accent2).opacity(0.35))
                    .frame(width: 8, height: 8)
                    .blur(radius: 1.5)
                Circle()
                    .fill(Color(hex: palette.accent2))
                    .frame(width: 5, height: 5)
                Circle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 2, height: 2)
                    .offset(x: -1, y: -1)
            }
        }
    }

    private var statusLED: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(engine.isPlaying ? Theme.dotOn : Theme.inkFaint)
                .frame(width: 5, height: 5)
            Text(engine.isPlaying ? "PLAYING" : "IDLE")
                .font(.mono(Typography.label)).tracking(2).foregroundStyle(Theme.inkDim)
        }
    }

    // MARK: - Now Playing

    private var nowPlaying: some View {
        Panel(label: "Now Playing") {
            VStack(alignment: .leading, spacing: Spacing.sectionSpacing) {
                MarqueeDotText(text: (engine.currentTrack?.title ?? "NO SIGNAL").uppercased(),
                                dot: 3.6, gap: 1.8, spacing: 4, color: Theme.dotOn)
                    .id(engine.currentIndex ?? -1)
                Text((engine.currentTrack?.artist ?? "—").uppercased())
                    .font(.grotesk(Typography.title, .semibold)).foregroundStyle(Theme.ink)
                Text((engine.currentTrack?.album ?? "—").uppercased())
                    .font(.mono(Typography.caption)).tracking(1).foregroundStyle(Theme.inkDim)

                if settings.showAlbumArt {
                    albumArtSection
                }

                if settings.showSpectrum {
                    SpectrumView(
                        bands: engine.bands,
                        levels: engine.levels,
                        rows: settings.spectrumRows,
                        active: engine.isPlaying,
                        style: settings.spectrumStyle
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    private var albumArtSection: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 4)
            HStack {
                Spacer()
                albumArtDisplay
                    .frame(width: 260, height: 260)
                Spacer()
            }
            Spacer(minLength: 4)
        }
        .onDrop(of: [UTType.image, UTType.png, UTType.jpeg, UTType.tiff, UTType.bmp].compactMap { $0 },
                isTargeted: $artDropTargeted) { providers in
            handleArtDrop(providers)
        }
    }

    private var albumArtDisplay: some View {
        Group {
            if let artwork = engine.currentTrack?.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(nsImage: defaultArtwork)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(0.5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.art))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.art)
                .stroke(artDropTargeted ? Theme.orange : Theme.panelStroke, lineWidth: artDropTargeted ? 2 : 1)
        )
        .contextMenu {
            if let track = engine.currentTrack, track.artworkFileName != nil {
                Button(role: .destructive) {
                    engine.clearCustomArtwork(for: track)
                } label: {
                    Label("Remove Custom Cover", systemImage: "trash")
                }
            }
        }
    }

    private static let _defaultArtwork: NSImage = {
        if let appIcon = NSImage(named: NSImage.applicationIconName) {
            return appIcon
        }
        return NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)!
    }()
    private var defaultArtwork: NSImage { Self._defaultArtwork }

    private func handleArtDrop(_ providers: [NSItemProvider]) -> Bool {
        guard engine.currentTrack != nil else { return false }
        guard let provider = providers.first else { return false }
        // Try loading as NSImage directly
        if provider.canLoadObject(ofClass: NSImage.self) {
            _ = provider.loadObject(ofClass: NSImage.self) { image, _ in
                if let image = image as? NSImage {
                    Task { @MainActor in
                        engine.setCustomArtwork(image)
                    }
                }
            }
            return true
        }
        // Fallback: load file URL and create image from it
        if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url, let image = NSImage(contentsOf: url) {
                    Task { @MainActor in
                        engine.setCustomArtwork(image)
                    }
                }
            }
            return true
        }
        return false
    }

    // MARK: - Transport

    private var transport: some View {
        Panel(label: "Transport") {
            VStack(spacing: settings.layoutDensity.spacing) {
                HStack(alignment: .bottom) {
                    DotText(text: fmt(engine.currentTime), dot: 3, gap: 1.5, color: Theme.dotOn)
                    Spacer()
                    DotText(text: fmt(engine.duration), dot: 3, gap: 1.5, color: Theme.inkDim)
                }
                Scrubber(value: engine.currentTime, total: max(engine.duration, 0.01)) { t in
                    engine.seek(to: t)
                }
                .frame(height: 16)
                transportCluster
            }
        }
        .frame(height: 190)
    }

    private var transportCluster: some View {
        HStack(spacing: Spacing.sectionSpacing) {
            GlyphButton(kind: .prev) { engine.prev() }
            GlyphButton(kind: engine.isPlaying ? .pause : .play, accent: true, size: 56) {
                engine.togglePlay()
            }
            GlyphButton(kind: .next) { engine.next() }
            Divider()
                .frame(width: 1, height: 28)
                .overlay(Theme.inkFaint.opacity(0.2))
            ModeButton(label: "SHUF", active: engine.shuffle, width: 42) { engine.shuffle.toggle() }
            ModeButton(label: repeatLabel, active: engine.repeatMode != .off, width: 52) { engine.cycleRepeat() }
            Spacer()
            volume
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.bg.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: Radius.input))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.input)
                .stroke(Theme.panelStroke, lineWidth: 1)
        )
    }

    private var volume: some View {
        HStack(spacing: Spacing.controlSpacing) {
            Text("VOL").font(.mono(Typography.label)).tracking(2).foregroundStyle(Theme.inkFaint)
            VolumeDots(value: $engine.volume)
                .frame(width: 104, height: 8)
        }
        .fixedSize()
    }

    // MARK: - Playlist

    private var playlistPanel: some View {
        Panel {
            HStack {
                Text("QUEUE · \(engine.playlist.count)")
                    .font(.mono(Typography.label)).tracking(2.2).foregroundStyle(Theme.inkFaint)
                Spacer()
                if !engine.playlist.isEmpty {
                    Button { engine.clear() } label: {
                        Text("CLEAR").font(.mono(Typography.label, .bold)).tracking(1.5)
                            .foregroundStyle(Theme.inkDim)
                    }
                    .buttonStyle(.plain)
                    .help("Remove all songs")
                }
            }
            if engine.playlist.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    DotText(text: "EMPTY", dot: 4, gap: 2, color: Theme.inkFaint)
                    Button(action: openFiles) {
                        Text("+ ADD FILES").font(.mono(11)).tracking(2)
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, Spacing.sectionPadding)
                            .padding(.vertical, Spacing.controlSpacing)
                            .overlay(RoundedRectangle(cornerRadius: Radius.button).stroke(Theme.panelStroke))
                    }.buttonStyle(.plain)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.hairline) {
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
            RoundedRectangle(cornerRadius: Radius.panel)
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
        return HStack(spacing: Spacing.controlSpacing) {
            if isCur {
                Rectangle().fill(Theme.red).frame(width: 3, height: 26)
            } else {
                Text(String(format: "%02d", idx + 1))
                    .font(.mono(Typography.caption)).foregroundStyle(Theme.inkFaint).frame(width: 18)
            }
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(track.title).font(.grotesk(Typography.body, .medium)).lineLimit(1)
                    .foregroundStyle(isCur || isSel ? Theme.dotOn : Theme.ink)
                Text(track.artist.uppercased()).font(.mono(Typography.label)).tracking(1)
                    .foregroundStyle(Theme.inkDim).lineLimit(1)
            }
            Spacer()
            Text(fmt(track.duration)).font(.mono(Typography.caption)).foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, Spacing.controlPadding).padding(.vertical, Spacing.controlVertical)
        .background(isSel ? Theme.bg : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Radius.button))
        .overlay(RoundedRectangle(cornerRadius: Radius.button)
            .stroke(Theme.panelStroke, lineWidth: isSel ? 1 : 0))
        .overlay(alignment: .top) {
            if draggingIndex != nil && draggingIndex == idx {
                Rectangle().fill(Theme.orange).frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { engine.play(index: idx) }
        .onTapGesture(count: 1) { engine.select(idx) }
        .contextMenu {
            Button(role: .destructive) { engine.remove(at: idx) } label: {
                Label("Remove from Queue", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

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


