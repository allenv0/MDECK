import Foundation
import AVFoundation
import Accelerate
import AppKit

struct Track: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var title: String
    var artist: String
    var album: String
    var duration: Double
    var artwork: NSImage?

    static func == (a: Track, b: Track) -> Bool { a.id == b.id }
}

@MainActor
final class AudioEngine: ObservableObject {
    @Published var playlist: [Track] = []
    @Published var currentIndex: Int? = nil
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Float = 0.8 { didSet { mixer.outputVolume = volume } }
    @Published var bands: [Float] = Array(repeating: 0, count: 16)
    @Published var level: Float = 0          // overall RMS level 0...1

    var currentTrack: Track? { currentIndex.flatMap { playlist.indices.contains($0) ? playlist[$0] : nil } }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var mixer: AVAudioMixerNode { engine.mainMixerNode }
    private var file: AVAudioFile?
    private var sampleRate: Double = 44100
    private var totalFrames: AVAudioFramePosition = 0
    private var seekFrame: AVAudioFramePosition = 0     // where current schedule started
    private var displayTimer: Timer?

    // FFT
    private let fftSize = 1024
    private var fftSetup: FFTSetup?
    private var window = [Float]()

    init() {
        engine.attach(player)
        engine.connect(player, to: mixer, format: nil)
        mixer.outputVolume = volume
        let log2n = vDSP_Length(log2(Float(fftSize)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }

    deinit { if let s = fftSetup { vDSP_destroy_fftsetup(s) } }

    // MARK: - Library

    func add(urls: [URL]) {
        var added: [Track] = []
        for url in urls {
            guard ["mp3","m4a","aac","wav","aiff","flac"].contains(url.pathExtension.lowercased()) else { continue }
            added.append(makeTrack(url))
        }
        let wasEmpty = playlist.isEmpty
        playlist.append(contentsOf: added)
        if wasEmpty, let first = added.first, let idx = playlist.firstIndex(of: first) {
            load(index: idx, autoplay: false)
        }
        for t in added { loadMetadata(for: t) }
    }

    private func makeTrack(_ url: URL) -> Track {
        var dur: Double = 0
        if let f = try? AVAudioFile(forReading: url) {
            dur = Double(f.length) / f.processingFormat.sampleRate
        }
        return Track(url: url, title: url.deletingPathExtension().lastPathComponent,
                     artist: "—", album: "—", duration: dur, artwork: nil)
    }

    private func loadMetadata(for track: Track) {
        let asset = AVURLAsset(url: track.url)
        Task {
            var title: String?, artist: String?, album: String?; var art: NSImage?
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
            await MainActor.run {
                guard let i = self.playlist.firstIndex(where: { $0.id == track.id }) else { return }
                if let t = title, !t.isEmpty { self.playlist[i].title = t }
                if let a = artist, !a.isEmpty { self.playlist[i].artist = a }
                if let al = album, !al.isEmpty { self.playlist[i].album = al }
                if let art { self.playlist[i].artwork = art }
            }
        }
    }

    // MARK: - Transport

    func load(index: Int, autoplay: Bool) {
        guard playlist.indices.contains(index) else { return }
        stopEngineOnly()
        currentIndex = index
        let url = playlist[index].url
        guard let f = try? AVAudioFile(forReading: url) else { return }
        file = f
        sampleRate = f.processingFormat.sampleRate
        totalFrames = f.length
        duration = Double(totalFrames) / sampleRate
        currentTime = 0
        seekFrame = 0
        installTap()
        scheduleSegment(from: 0)
        if autoplay { play() } else { isPlaying = false }
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

    func next() {
        guard let i = currentIndex else { return }
        let n = i + 1
        if playlist.indices.contains(n) { load(index: n, autoplay: true) }
        else { pause(); seek(to: 0) }
    }

    func prev() {
        guard let i = currentIndex else { return }
        if currentTime > 3 { seek(to: 0); return }
        let p = i - 1
        if playlist.indices.contains(p) { load(index: p, autoplay: true) }
        else { seek(to: 0) }
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
        file.framePosition = frame
        player.scheduleSegment(file, startingFrame: frame,
                               frameCount: AVAudioFrameCount(remaining),
                               at: nil) { [weak self] in
            Task { @MainActor in self?.handleSegmentEnd() }
        }
    }

    private func handleSegmentEnd() {
        // Fired when the scheduled buffer drains. Only treat as track-end if we're near the end.
        guard isPlaying else { return }
        if currentTime >= duration - 0.5 { next() }
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
    }

    // MARK: - FFT spectrum

    private func installTap() {
        mixer.removeTap(onBus: 0)
        mixer.installTap(onBus: 0, bufferSize: AVAudioFrameCount(fftSize), format: mixer.outputFormat(forBus: 0)) { [weak self] buf, _ in
            self?.process(buf)
        }
    }

    private func process(_ buffer: AVAudioPCMBuffer) {
        guard let setup = fftSetup, let ch = buffer.floatChannelData else { return }
        let n = min(Int(buffer.frameLength), fftSize)
        guard n == fftSize else { return }
        let samples = ch[0]

        var windowed = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(samples, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

        // RMS for overall level
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(fftSize))

        let half = fftSize / 2
        var real = [Float](repeating: 0, count: half)
        var imag = [Float](repeating: 0, count: half)
        var magnitudes = [Float](repeating: 0, count: half)
        windowed.withUnsafeBufferPointer { ptr in
            real.withUnsafeMutableBufferPointer { rp in
                imag.withUnsafeMutableBufferPointer { ip in
                    var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                    ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: half) { typed in
                        vDSP_ctoz(typed, 2, &split, 1, vDSP_Length(half))
                    }
                    vDSP_fft_zrip(setup, &split, 1, vDSP_Length(log2(Float(fftSize))), FFTDirection(FFT_FORWARD))
                    vDSP_zvmags(&split, 1, &magnitudes, 1, vDSP_Length(half))
                }
            }
        }

        // Group into log-spaced bands.
        let bandCount = 16
        var out = [Float](repeating: 0, count: bandCount)
        let minBin = 2
        for b in 0..<bandCount {
            let lo = Int(Double(half - minBin) * pow(Double(b) / Double(bandCount), 2.0)) + minBin
            let hi = Int(Double(half - minBin) * pow(Double(b + 1) / Double(bandCount), 2.0)) + minBin
            let a = max(minBin, lo), z = max(a + 1, min(half, hi))
            var sum: Float = 0
            for i in a..<z { sum += magnitudes[i] }
            let meanPower = sum / Float(z - a)
            // Normalize to ~0...1 amplitude (zvmags is unscaled power for an N-pt zrip FFT).
            let amp = sqrtf(meanPower) * 2 / Float(fftSize)
            // Spectral tilt: lift higher bands so bass doesn't dominate the left side.
            let tilt = Float(b) * 1.7
            let db = 20 * log10f(amp + 1e-7) + tilt
            // Map a -58dB...-12dB window onto the meter so peaks rarely peg.
            let norm = max(0, min(1, (db + 58) / 46))
            out[b] = norm
        }

        let lvl = min(1, rms * 6)
        Task { @MainActor in
            // smooth
            for i in 0..<self.bands.count {
                let target = i < out.count ? out[i] : 0
                self.bands[i] = self.bands[i] * 0.6 + target * 0.4
            }
            self.level = self.level * 0.7 + lvl * 0.3
        }
    }
}
