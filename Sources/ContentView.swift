import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var engine: AudioEngine
    @StateObject private var theme = ThemeManager()
    @ObservedObject private var settings = AppSettings.shared
    @State private var dropTargeted = false
    @State private var windowDropTargeted = false
    @State private var artDropTargeted = false
    @State private var artHovered = false
    @State private var draggingIndex: Int? = nil
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: AppSettings.shared.layoutDensity.spacing) {
            header
            HStack(spacing: AppSettings.shared.layoutDensity.spacing) {
                VStack(spacing: AppSettings.shared.layoutDensity.spacing) {
                    nowPlaying
                    transport
                }
                if settings.showPlaylist {
                    playlistPanel
                        .frame(width: 320)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .frame(
            minWidth: settings.showSpectrum || settings.showAlbumArt ? 680 : 480,
            minHeight: settings.showPlaylist ? 560 : 400
        )
        .animation(Anim.slide, value: settings.showPlaylist)
        .animation(Anim.slide, value: settings.showAlbumArt)
        .animation(Anim.slide, value: settings.showSpectrum)
        .padding(AppSettings.shared.layoutDensity.spacing)
        .background(Theme.bg)
        .overlay(alignment: .top) {
            LinearGradient(
                gradient: Gradient(colors: [
                    .white.opacity(OpacityToken.ghost),
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
        .clipShape(RoundedRectangle(cornerRadius: Radius.window, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.window, style: .continuous)
                .stroke(Color.white.opacity(OpacityToken.ghost), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.window, style: .continuous)
                .stroke(Color.black.opacity(0.35), lineWidth: 2)
                .offset(y: 1)
        )
        .environment(\.palette, theme.selected)
        .animation(Anim.theme, value: theme.selectedID)
        .focusEffectDisabled()
        .onDrop(of: [UTType.fileURL], isTargeted: $windowDropTargeted) { providers in
            engine.add(providers: providers)
            return true
        }
        .overlay {
            if windowDropTargeted {
                RoundedRectangle(cornerRadius: Radius.window, style: .continuous)
                    .fill(Theme.accent.opacity(OpacityToken.ghost))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.window, style: .continuous)
                            .stroke(Theme.accent, lineWidth: 2)
                    )
                    .overlay {
                        VStack(spacing: 12) {
                            DotText(text: "DROP FILES", dot: 5, gap: 2.5, spacing: 5, color: Theme.accent)
                            Text("Add to queue")
                                .font(.mono(Typography.caption)).tracking(1.5).foregroundStyle(Theme.inkDim)
                        }
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: windowDropTargeted)
        .onReceive(NotificationCenter.default.publisher(for: .openFiles)) { _ in openFiles() }
        .onAppear { NSWindow.allowsAutomaticWindowTabbing = false }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            DotText(text: "MDECK", dot: 1.8, gap: 1.1, spacing: 2.4, color: Theme.dotOn)
            modelBadge

            controlStrip

            Spacer()
            statusLED
            Text("PLAYLIST")
                .font(.mono(Typography.label)).tracking(Tracking.panel).foregroundStyle(Theme.inkDim)
                .padding(.leading, 8)
            GridToggle(on: $settings.showPlaylist)
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
        .frame(height: Spacing.headerHeight)
    }

    private var controlStrip: some View {
        HStack(spacing: Spacing.controlSpacing()) {
            RotaryKnob(size: 18)
            RotaryKnob(size: 18)
        }
        .padding(.horizontal, Spacing.controlPadding())
        .padding(.vertical, Spacing.snug)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.bg.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.button)
                .stroke(Color.white.opacity(OpacityToken.ghost), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.button)
                .inset(by: 0.5)
                .stroke(Color.black.opacity(OpacityToken.panelBorder), lineWidth: 1)
                .offset(y: 1)
        )
    }

    private var modelBadge: some View {
        Text("Fontier-Systems")
            .font(.mono(Typography.label, .bold))
            .tracking(Tracking.section)
            .foregroundStyle(Theme.inkFaint.opacity(0.7))
            .padding(.horizontal, Spacing.modelBadgeW)
            .padding(.vertical, Spacing.modelBadgeH)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.badge)
                    .stroke(Theme.inkFaint.opacity(OpacityToken.panelBorder), lineWidth: 1)
            )
            .padding(.leading, 6)
    }

    private var statusLED: some View {
        HStack(spacing: 5) {
            PowerLED(isActive: engine.isPlaying)
            Text(engine.isPlaying ? "PLAYING" : "IDLE")
                .font(.mono(Typography.label)).tracking(Tracking.panel).foregroundStyle(Theme.inkDim)
        }
    }

    // MARK: - Now Playing

    private var nowPlaying: some View {
        Panel(label: "Now Playing") {
            VStack(alignment: .leading, spacing: Spacing.sectionSpacing) {
                let titleText = (engine.currentTrack?.title ?? "NO SIGNAL").uppercased()
                MarqueeDotText(text: titleText,
                                dot: 3.6, gap: 1.8, spacing: 4, color: trackLoaded ? Theme.dotOn : Theme.inkDim,
                                speed: max(24, CGFloat(titleText.count) * 1.2))
                    .id(engine.currentIndex ?? -1)

                if trackLoaded {
                    Text((engine.currentTrack?.artist ?? "\u{2014}").uppercased())
                        .font(.grotesk(Typography.title, .semibold)).foregroundStyle(Theme.ink)
                    Text((engine.currentTrack?.album ?? "\u{2014}").uppercased())
                        .font(.mono(Typography.caption)).tracking(Tracking.label).foregroundStyle(Theme.inkDim)
                } else {
                    Text("DROP FILES TO PLAY")
                        .font(.mono(Typography.caption)).tracking(Tracking.section).foregroundStyle(Theme.inkFaint)
                        .phaseAnimator([false, true]) { content, pulse in
                            content.opacity(pulse ? 0.4 : 1)
                        } animation: { _ in Anim.pulse }
                }

                if settings.showAlbumArt {
                    albumArtSection
                }

                if settings.showSpectrum {
                    SpectrumView(
                        bands: trackLoaded ? engine.bands : [],
                        levels: trackLoaded ? engine.levels : [],
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
        .opacity(trackLoaded ? 1 : 0.85)
    }

    private var trackLoaded: Bool { engine.currentTrack != nil }

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
                    .opacity(artHovered ? 0.7 : 0.5)
                    .phaseAnimator([false, true]) { content, pulse in
                        content.opacity(pulse ? 0.55 : 0.45)
                    } animation: { _ in
                            Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.art))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.art)
                .stroke(artDropTargeted ? Theme.accent : (artHovered ? Theme.inkDim : Theme.panelStroke), lineWidth: artDropTargeted ? 2 : (artHovered ? 1.5 : 1))
        )
        .overlay(alignment: .bottom) {
            if artHovered && engine.currentTrack != nil {
                Text("DROP COVER")
                    .font(.mono(Typography.badge, .bold)).tracking(1)
                    .foregroundStyle(Theme.inkDim)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.art - 1))
            }
        }
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.15)) { artHovered = h }
        }
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
                    DotText(text: formatTime(engine.currentTime), dot: 3, gap: 1.5, color: trackLoaded ? Theme.dotOn : Theme.inkFaint)
                    Spacer()
                    DotText(text: formatTime(engine.duration), dot: 3, gap: 1.5, color: trackLoaded ? Theme.inkDim : Theme.inkFaint)
                }
                Scrubber(value: engine.currentTime, total: max(engine.duration, 0.01)) { t in
                    engine.seek(to: t)
                }
                .frame(height: 16)
                .opacity(trackLoaded ? 1 : 0.4)
                transportCluster
                    .opacity(trackLoaded ? 1 : 0.35)
            }
        }
        .frame(minHeight: 150)
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
        .padding(.horizontal, Spacing.controlPadding())
        .padding(.vertical, Spacing.snug * 2)
        .background(Theme.bg.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: Radius.input))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.input)
                .stroke(Theme.panelStroke, lineWidth: 1)
        )
    }

    private var volume: some View {
        HStack(spacing: Spacing.controlSpacing) {
            Text("VOL").font(.mono(Typography.label)).tracking(Tracking.panel).foregroundStyle(Theme.inkFaint)
            VolumeDots(value: $engine.volume)
                .frame(width: 104, height: 8)
        }
        .fixedSize()
    }

    // MARK: - Playlist

    private var playlistPanel: some View {
        Panel {
            HStack {
                Text("QUEUE \u{00B7} \(engine.playlist.count)")
                    .font(.mono(Typography.label)).tracking(Tracking.queue).foregroundStyle(Theme.inkFaint)
                Spacer()
                if !engine.playlist.isEmpty {
                    Button { engine.clear() } label: {
                        Text("CLEAR").font(.mono(Typography.label, .bold)).tracking(Tracking.section)
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
                        .phaseAnimator([false, true]) { content, pulse in
                            content.opacity(pulse ? 0.35 : 1)
                        } animation: { _ in Anim.pulse }
                    Button(action: openFiles) {
                        Text("+ ADD FILES").font(.mono(Typography.body)).tracking(Tracking.panel)
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, Spacing.sectionPadding)
                            .padding(.vertical, Spacing.controlSpacing)
                            .overlay(RoundedRectangle(cornerRadius: Radius.button).stroke(Theme.panelStroke))
                    }.buttonStyle(.plain)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.panel)
                        .stroke(Theme.accent.opacity(0.06), lineWidth: 1)
                )
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
                .stroke(Theme.accent, lineWidth: dropTargeted ? 2 : 0)
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
                DotText(text: "▶", dot: 2.2, gap: 1, spacing: 0, color: Theme.accent)
                    .frame(width: 18)
            } else {
                Text(String(format: "%02d", idx + 1))
                    .font(.mono(Typography.caption)).foregroundStyle(Theme.inkFaint).frame(width: 18)
            }
            VStack(alignment: .leading, spacing: Spacing.hairline) {
                Text(track.title).font(.grotesk(Typography.body, .medium)).lineLimit(1)
                    .foregroundStyle(isCur || isSel ? Theme.dotOn : Theme.ink)
                Text(track.artist.uppercased()).font(.mono(Typography.label)).tracking(Tracking.label)
                    .foregroundStyle(Theme.inkDim).lineLimit(1)
            }
            Spacer()
            Text(formatTime(track.duration)).font(.mono(Typography.caption)).foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, Spacing.controlPadding).padding(.vertical, Spacing.controlVertical)
        .background(isSel ? Theme.bg : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Radius.button))
        .overlay(RoundedRectangle(cornerRadius: Radius.button)
            .stroke(Theme.panelStroke, lineWidth: isSel ? 1 : 0))
        .overlay(alignment: .top) {
            if draggingIndex != nil && draggingIndex == idx {
                Rectangle().fill(Theme.accent).frame(height: 2)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(track.title) by \(track.artist)")
        .accessibilityHint("Double-click to play")
        .onTapGesture(count: 2) { engine.play(index: idx) }
        .onTapGesture(count: 1) { engine.select(idx) }
        .contextMenu {
            Button(role: .destructive) { engine.remove(at: idx) } label: {
                Label("Remove from Queue", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private var repeatLabel: String { engine.repeatMode == .one ? "LOOP\u{00B7}1" : "LOOP" }

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


