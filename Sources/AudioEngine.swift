import Foundation
import AVFoundation
import AppKit

enum RepeatMode { case off, all, one }

struct Track: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var title: String
    var artist: String
    var album: String
    var duration: Double
    var artwork: NSImage?
    var artworkFileName: String?     // filename of saved custom artwork in musicDirectory

    // Audio quality metadata
    var codec: String = ""          // "MP3", "FLAC", "AAC", "WAV", "AIFF"
    var sampleRate: Int = 0         // Hz (e.g. 44100)
    var bitDepth: Int = 0           // bits (0 for lossy/compressed)
    var channels: Int = 0           // 1=mono, 2=stereo
    var bitRate: Int = 0            // kbps (e.g. 320)

    var qualityLabel: String {
        var parts: [String] = []
        if !codec.isEmpty { parts.append(codec) }
        if sampleRate > 0 {
            let khz = Double(sampleRate) / 1000.0
            parts.append(khz == floor(khz) ? "\(Int(khz))kHz" : String(format: "%.1fkHz", khz))
        }
        if bitDepth > 0 { parts.append("\(bitDepth)-bit") }
        if channels == 1 { parts.append("Mono") }
        else if channels == 2 { parts.append("Stereo") }
        else if channels > 2 { parts.append("\(channels)ch") }
        if bitRate > 0 { parts.append("\(bitRate)kbps") }
        return parts.isEmpty ? "" : parts.joined(separator: " · ")
    }

    static func == (a: Track, b: Track) -> Bool { a.id == b.id }
}

@MainActor
final class AudioEngine: ObservableObject {
    @Published var playlist: [Track] = []
    @Published var currentIndex: Int? = nil { didSet { if !restoring { savePlaylist() } } }
    @Published var selectedIndex: Int? = nil
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Float = 0.8 {
        didSet { mixer.outputVolume = volume; UserDefaults.standard.set(volume, forKey: "MDECK.volume") }
    }
    @Published var bands: [Float] = Array(repeating: 0, count: 16)
    @Published var level: Float = 0
    @Published var waveformSamples: [Float] = []
    @Published var repeatMode: RepeatMode = .off { didSet { if !restoring { savePlaylist() } } }
    @Published var shuffle: Bool = false { didSet { if !restoring { savePlaylist() } } }
    @Published var levels: [Float] = []
    @Published var trackTransitionCount = 0

    // Equalizer (10-band graphic EQ)
    static let eqBandCount = 10
    static let eqFrequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    @Published var eqGains: [Float] = Array(repeating: 0, count: eqBandCount) {
        didSet { applyEQ(); saveEQ() }
    }
    @Published var eqEnabled: Bool = true {
        didSet { applyEQ(); saveEQ() }
    }

    private var restoring = false
    let levelCapacity = 80
    private var tickCount = 0

    var currentTrack: Track? { currentIndex.flatMap { playlist.indices.contains($0) ? playlist[$0] : nil } }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let eq = AVAudioUnitEQ(numberOfBands: eqBandCount)
    private var mixer: AVAudioMixerNode { engine.mainMixerNode }
    private var file: AVAudioFile?
    private var sampleRate: Double = 44100
    private var totalFrames: AVAudioFramePosition = 0
    private var seekFrame: AVAudioFramePosition = 0
    private var scheduleToken = 0
    private var displayTimer: Timer?

    private let fftAnalyzer = FFTAnalyzer()

    // MARK: - Persistence Paths

