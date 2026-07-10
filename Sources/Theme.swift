import SwiftUI

struct Palette: Identifiable, Equatable {
    let id: String
    let name: String
    let bg, panel, grid, grain: UInt32
    let cream, muted, faint: UInt32
    let accent, accent2: UInt32
    let bandLow, bandMid, bandHigh, bandPeak: UInt32
}

enum ThemeCatalog {
    static let classic = Palette(
        id: "classic", name: "Classic",
        bg: 0x0C0C0B, panel: 0x121211, grid: 0x161614, grain: 0x262622,
        cream: 0xE9E4D6, muted: 0x6E6B60, faint: 0x3A3A35,
        accent: 0xDE5A1E, accent2: 0x2BB6D6,
        bandLow: 0x55534A, bandMid: 0x9FC11A, bandHigh: 0xE07B1A, bandPeak: 0xD23A1F)

    static let iris = Palette(
        id: "iris", name: "Iris",
        bg: 0x0A0712, panel: 0x140E22, grid: 0x191430, grain: 0x2A2348,
        cream: 0xF4F1FF, muted: 0x8C84B6, faint: 0x39335C,
        accent: 0x8B6CFF, accent2: 0xB9A3FF,
        bandLow: 0x4A3A7A, bandMid: 0x7B5CFF, bandHigh: 0xB06CFF, bandPeak: 0xE9D8FF)

    static let amber = Palette(
        id: "amber", name: "Amber CRT",
        bg: 0x0A0805, panel: 0x12100A, grid: 0x1A1610, grain: 0x2C2414,
        cream: 0xF0D8A0, muted: 0x8A7445, faint: 0x3C3320,
        accent: 0xE0A020, accent2: 0xC08010,
        bandLow: 0x4A3A10, bandMid: 0xB07D10, bandHigh: 0xE0A820, bandPeak: 0xFFF0C0)

    static let mono = Palette(
        id: "mono", name: "Mono",
        bg: 0x0B0B0B, panel: 0x121212, grid: 0x171717, grain: 0x262626,
        cream: 0xE8E8E8, muted: 0x777777, faint: 0x3A3A3A,
        accent: 0xBFBFBF, accent2: 0x8A8A8A,
        bandLow: 0x3A3A3A, bandMid: 0x777777, bandHigh: 0xAAAAAA, bandPeak: 0xFFFFFF)

    static let dracula = Palette(
        id: "dracula", name: "Dracula",
        bg: 0x282A36, panel: 0x21222C, grid: 0x2D2F3D, grain: 0x44475A,
        cream: 0xF8F8F2, muted: 0x6272A4, faint: 0x3B3D4D,
        accent: 0xBD93F9, accent2: 0xFF79C6,
        bandLow: 0x8BE9FD, bandMid: 0x50FA7B, bandHigh: 0xF1FA8C, bandPeak: 0xFF79C6)

    static let silver = Palette(
        id: "silver", name: "Silver",
        bg: 0xD5D9DE, panel: 0xEEF0F2, grid: 0xD0D3D7, grain: 0xB4B8BD,
        cream: 0x2C2F33, muted: 0x5E636A, faint: 0xA2A6AC,
        accent: 0x5B8BAA, accent2: 0x8DABBF,
        bandLow: 0x758795, bandMid: 0x6D9DBA, bandHigh: 0x4EA8C8, bandPeak: 0xCC5544)

    static let ayuDark = Palette(
        id: "ayudark", name: "Ayu Dark",
        bg: 0x0A0E14, panel: 0x11151E, grid: 0x151A24, grain: 0x1F2430,
        cream: 0xCBCCC6, muted: 0x707A8C, faint: 0x363E4A,
        accent: 0xF29718, accent2: 0x39BAE6,
        bandLow: 0x39BAE6, bandMid: 0xAAD94C, bandHigh: 0xF29718, bandPeak: 0xF07178)

    // ── Braun ──────────────────────────────────────────────────
    // Inspired by Dieter Rams / 1970s German audio equipment.
    // Matte charcoal chassis, warm cream type, iconic orange accent,
    // and copper/amber spectrum tones for an analog, tactile feel.
    static let braun = Palette(
        id: "braun", name: "Braun",
        bg: 0x1A1C1E, panel: 0x26282B, grid: 0x303337, grain: 0x3E4044,
        cream: 0xDED5BE, muted: 0x898370, faint: 0x4D4942,
        accent: 0xD4792B, accent2: 0x6B8B9E,
        bandLow: 0x8A6E47, bandMid: 0xD4792B, bandHigh: 0xDA9E48, bandPeak: 0xCC3F32)

    static let all: [Palette] = [
        mono, classic, silver, iris, amber, dracula, ayuDark, braun
    ]

    static func byID(_ id: String) -> Palette { all.first { $0.id == id } ?? classic }
}

enum Theme {
    static var current: Palette = ThemeCatalog.classic
    static var customAccentEnabled = false
    static var customAccent: Color? = nil

    static var colorCache: [UInt32: Color] = [:]

    private static func hex(_ value: UInt32, alpha: Double = 1) -> Color {
        if let c = colorCache[value], alpha == 1 { return c }
        let c = Color(hex: value)
        if alpha == 1 { colorCache[value] = c }
        return alpha != 1 ? c.opacity(alpha) : c
    }

    static var bg: Color         { hex(current.bg) }
    static var panel: Color      { hex(current.panel) }
    static var panelStroke: Color { hex(current.faint, alpha: 0.25) }
    static var dotOn: Color      { hex(current.cream) }
    static var dotOff: Color     { hex(current.grain) }
    static var pixelOff: Color   { hex(current.grain, alpha: 0.45) }
    static var ink: Color        { hex(current.cream, alpha: 0.92) }
    static var inkDim: Color     { hex(current.muted) }
    static var inkFaint: Color   { hex(current.faint) }
    static var red: Color        { hex(current.bandPeak) }
    static var accent: Color     { customAccentEnabled && customAccent != nil ? customAccent! : hex(current.accent) }
    static var accent2: Color    { hex(current.accent2) }
    static var orange: Color     { accent }
    static var trackOff: Color   { hex(current.grid) }

    static var bandLow: Color    { hex(current.bandLow) }
    static var bandMid: Color    { hex(current.bandMid) }
    static var bandHigh: Color   { hex(current.bandHigh) }
    static var bandPeak: Color   { hex(current.bandPeak) }

}

struct PaletteKey: EnvironmentKey {
    static let defaultValue: Palette = ThemeCatalog.classic
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue; Theme.current = newValue; Theme.colorCache.removeAll() }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    private let key = "MDECK.theme"
    @Published var selectedID: String {
        didSet {
            Theme.current = ThemeCatalog.byID(selectedID)
            Theme.colorCache.removeAll()
            UserDefaults.standard.set(selectedID, forKey: key)
        }
    }

    var palettes: [Palette] { ThemeCatalog.all }
    var selected: Palette { ThemeCatalog.byID(selectedID) }

    init() {
        let saved = UserDefaults.standard.string(forKey: key) ?? ThemeCatalog.classic.id
        selectedID = saved
        Theme.current = ThemeCatalog.byID(saved)
    }

    func select(_ p: Palette) { selectedID = p.id }
}


