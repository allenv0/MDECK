import SwiftUI

/// Spectrum visualization styles
enum SpectrumStyle: String, CaseIterable, Sendable {
    case bars = "bars"
    case waveform = "waveform"
    case combined = "combined"

    var label: String {
        switch self {
        case .bars:     return "Bars"
        case .waveform: return "Wave"
        case .combined: return "Both"
        }
    }
}

/// Overall spacing density
enum LayoutDensity: String, CaseIterable, Sendable {
    case compact  = "compact"
    case normal   = "normal"
    case spacious = "spacious"

    var label: String {
        switch self {
        case .compact:  return "Compact"
        case .normal:   return "Normal"
        case .spacious: return "Spacious"
        }
    }

    var spacing: CGFloat { Spacing.density(self) }
}

/// Preset accent colors for the override picker
let accentPresets: [(name: String, hex: UInt32)] = [
    ("Orange", 0xDE5A1E),
    ("Red",    0xE03A3A),
    ("Pink",   0xFF79C6),
    ("Purple", 0xBD93F9),
    ("Blue",   0x2BB6D6),
    ("Teal",   0x2AA198),
    ("Green",  0x9FC11A),
    ("Yellow", 0xFABD2F),
    ("White",  0xCCCCCC),
]

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Published Properties

    @Published var spectrumStyle: SpectrumStyle = .bars {
        didSet { save() }
    }
    @Published var spectrumRows: Int = 14 {
        didSet { save() }
    }
    @Published var spectrumSmoothing: Double = 0.6 {
        didSet { save() }
    }

    @Published var accentOverrideEnabled: Bool = false {
        didSet { save(); applyAccentOverride() }
    }
    @Published var accentOverrideHex: UInt32? = nil {
        didSet { save(); applyAccentOverride() }
    }

    @Published var showAlbumArt: Bool = true {
        didSet { save() }
    }
    @Published var showSpectrum: Bool = true {
        didSet { save() }
    }

    @Published var layoutDensity: LayoutDensity = .normal {
        didSet { save() }
    }

    // MARK: - Persistence Keys

    private enum Key {
        static let spectrumStyle     = "MDeck.spectrumStyle"
        static let spectrumRows      = "MDeck.spectrumRows"
        static let spectrumSmoothing = "MDeck.spectrumSmoothing"
        static let accentEnabled     = "MDeck.accentOverrideEnabled"
        static let accentHex         = "MDeck.accentOverrideHex"
        static let showAlbumArt      = "MDeck.showAlbumArt"
        static let showSpectrum      = "MDeck.showSpectrum"
        static let layoutDensity     = "MDeck.layoutDensity"
    }

    init() {
        let d = UserDefaults.standard

        if let raw = d.string(forKey: Key.spectrumStyle),
           let style = SpectrumStyle(rawValue: raw) { spectrumStyle = style }
        if d.object(forKey: Key.spectrumRows) != nil { spectrumRows = d.integer(forKey: Key.spectrumRows) }
        if d.object(forKey: Key.spectrumSmoothing) != nil { spectrumSmoothing = d.double(forKey: Key.spectrumSmoothing) }

        accentOverrideEnabled = d.bool(forKey: Key.accentEnabled)
        if let h = d.object(forKey: Key.accentHex) as? Int { accentOverrideHex = UInt32(h) }

        if d.object(forKey: Key.showAlbumArt) != nil { showAlbumArt = d.bool(forKey: Key.showAlbumArt) }
        if d.object(forKey: Key.showSpectrum) != nil { showSpectrum = d.bool(forKey: Key.showSpectrum) }
        if let raw = d.string(forKey: Key.layoutDensity),
           let density = LayoutDensity(rawValue: raw) { layoutDensity = density }

        applyAccentOverride()
    }

    // MARK: - Accent

    func applyAccentOverride() {
        if accentOverrideEnabled, let hex = accentOverrideHex {
            Theme.customAccent = Color(hex: hex)
            Theme.customAccentEnabled = true
        } else {
            Theme.customAccentEnabled = false
            Theme.customAccent = nil
        }
    }

    /// Convenience – select an accent by preset hex or disable it.
    func selectAccent(_ hex: UInt32?) {
        if let hex {
            accentOverrideEnabled = true
            accentOverrideHex = hex
        } else {
            accentOverrideEnabled = false
            accentOverrideHex = nil
        }
    }

    // MARK: - Persist

    private func save() {
        let d = UserDefaults.standard
        d.set(spectrumStyle.rawValue,   forKey: Key.spectrumStyle)
        d.set(spectrumRows,             forKey: Key.spectrumRows)
        d.set(spectrumSmoothing,        forKey: Key.spectrumSmoothing)
        d.set(accentOverrideEnabled,    forKey: Key.accentEnabled)
        d.set(accentOverrideHex.map { Int($0) }, forKey: Key.accentHex)
        d.set(showAlbumArt,             forKey: Key.showAlbumArt)
        d.set(showSpectrum,             forKey: Key.showSpectrum)
        d.set(layoutDensity.rawValue,   forKey: Key.layoutDensity)
    }
}