    private var musicDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("com.moerdowo.MDECK/Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }

    private var playlistFile: URL {
        musicDirectory.appendingPathComponent("playlist.json")
    }

    // MARK: - Codable Persistence Models

    private struct SavedTrack: Codable {
        let fileName: String
        let title: String
        let artist: String
        let album: String
        let duration: Double
        let artworkFileName: String?
        let codec: String?
        let sampleRate: Int?
        let bitDepth: Int?
        let channels: Int?
        let bitRate: Int?
    }

    private struct SavedPlaylist: Codable {
        let tracks: [SavedTrack]
        let currentIndex: Int
        let shuffle: Bool
        let repeatMode: String
    }

    init() {
        engine.attach(player)
        engine.attach(eq)
        configureEQ()
        engine.connect(player, to: eq, format: nil)
        engine.connect(eq, to: mixer, format: nil)
        mixer.outputVolume = volume

        if UserDefaults.standard.object(forKey: "MDECK.volume") != nil {
            volume = UserDefaults.standard.float(forKey: "MDECK.volume")
        }
        restoreEQ()
        applyEQ()

        loadPlaylist()
    }

    // MARK: - Equalizer

    private func configureEQ() {
        for (i, freq) in Self.eqFrequencies.enumerated() {
            let band = eq.bands[i]
            band.filterType = .parametric
            band.frequency = Float(freq)
            band.bandwidth = 1.0
            band.gain = 0
            band.bypass = false
        }
        eq.globalGain = 0
    }

    private func applyEQ() {
        for i in 0..<Self.eqBandCount {
            eq.bands[i].gain = Float(eqGains[i])
            eq.bands[i].bypass = !eqEnabled
        }
    }

    private func saveEQ() {
        guard !restoring else { return }
        let d = UserDefaults.standard
        d.set(eqGains.map { Double($0) }, forKey: "MDECK.eqGains")
        d.set(eqEnabled, forKey: "MDECK.eqEnabled")
    }

    private func restoreEQ() {
        let d = UserDefaults.standard
        if let saved = d.array(forKey: "MDECK.eqGains") as? [Double], saved.count == Self.eqBandCount {
            eqGains = saved.map { Float($0) }
        }
        if d.object(forKey: "MDECK.eqEnabled") != nil {
            eqEnabled = d.bool(forKey: "MDECK.eqEnabled")
        }
    }

    // MARK: - Persistence

    private func savePlaylist() {
        let saved = SavedPlaylist(
            tracks: playlist.map { SavedTrack(
                fileName: $0.url.lastPathComponent,
                title: $0.title,
                artist: $0.artist,
                album: $0.album,
                duration: $0.duration,
                artworkFileName: $0.artworkFileName,
                codec: $0.codec.isEmpty ? nil : $0.codec,
                sampleRate: $0.sampleRate > 0 ? $0.sampleRate : nil,
                bitDepth: $0.bitDepth > 0 ? $0.bitDepth : nil,
                channels: $0.channels > 0 ? $0.channels : nil,
                bitRate: $0.bitRate > 0 ? $0.bitRate : nil
            )},
            currentIndex: currentIndex ?? -1,
            shuffle: shuffle,
            repeatMode: repeatMode == .off ? "off" : repeatMode == .all ? "all" : "one"
        )
        if let data = try? JSONEncoder().encode(saved) {
            try? data.write(to: playlistFile, options: .atomic)
        }
    }

    private func loadPlaylist() {
        restoring = true
        defer { restoring = false }

        guard let data = try? Data(contentsOf: playlistFile),
              let saved = try? JSONDecoder().decode(SavedPlaylist.self, from: data) else { return }

        var restored: [Track] = []
        for st in saved.tracks {
            let url = musicDirectory.appendingPathComponent(st.fileName)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            var artwork: NSImage? = nil
            if let artName = st.artworkFileName {
                let artURL = musicDirectory.appendingPathComponent(artName)
                if let data = try? Data(contentsOf: artURL) { artwork = NSImage(data: data) }
            }
            let track = Track(url: url, title: st.title, artist: st.artist, album: st.album,
                              duration: st.duration, artwork: artwork,
                              codec: st.codec ?? "",
                              sampleRate: st.sampleRate ?? 0,
                              bitDepth: st.bitDepth ?? 0,
                              channels: st.channels ?? 0,
                              bitRate: st.bitRate ?? 0)
            restored.append(track)
        }
        playlist = restored

        if saved.currentIndex >= 0, playlist.indices.contains(saved.currentIndex) {
            load(index: saved.currentIndex, autoplay: false)
        }

        // Load artwork asynchronously
        for t in restored { loadMetadata(for: t) }
    }

    // MARK: - Custom Artwork

    /// Set custom artwork for the current track from a dropped image.
    func setCustomArtwork(_ image: NSImage) {
        guard let idx = currentIndex else { return }
        let audioName = playlist[idx].url.lastPathComponent
        let artName = audioName + "_artwork.png"
        let artURL = musicDirectory.appendingPathComponent(artName)

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: artURL)
        }

