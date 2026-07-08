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

    static let ice = Palette(
        id: "ice", name: "Ice",
        bg: 0x06090D, panel: 0x0B1118, grid: 0x101822, grain: 0x1C2C3A,
        cream: 0xDFEEFC, muted: 0x5E7A92, faint: 0x29404F,
        accent: 0x2BB6D6, accent2: 0x5AD0FF,
        bandLow: 0x20405A, bandMid: 0x2B8FB0, bandHigh: 0x4EC0E0, bandPeak: 0xD8F4FF)

    static let mono = Palette(
        id: "mono", name: "Mono",
        bg: 0x0B0B0B, panel: 0x121212, grid: 0x171717, grain: 0x262626,
        cream: 0xE8E8E8, muted: 0x777777, faint: 0x3A3A3A,
        accent: 0xBFBFBF, accent2: 0x8A8A8A,
        bandLow: 0x3A3A3A, bandMid: 0x777777, bandHigh: 0xAAAAAA, bandPeak: 0xFFFFFF)

    static let tokyoNight = Palette(
        id: "tokyo", name: "Tokyo Night",
        bg: 0x1A1B26, panel: 0x1F2335, grid: 0x1E2030, grain: 0x292E42,
        cream: 0xC0CAF5, muted: 0x565F89, faint: 0x3B4261,
        accent: 0x7AA2F7, accent2: 0xBB9AF7,
        bandLow: 0x7AA2F7, bandMid: 0x9ECE6A, bandHigh: 0xE0AF68, bandPeak: 0xF7768E)

    static let dracula = Palette(
        id: "dracula", name: "Dracula",
        bg: 0x282A36, panel: 0x21222C, grid: 0x2D2F3D, grain: 0x44475A,
        cream: 0xF8F8F2, muted: 0x6272A4, faint: 0x3B3D4D,
        accent: 0xBD93F9, accent2: 0xFF79C6,
        bandLow: 0x8BE9FD, bandMid: 0x50FA7B, bandHigh: 0xF1FA8C, bandPeak: 0xFF79C6)

    static let nord = Palette(
        id: "nord", name: "Nord",
        bg: 0x2E3440, panel: 0x2B303B, grid: 0x3B4252, grain: 0x434C5E,
        cream: 0xECEFF4, muted: 0x7B88A1, faint: 0x434C5E,
        accent: 0x88C0D0, accent2: 0x81A1C1,
        bandLow: 0x5E81AC, bandMid: 0xA3BE8C, bandHigh: 0xEBCB8B, bandPeak: 0xBF616A)

    static let gruvbox = Palette(
        id: "gruvbox", name: "Gruvbox",
        bg: 0x282828, panel: 0x1D2021, grid: 0x32302F, grain: 0x3C3836,
        cream: 0xEBDBB2, muted: 0x928374, faint: 0x3C3836,
        accent: 0xFE8019, accent2: 0xFABD2F,
        bandLow: 0x83A598, bandMid: 0xB8BB26, bandHigh: 0xFABD2F, bandPeak: 0xFB4934)

    static let catppuccin = Palette(
        id: "catppuccin", name: "Catppuccin",
        bg: 0x1E1E2E, panel: 0x181825, grid: 0x2A2A3C, grain: 0x313244,
        cream: 0xCDD6F4, muted: 0x7F849C, faint: 0x313244,
        accent: 0xCBA6F7, accent2: 0xF5C2E7,
        bandLow: 0x89B4FA, bandMid: 0xA6E3A1, bandHigh: 0xF9E2AF, bandPeak: 0xF38BA8)

    static let synthwave = Palette(
        id: "synthwave", name: "Synthwave",
        bg: 0x241B2F, panel: 0x1C1528, grid: 0x2A1F3D, grain: 0x3B2A52,
        cream: 0xF6E6FF, muted: 0x9D7CB8, faint: 0x3B2A52,
        accent: 0xF92AAD, accent2: 0x36F9F6,
        bandLow: 0x36F9F6, bandMid: 0xB893CE, bandHigh: 0xFF8B39, bandPeak: 0xFF7EDB)

    static let rosePine = Palette(
        id: "rosepine", name: "Rosé Pine",
        bg: 0x191724, panel: 0x1F1D2E, grid: 0x26233A, grain: 0x393552,
        cream: 0xE0DEF4, muted: 0x6E6A86, faint: 0x2A273F,
        accent: 0xC4A7E7, accent2: 0xEBBCBA,
        bandLow: 0x31748F, bandMid: 0x9CCFD8, bandHigh: 0xF6C177, bandPeak: 0xEB6F92)

    static let solarized = Palette(
        id: "solarized", name: "Solarized",
        bg: 0x002B36, panel: 0x073642, grid: 0x0A3A45, grain: 0x16505D,
        cream: 0x93A1A1, muted: 0x586E75, faint: 0x0A3A45,
        accent: 0x268BD2, accent2: 0x2AA198,
        bandLow: 0x268BD2, bandMid: 0x859900, bandHigh: 0xB58900, bandPeak: 0xDC322F)

    static let monokai = Palette(
        id: "monokai", name: "Monokai",
        bg: 0x272822, panel: 0x1E1F1C, grid: 0x2F302A, grain: 0x41423B,
        cream: 0xF8F8F2, muted: 0x75715E, faint: 0x3A3B34,
        accent: 0xFD971F, accent2: 0xA6E22E,
        bandLow: 0x66D9EF, bandMid: 0xA6E22E, bandHigh: 0xE6DB74, bandPeak: 0xF92672)

    static let oneDark = Palette(
        id: "onedark", name: "One Dark",
        bg: 0x282C34, panel: 0x21252B, grid: 0x2C313A, grain: 0x3A3F4B,
        cream: 0xABB2BF, muted: 0x5C6370, faint: 0x3A3F4B,
        accent: 0x61AFEF, accent2: 0x98C379,
        bandLow: 0x61AFEF, bandMid: 0x98C379, bandHigh: 0xE5C07B, bandPeak: 0xE06C75)

    static let everforest = Palette(
        id: "everforest", name: "Everforest",
        bg: 0x2B3339, panel: 0x232A2E, grid: 0x2D3C3F, grain: 0x3E4A4D,
        cream: 0xD3C6AA, muted: 0x859289, faint: 0x3E4A4D,
        accent: 0xA7C080, accent2: 0xE69875,
        bandLow: 0x7FBBB3, bandMid: 0xA7C080, bandHigh: 0xD3C6AA, bandPeak: 0xE67E80)

    static let githubDark = Palette(
        id: "githubdark", name: "GitHub Dark",
        bg: 0x0D1117, panel: 0x161B22, grid: 0x21262D, grain: 0x30363D,
        cream: 0xC9D1D9, muted: 0x8B949E, faint: 0x484F58,
        accent: 0x58A6FF, accent2: 0x3FB950,
        bandLow: 0x58A6FF, bandMid: 0x3FB950, bandHigh: 0xD29922, bandPeak: 0xF85149)

    static let nightOwl = Palette(
        id: "nightowl", name: "Night Owl",
        bg: 0x011627, panel: 0x0B1D2F, grid: 0x122D42, grain: 0x1D3B53,
        cream: 0xD6DEEB, muted: 0x637D97, faint: 0x334E68,
        accent: 0x82AAFF, accent2: 0xC792EA,
        bandLow: 0x7FDBCA, bandMid: 0x82AAFF, bandHigh: 0xFFCB6B, bandPeak: 0xEF5350)

    static let ayuDark = Palette(
        id: "ayudark", name: "Ayu Dark",
        bg: 0x0A0E14, panel: 0x11151E, grid: 0x151A24, grain: 0x1F2430,
        cream: 0xCBCCC6, muted: 0x707A8C, faint: 0x363E4A,
        accent: 0xF29718, accent2: 0x39BAE6,
        bandLow: 0x39BAE6, bandMid: 0xAAD94C, bandHigh: 0xF29718, bandPeak: 0xF07178)

    static let horizon = Palette(
        id: "horizon", name: "Horizon",
        bg: 0x1C1A21, panel: 0x23212A, grid: 0x2B2835, grain: 0x3A3547,
        cream: 0xE3D9E5, muted: 0x9C8DA8, faint: 0x3A3547,
        accent: 0xE95678, accent2: 0xFAB795,
        bandLow: 0x6FD991, bandMid: 0xFAB795, bandHigh: 0xFAC29A, bandPeak: 0xE95678)

    static let all: [Palette] = [
        classic, iris, amber, ice, mono,
        tokyoNight, dracula, nord, gruvbox, catppuccin,
        synthwave, rosePine, solarized, monokai,
        oneDark, everforest, githubDark, nightOwl, ayuDark, horizon
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