        playlist[idx].artwork = image
        playlist[idx].artworkFileName = artName
        savePlaylist()
    }

    /// Remove the custom artwork file for a given track (e.g. when resetting).
    func clearCustomArtwork(for track: Track) {
        guard let idx = playlist.firstIndex(where: { $0.id == track.id }),
              let artName = playlist[idx].artworkFileName else { return }
        let artURL = musicDirectory.appendingPathComponent(artName)
        try? FileManager.default.removeItem(at: artURL)
        playlist[idx].artworkFileName = nil
        playlist[idx].artwork = nil
        savePlaylist()
    }

    // MARK: - Library

    func add(urls: [URL]) {
        var added: [Track] = []
        for url in urls {
            guard ["mp3","m4a","aac","wav","aiff","flac"].contains(url.pathExtension.lowercased()) else { continue }

            // Copy file into the sandboxed Music directory for persistent access
            let ext = url.pathExtension
            let fileName = "\(UUID().uuidString).\(ext)"
            let dest = musicDirectory.appendingPathComponent(fileName)
            try? FileManager.default.copyItem(at: url, to: dest)
            guard FileManager.default.fileExists(atPath: dest.path) else { continue }

            let originalName = url.deletingPathExtension().lastPathComponent
            let track = makeTrack(dest, title: originalName)
            added.append(track)
        }

        let wasEmpty = playlist.isEmpty
        playlist.append(contentsOf: added)
        if wasEmpty, let first = added.first, let idx = playlist.firstIndex(of: first) {
            load(index: idx, autoplay: false)
        }
        for t in added { loadMetadata(for: t) }
        savePlaylist()
    }

    // Single-click: just highlight the row.
    func select(_ index: Int) {
        guard playlist.indices.contains(index) else { return }
        selectedIndex = index
    }

    // Double-click: load and play.
    func play(index: Int) {
        guard playlist.indices.contains(index) else { return }
        selectedIndex = index
        load(index: index, autoplay: true)
    }

    // Reorder the queue, keeping the playing track's index in sync.
    func move(from: Int, to: Int) {
        guard from != to, playlist.indices.contains(from) else { return }
        let curId = currentTrack?.id
        let item = playlist.remove(at: from)
        let dest = max(0, min(playlist.count, to))
        playlist.insert(item, at: dest)
        if let curId { currentIndex = playlist.firstIndex { $0.id == curId } }
        savePlaylist()
    }

    // Add tracks from dropped Finder item providers (file URLs).
    func add(providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []
            for p in providers {
                if let url = await loadURL(from: p) {
                    urls.append(url)
                }
            }
            let sorted = urls.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            await MainActor.run { add(urls: sorted) }
        }
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                continuation.resume(returning: url)
            }
        }
    }

    private func makeTrack(_ url: URL, title: String? = nil) -> Track {
        var dur: Double = 0
        var sampleRate: Int = 0
        var channels: Int = 0
        var bitDepth: Int = 0
        if let f = try? AVAudioFile(forReading: url) {
            dur = Double(f.length) / f.processingFormat.sampleRate
            let fmt = f.processingFormat
            sampleRate = Int(fmt.sampleRate)
            channels = Int(fmt.channelCount)
            bitDepth = AudioEngine.bitDepth(from: f.fileFormat.commonFormat)
        }
        let codec = url.pathExtension.uppercased()
        return Track(url: url,
                     title: title ?? url.deletingPathExtension().lastPathComponent,
                     artist: "—", album: "—", duration: dur, artwork: nil,
                     codec: codec, sampleRate: sampleRate, bitDepth: bitDepth, channels: channels)
    }

    /// Map AVAudioCommonFormat to bit depth (returns 0 for compressed/other).
    private static func bitDepth(from commonFormat: AVAudioCommonFormat) -> Int {
        switch commonFormat {
        case .pcmFormatInt16:    return 16
        case .pcmFormatInt32:    return 32
        case .pcmFormatFloat32:  return 32
        case .pcmFormatFloat64:  return 64
        default:                 return 0
        }
    }

    private func loadMetadata(for track: Track) {
        let asset = AVURLAsset(url: track.url)
        Task {
            var title: String?, artist: String?, album: String?; var art: NSImage?
            var bitRate: Int = 0

            // Load metadata tags
            if let meta = try? await asset.load(.commonMetadata) {
                for item in meta {
                    guard let key = item.commonKey else { continue }
                    switch key {
                    case .commonKeyTitle:  title  = try? await item.load(.stringValue)
                    case .commonKeyArtist: artist = try? await item.load(.stringValue)
                    case .commonKeyAlbumName: album = try? await item.load(.stringValue)
                    case .commonKeyArtwork:
                        if let d = try? await item.load(.dataValue) { art = NSImage(data: d) }
                    default: break
                    }
                }
            }

            // Extract bitrate from audio track
            if let tracks = try? await asset.load(.tracks) {
                for t in tracks where t.mediaType == .audio {
                    if #available(macOS 13, *) {
                        if let rate = try? await t.load(.estimatedDataRate), rate > 0 {
                            bitRate = Int(rate / 1000)
                        }
                    } else {
                        let rate = t.estimatedDataRate
                        if rate > 0 { bitRate = Int(rate / 1000) }
                    }
                    break
                }
            }

            await MainActor.run {
                guard let i = self.playlist.firstIndex(where: { $0.id == track.id }) else { return }
                if let t = title, !t.isEmpty { self.playlist[i].title = t }
                if let a = artist, !a.isEmpty { self.playlist[i].artist = a }
                if let al = album, !al.isEmpty { self.playlist[i].album = al }
                if bitRate > 0 { self.playlist[i].bitRate = bitRate }
                if let art, self.playlist[i].artworkFileName == nil { self.playlist[i].artwork = art }
                // Persist updated metadata
                self.savePlaylist()
            }
        }
    }

    // MARK: - Transport

    func load(index: Int, autoplay: Bool) {
        guard playlist.indices.contains(index) else { return }
        stopEngineOnly()
        let wasNewTrack = currentIndex != index
        currentIndex = index
        let url = playlist[index].url
        guard let f = try? AVAudioFile(forReading: url) else { return }
        file = f
        sampleRate = f.processingFormat.sampleRate
        totalFrames = f.length
        duration = Double(totalFrames) / sampleRate
        currentTime = 0
        seekFrame = 0
        levels.removeAll()

        // Update quality info from the actual audio file
        let fmt = f.processingFormat
        playlist[index].sampleRate = Int(fmt.sampleRate)
        playlist[index].channels = Int(fmt.channelCount)
        playlist[index].bitDepth = AudioEngine.bitDepth(from: f.fileFormat.commonFormat)
        playlist[index].codec = url.pathExtension.uppercased()

        installTap()
        scheduleSegment(from: 0)
        if autoplay {
            if wasNewTrack { trackTransitionCount += 1 }
            play()
        } else {
            isPlaying = false
        }
    }

    func togglePlay() {
        if currentIndex == nil, !playlist.isEmpty { load(index: 0, autoplay: true); return }
        isPlaying ? pause() : play()
    }

    func play() {
        guard file != nil else { return }
        do {
            if !engine.isRunning { try engine.start() }
            player.play()
            isPlaying = true
            startDisplayTimer()
        } catch { print("engine start failed: \(error)") }
    }

    func pause() {
        player.pause()
        isPlaying = false
        bands = bands.map { _ in 0 }
        level = 0
    }

    func next() { advance(auto: false) }

    func cycleRepeat() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    private func advance(auto: Bool) {
        guard let i = currentIndex, !playlist.isEmpty else { return }
        if auto && repeatMode == .one { seek(to: 0); play(); return }
        var n = shuffle ? randomOtherIndex(from: i) : i + 1
        if !playlist.indices.contains(n) {
            if repeatMode == .all { n = shuffle ? randomOtherIndex(from: i) : 0 }
            else { pause(); seek(to: 0); return }
        }
        load(index: n, autoplay: true)
    }

    func prev() {
        guard let i = currentIndex, !playlist.isEmpty else { return }
        if currentTime > 3 { seek(to: 0); return }
        var p = shuffle ? randomOtherIndex(from: i) : i - 1
        if !playlist.indices.contains(p) {
            if repeatMode == .all { p = playlist.count - 1 } else { seek(to: 0); return }
        }
        load(index: p, autoplay: true)
    }

    func clear() {
        stopEngineOnly()
        isPlaying = false
        file = nil

        for track in playlist {
            if let artName = track.artworkFileName {
                let artURL = musicDirectory.appendingPathComponent(artName)
                try? FileManager.default.removeItem(at: artURL)
            }
            try? FileManager.default.removeItem(at: track.url)
        }
        playlist.removeAll()
        currentIndex = nil
        selectedIndex = nil
        currentTime = 0
        duration = 0
        bands = bands.map { _ in 0 }
        level = 0
        savePlaylist()
    }

    func remove(at index: Int) {
        guard playlist.indices.contains(index) else { return }
        let wasCurrent = currentIndex == index

        // Remove the copied file from disk
        try? FileManager.default.removeItem(at: playlist[index].url)
        if let artName = playlist[index].artworkFileName {
            let artURL = musicDirectory.appendingPathComponent(artName)
            try? FileManager.default.removeItem(at: artURL)
        }

        playlist.remove(at: index)
        func adjust(_ idx: Int?) -> Int? {
            guard let i = idx else { return nil }
            if i == index { return nil }
            return i > index ? i - 1 : i
        }
        if wasCurrent {
            stopEngineOnly()
            isPlaying = false
            file = nil
            currentIndex = nil
            currentTime = 0
            duration = 0
            bands = bands.map { _ in 0 }
            level = 0
        } else {
            currentIndex = adjust(currentIndex)
        }
        selectedIndex = adjust(selectedIndex)
        savePlaylist()
    }

    private func randomOtherIndex(from i: Int) -> Int {
        guard playlist.count > 1 else { return i }
        var r = i
        while r == i { r = Int.random(in: 0..<playlist.count) }
        return r
    }

    func seek(to time: Double) {
        guard file != nil else { return }
        let wasPlaying = isPlaying
        let clamped = max(0, min(time, duration))
        let frame = AVAudioFramePosition(clamped * sampleRate)
        player.stop()
        seekFrame = frame
        currentTime = clamped
        scheduleSegment(from: frame)
        if wasPlaying { player.play() }
    }

    private func scheduleSegment(from frame: AVAudioFramePosition) {
        guard let file else { return }
        let remaining = totalFrames - frame
        guard remaining > 0 else { return }
        scheduleToken &+= 1
        let token = scheduleToken
        file.framePosition = frame
        player.scheduleSegment(file, startingFrame: frame,
                               frameCount: AVAudioFrameCount(remaining),
                               at: nil,
                               completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor in self?.handleSegmentEnd(token: token) }
        }
    }

    private func handleSegmentEnd(token: Int) {
        guard token == scheduleToken else { return }
        guard isPlaying else { return }
        advance(auto: true)
    }

    private func stopEngineOnly() {
        player.stop()
        displayTimer?.invalidate()
    }

    // MARK: - Time display

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard isPlaying,
              let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime) else { return }
        let played = Double(playerTime.sampleTime) / playerTime.sampleRate
        currentTime = min(duration, Double(seekFrame) / sampleRate + max(0, played))

        tickCount += 1
        if tickCount % 3 == 0 {
            levels.append(level)
            if levels.count > levelCapacity { levels.removeFirst(levels.count - levelCapacity) }
        }
    }

    // MARK: - FFT spectrum

    private func installTap() {
        mixer.removeTap(onBus: 0)
        mixer.installTap(onBus: 0, bufferSize: fftAnalyzer.makeBufferSize(), format: mixer.outputFormat(forBus: 0)) { [weak self] buf, _ in
            self?.process(buf)
        }
    }

    private func process(_ buffer: AVAudioPCMBuffer) {
        let result = fftAnalyzer.process(buffer)
        Task { @MainActor in
            let s = Float(AppSettings.shared.spectrumSmoothing)
            let inv = 1 - s
            let bands = self.bands
            for i in 0..<bands.count {
                let target = i < result.bands.count ? result.bands[i] : 0
                self.bands[i] = bands[i] * s + target * inv
            }
            let levelSmooth = 0.5 + s * 0.4
            self.level = self.level * levelSmooth + result.level * (1 - levelSmooth)

            // Extract real waveform samples from the PCM buffer
            if let ch = buffer.floatChannelData {
                let n = Int(buffer.frameLength)
                let step = max(1, n / 192)
                var slice: [Float] = []
                slice.reserveCapacity(192)
                for i in stride(from: 0, to: n, by: step) {
                    slice.append(ch[0][i])
                }
                self.waveformSamples.append(contentsOf: slice)
                if self.waveformSamples.count > 768 {
                    self.waveformSamples.removeFirst(self.waveformSamples.count - 768)
                }
            }
        }
    }
}
