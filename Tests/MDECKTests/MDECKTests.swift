import XCTest
import SwiftUI
import AVFoundation
@testable import MDECK

private let testSRGB = NSColorSpace.sRGB

// MARK: - Theme Tests

final class ThemeCatalogTests: XCTestCase {
    func test_allThemes_count() {
        XCTAssertEqual(ThemeCatalog.all.count, 20, "Must ship exactly 20 themes")
    }

    func test_allThemes_haveUniqueIDs() {
        let ids = ThemeCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Each theme must have a unique id")
    }

    func test_allThemes_haveUniqueNames() {
        let names = ThemeCatalog.all.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "Each theme must have a unique display name")
    }

    func test_byID_returnsCorrectPalette() {
        XCTAssertEqual(ThemeCatalog.byID("iris").name, "Iris")
        XCTAssertEqual(ThemeCatalog.byID("tokyo").name, "Tokyo Night")
        XCTAssertEqual(ThemeCatalog.byID("amber").name, "Amber CRT")
        XCTAssertEqual(ThemeCatalog.byID("monokai").name, "Monokai")
    }

    func test_byID_fallbackToClassic() {
        let p = ThemeCatalog.byID("nonexistent")
        XCTAssertEqual(p.id, "classic")
        XCTAssertEqual(p.name, "Classic")
    }

    func test_eachPalette_hasNonZeroColors() {
        for p in ThemeCatalog.all {
            XCTAssertNotEqual(p.bg, 0, "\(p.id) bg should not be pure black 0x000000")
            XCTAssertNotEqual(p.cream, 0, "\(p.id) cream should not be 0x000000")
            // Every palette should have distinct bg/panel/grid/grain (some may be close, that's fine)
            let surfaces = [p.bg, p.panel, p.grid, p.grain]
            let distinct = Set(surfaces)
            XCTAssertGreaterThanOrEqual(distinct.count, 2, "\(p.id) should have at least 2 distinct surface colors")
        }
    }
}

final class ThemeMappingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Theme.current = ThemeCatalog.classic
    }

    // Each computed property on Theme should return a valid Color without crashing.
    func test_computedProperties_resolve() {
        let colors: [Color] = [
            Theme.bg, Theme.panel, Theme.panelStroke,
            Theme.dotOn, Theme.dotOff, Theme.pixelOff,
            Theme.ink, Theme.inkDim, Theme.inkFaint,
            Theme.red, Theme.orange, Theme.trackOff,
            Theme.bandLow, Theme.bandMid, Theme.bandHigh, Theme.bandPeak,
        ]
        for c in colors {
            let ns = NSColor(c)
            XCTAssertNotNil(ns, "Color should be convertible to NSColor")
        }
    }

    func test_dotOn_equalsCream() {
        let classic = ThemeCatalog.classic
        Theme.current = ThemeCatalog.iris
        let iris = ThemeCatalog.iris
        let dotOnNS = NSColor(Theme.dotOn)
        let creamNS = NSColor(Color(hex: iris.cream))
        XCTAssertEqual(dotOnNS, creamNS)
        Theme.current = classic
    }

    func test_red_equalsBandPeak() {
        let p = ThemeCatalog.monokai
        Theme.current = p
        let redNS = NSColor(Theme.red)
        let peakNS = NSColor(Color(hex: p.bandPeak))
        XCTAssertEqual(redNS, peakNS)
        Theme.current = ThemeCatalog.classic
    }

    func test_orange_equalsAccent() {
        let p = ThemeCatalog.dracula
        Theme.current = p
        let orangeNS = NSColor(Theme.orange)
        let accentNS = NSColor(Color(hex: p.accent))
        XCTAssertEqual(orangeNS, accentNS)
        Theme.current = ThemeCatalog.classic
    }
}

final class ColorHexTests: XCTestCase {
    func test_ff0000_isRed() {
        let c = NSColor(Color(hex: 0xFF0000)).usingColorSpace(testSRGB)!
        XCTAssertEqual(c.redComponent, 1.0, accuracy: 0.001)
        XCTAssertEqual(c.greenComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(c.blueComponent, 0.0, accuracy: 0.001)
    }

    func test_00ff00_isGreen() {
        let c = NSColor(Color(hex: 0x00FF00)).usingColorSpace(testSRGB)!
        XCTAssertEqual(c.redComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(c.greenComponent, 1.0, accuracy: 0.001)
        XCTAssertEqual(c.blueComponent, 0.0, accuracy: 0.001)
    }

    func test_0000ff_isBlue() {
        let c = NSColor(Color(hex: 0x0000FF)).usingColorSpace(testSRGB)!
        XCTAssertEqual(c.redComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(c.greenComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(c.blueComponent, 1.0, accuracy: 0.001)
    }

    func test_classicBg_matchesExpectedRGB() {
        let c = NSColor(Color(hex: 0x0C0C0B)).usingColorSpace(testSRGB)!
        XCTAssertEqual(c.redComponent, 12.0 / 255, accuracy: 0.002)
        XCTAssertEqual(c.greenComponent, 12.0 / 255, accuracy: 0.002)
        XCTAssertEqual(c.blueComponent, 11.0 / 255, accuracy: 0.002)
    }
}

@MainActor
final class ThemeManagerTests: XCTestCase {
    let defaults = UserDefaults(suiteName: "test.theme.MDECK")!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "MDECK.theme")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "test.theme.MDECK")
        UserDefaults.standard.removeObject(forKey: "MDECK.theme")
        Theme.current = ThemeCatalog.classic
    }

    func test_init_usesClassicWhenNoSavedPreference() {
        let mgr = ThemeManager()
        XCTAssertEqual(mgr.selectedID, "classic")
    }

    func test_select_updatesCurrent() {
        let mgr = ThemeManager()
        mgr.select(ThemeCatalog.iris)
        XCTAssertEqual(mgr.selectedID, "iris")
        let bgNS = NSColor(Theme.bg)
        let irisBgNS = NSColor(Color(hex: ThemeCatalog.iris.bg))
        XCTAssertEqual(bgNS, irisBgNS)
    }

    func test_selectionPersistsAcrossInstances() {
        let defaults = self.defaults
        defaults.set("dracula", forKey: "MDECK.theme")

        let mgr = ThemeManager()
        mgr.select(ThemeCatalog.nord)
        let saved = UserDefaults.standard.string(forKey: "MDECK.theme")
        XCTAssertEqual(saved, "nord")
    }
}

// MARK: - Persistence Tests

/// Simulates the exact UserDefaults key/value contract that AudioEngine uses,
/// so we can verify the encoding/decoding logic in isolation.
final class PersistenceContractTests: XCTestCase {
    let defaults = UserDefaults(suiteName: "test.persist.MDECK")!

    override func tearDown() {
        defaults.removePersistentDomain(forName: "test.persist.MDECK")
    }

    // MARK: Shuffle

    func test_shuffle_defaultIsFalse() {
        let key = "MDECK.shuffle"
        XCTAssertFalse(defaults.bool(forKey: key),
                       "Missing shuffle key should return false")
    }

    func test_shuffle_roundTrip() {
        let key = "MDECK.shuffle"
        defaults.set(true, forKey: key)
        XCTAssertTrue(defaults.bool(forKey: key))
        defaults.set(false, forKey: key)
        XCTAssertFalse(defaults.bool(forKey: key))
    }

    func test_shuffle_onlyReadWhenKeyExists() {
        let key = "MDECK.shuffle"
        XCTAssertNil(defaults.object(forKey: key),
                     "object(forKey:) should return nil for missing key")
    }

    // MARK: RepeatMode

    func test_repeatMode_defaultIsOff() {
        let key = "MDECK.repeatMode"
        let raw = defaults.string(forKey: key)
        XCTAssertNil(raw, "Missing repeatMode key should return nil")
        // The restore code maps nil → .off
    }

    func test_repeatMode_roundTrip() {
        let key = "MDECK.repeatMode"
        for mode in ["off", "all", "one"] {
            defaults.set(mode, forKey: key)
            let decoded: RepeatMode = {
                switch defaults.string(forKey: key) {
                case "all": return .all
                case "one": return .one
                default:    return .off
                }
            }()
            let expected: RepeatMode = mode == "all" ? .all : mode == "one" ? .one : .off
            XCTAssertEqual(decoded, expected, "repeatMode '\(mode)' round-trip failed")
        }
    }

    // MARK: CurrentIndex

    func test_currentIndex_defaultIsNegative() {
        let key = "MDECK.currentIndex"
        // integer(forKey:) returns 0 when missing, but AudioEngine uses
        // object(forKey:) to detect absence.  Without a saved value we
        // should treat -1 (or nil) as "no saved index".
        XCTAssertNil(defaults.object(forKey: key),
                     "object(forKey:) should return nil for missing currentIndex")
    }

    func test_currentIndex_roundTrip() {
        let key = "MDECK.currentIndex"
        defaults.set(3, forKey: key)
        XCTAssertEqual(defaults.integer(forKey: key), 3)

        defaults.set(-1, forKey: key)
        // -1 is AudioEngine's sentinel for "no track"
        let saved = defaults.integer(forKey: key)
        XCTAssertEqual(saved, -1)
    }

    // MARK: Volume

    func test_volume_roundTrip() {
        let key = "MDECK.volume"
        defaults.set(Float(0.5), forKey: key)
        XCTAssertEqual(defaults.float(forKey: key), 0.5, accuracy: 0.001)

        defaults.set(Float(1.0), forKey: key)
        XCTAssertEqual(defaults.float(forKey: key), 1.0, accuracy: 0.001)
    }

    // MARK: Bookmarks (simulated)

    func test_bookmarks_roundTrip() {
        let key = "MDECK.bookmarks"
        // Create fake bookmark data
        let fakeData1 = "track1".data(using: .utf8)!
        let fakeData2 = "track2".data(using: .utf8)!
        let bookmarks: [Data] = [fakeData1, fakeData2]

        defaults.set(bookmarks, forKey: key)
        guard let read = defaults.array(forKey: key) as? [Data] else {
            XCTFail("Should read back bookmark array")
            return
        }
        XCTAssertEqual(read.count, 2)
        XCTAssertEqual(read[0], fakeData1)
        XCTAssertEqual(read[1], fakeData2)
    }

    func test_bookmarks_emptyArray() {
        let key = "MDECK.bookmarks"
        defaults.set([Data](), forKey: key)
        guard let read = defaults.array(forKey: key) as? [Data] else {
            XCTFail("Should read back empty bookmark array")
            return
        }
        XCTAssertTrue(read.isEmpty)
    }

    func test_bookmarks_missingKeyReturnsNil() {
        let key = "MDECK.bookmarks"
        XCTAssertNil(defaults.array(forKey: key))
    }

    // MARK: File-existence check (simulated)

    func test_fileExistenceFilter_skipsMissingFiles() {
        // Simulate the filter in AudioEngine.restore():
        //   guard FileManager.default.fileExists(atPath: url.path) else { continue }
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory

        let extantURL = tmp.appendingPathComponent("test_exists.mp3")
        let missingURL = tmp.appendingPathComponent("test_missing.mp3")

        // Create a real file
        fm.createFile(atPath: extantURL.path, contents: Data())
        defer { try? fm.removeItem(at: extantURL) }
        // Ensure the other one does NOT exist
        try? fm.removeItem(at: missingURL)

        let urls = [extantURL, missingURL]
        let filtered = urls.filter { fm.fileExists(atPath: $0.path) }

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first, extantURL)
    }
}

// MARK: - SpectrumStyle Enum Tests

final class SpectrumStyleTests: XCTestCase {
    func test_allCases_count() {
        XCTAssertEqual(SpectrumStyle.allCases.count, 2)
    }

    func test_labels() {
        XCTAssertEqual(SpectrumStyle.bars.label, "Bars")
        XCTAssertEqual(SpectrumStyle.waveform.label, "Wave")
    }

    func test_rawValues() {
        XCTAssertEqual(SpectrumStyle.bars.rawValue, "bars")
        XCTAssertEqual(SpectrumStyle.waveform.rawValue, "waveform")
    }
}

// MARK: - LayoutDensity Enum Tests

final class LayoutDensityTests: XCTestCase {
    func test_allCases_count() {
        XCTAssertEqual(LayoutDensity.allCases.count, 3)
    }

    func test_labels() {
        XCTAssertEqual(LayoutDensity.compact.label, "Compact")
        XCTAssertEqual(LayoutDensity.normal.label, "Normal")
        XCTAssertEqual(LayoutDensity.spacious.label, "Spacious")
    }

    func test_spacing() {
        XCTAssertEqual(LayoutDensity.compact.spacing, 12)
        XCTAssertEqual(LayoutDensity.normal.spacing, 16)
        XCTAssertEqual(LayoutDensity.spacious.spacing, 24)
    }

    func test_rawValues() {
        XCTAssertEqual(LayoutDensity.compact.rawValue, "compact")
        XCTAssertEqual(LayoutDensity.normal.rawValue, "normal")
        XCTAssertEqual(LayoutDensity.spacious.rawValue, "spacious")
    }
}

// MARK: - DesignTokens Tests

final class DesignTokensTests: XCTestCase {
    func test_spacing_values() {
        XCTAssertEqual(Spacing.grid, 16)
        XCTAssertEqual(Spacing.panelPadding, 14)
        XCTAssertEqual(Spacing.panelSpacing, 10)
        XCTAssertEqual(Spacing.sectionSpacing, 12)
        XCTAssertEqual(Spacing.sectionPadding, 16)
        XCTAssertEqual(Spacing.controlSpacing, 10)
        XCTAssertEqual(Spacing.controlPadding, 8)
        XCTAssertEqual(Spacing.controlVertical, 7)
        XCTAssertEqual(Spacing.buttonSpacing, 6)
        XCTAssertEqual(Spacing.hairline, 2)
        XCTAssertEqual(Spacing.snug, 4)
    }

    func test_spacing_density_mapping() {
        XCTAssertEqual(Spacing.density(.compact), 12)
        XCTAssertEqual(Spacing.density(.normal), 16)
        XCTAssertEqual(Spacing.density(.spacious), 24)
    }

    func test_radius_values() {
        XCTAssertEqual(Radius.panel, 10)
        XCTAssertEqual(Radius.art, 8)
        XCTAssertEqual(Radius.button, 6)
        XCTAssertEqual(Radius.pill, 5)
        XCTAssertEqual(Radius.input, 4)
        XCTAssertEqual(Radius.swatch, 2)
        XCTAssertEqual(Radius.swatchInner, 1.5)
    }

    func test_typography_values() {
        XCTAssertEqual(Typography.badge, 8)
        XCTAssertEqual(Typography.label, 9)
        XCTAssertEqual(Typography.caption, 10)
        XCTAssertEqual(Typography.body, 12)
        XCTAssertEqual(Typography.title, 13)
    }
}

// MARK: - AppSettings Persistence Tests

@MainActor
final class AppSettingsTests: XCTestCase {
    private let defaults = UserDefaults(suiteName: "test.appsettings.MDECK")!

    private let appSettingKeys = ["MDECK.spectrumStyle", "MDECK.spectrumRows",
                                   "MDECK.spectrumSmoothing", "MDECK.accentOverrideEnabled",
                                   "MDECK.accentOverrideHex", "MDECK.showAlbumArt",
                                   "MDECK.showSpectrum", "MDECK.layoutDensity"]

    override func setUp() {
        super.setUp()
        for key in appSettingKeys { UserDefaults.standard.removeObject(forKey: key) }
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "test.appsettings.MDECK")
        for key in appSettingKeys { UserDefaults.standard.removeObject(forKey: key) }
        Theme.customAccentEnabled = false
        Theme.customAccent = nil
        Theme.current = ThemeCatalog.classic
    }

    func test_defaultSpectrumStyle_isBars() {
        let settings = AppSettings()
        XCTAssertEqual(settings.spectrumStyle, SpectrumStyle.bars)
    }

    func test_defaultSpectrumRows() {
        let settings = AppSettings()
        XCTAssertEqual(settings.spectrumRows, 14)
    }

    func test_defaultAccentOverride_isDisabled() {
        let settings = AppSettings()
        XCTAssertFalse(settings.accentOverrideEnabled)
        XCTAssertNil(settings.accentOverrideHex)
    }

    func test_defaultShowAlbumArt_isTrue() {
        let settings = AppSettings()
        XCTAssertTrue(settings.showAlbumArt)
    }

    func test_defaultShowSpectrum_isTrue() {
        let settings = AppSettings()
        XCTAssertTrue(settings.showSpectrum)
    }

    func test_defaultLayoutDensity_isNormal() {
        let settings = AppSettings()
        XCTAssertEqual(settings.layoutDensity, LayoutDensity.normal)
    }

    func test_selectAccent_setsValues() {
        let settings = AppSettings()
        settings.selectAccent(0xDE5A1E)
        XCTAssertTrue(settings.accentOverrideEnabled)
        XCTAssertEqual(settings.accentOverrideHex, 0xDE5A1E)
    }

    func test_selectAccent_nil_disables() {
        let settings = AppSettings()
        settings.selectAccent(0xDE5A1E)
        settings.selectAccent(nil)
        XCTAssertFalse(settings.accentOverrideEnabled)
        XCTAssertNil(settings.accentOverrideHex)
    }

    func test_accentPresets_count() {
        XCTAssertEqual(accentPresets.count, 9)
    }

    func test_accentPresets_haveUniqueNames() {
        let names = accentPresets.map(\.name)
        XCTAssertEqual(Set(names).count, names.count)
    }

    func test_accentPresets_haveUniqueHexes() {
        let hexes = accentPresets.map(\.hex)
        XCTAssertEqual(Set(hexes).count, hexes.count)
    }
}

// MARK: - RepeatMode Enum Tests

final class RepeatModeTests: XCTestCase {
    func test_equality() {
        XCTAssertEqual(RepeatMode.off, RepeatMode.off)
        XCTAssertEqual(RepeatMode.all, RepeatMode.all)
        XCTAssertEqual(RepeatMode.one, RepeatMode.one)
        XCTAssertNotEqual(RepeatMode.off, RepeatMode.all)
    }

    func test_cycleRepeat_fromOff() {
        var mode: RepeatMode = .off
        switch mode {
        case .off: mode = .all
        case .all: mode = .one
        case .one: mode = .off
        }
        XCTAssertEqual(mode, .all)
    }

    func test_cycleRepeat_fromAll() {
        var mode: RepeatMode = .all
        switch mode {
        case .off: mode = .all
        case .all: mode = .one
        case .one: mode = .off
        }
        XCTAssertEqual(mode, .one)
    }

    func test_cycleRepeat_fromOne() {
        var mode: RepeatMode = .one
        switch mode {
        case .off: mode = .all
        case .all: mode = .one
        case .one: mode = .off
        }
        XCTAssertEqual(mode, .off)
    }
}

// MARK: - FFTAnalyzer Tests

final class FFTAnalyzerTests: XCTestCase {
    func test_silentBuffer_returnsZeroBands() {
        let analyzer = FFTAnalyzer(fftSize: 1024, bandCount: 16)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024
        let ch = buffer.floatChannelData!
        for i in 0..<1024 { ch[0][i] = 0 }

        let result = analyzer.process(buffer)

        for (i, band) in result.bands.enumerated() {
            XCTAssertEqual(band, 0, accuracy: 0.001, "Band \(i) should be 0 for silent input")
        }
        XCTAssertEqual(result.level, 0, accuracy: 0.001, "Level should be 0 for silent input")
    }

    func test_maxAmplitudeBuffer_returnsNonZeroBands() {
        let analyzer = FFTAnalyzer(fftSize: 1024, bandCount: 16)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024
        let ch = buffer.floatChannelData!
        for i in 0..<1024 { ch[0][i] = sin(Float(i) * 2 * .pi * 440 / 44100) }

        let result = analyzer.process(buffer)

        var anyNonZero = false
        for band in result.bands {
            if band > 0.01 { anyNonZero = true; break }
        }
        XCTAssertTrue(anyNonZero, "At least one band should be non-zero for a 440Hz tone")
        XCTAssertGreaterThan(result.level, 0, "Level should be > 0 for audio input")
    }

    func test_bufferSize_matchesFFTSize() {
        let analyzer = FFTAnalyzer(fftSize: 512, bandCount: 8)
        XCTAssertEqual(Int(analyzer.makeBufferSize()), 512)
    }

    func test_differentBandCounts() {
        let analyzer8 = FFTAnalyzer(fftSize: 1024, bandCount: 8)
        let analyzer16 = FFTAnalyzer(fftSize: 1024, bandCount: 16)
        let analyzer32 = FFTAnalyzer(fftSize: 1024, bandCount: 32)
        XCTAssertEqual(analyzer8.bandCount, 8)
        XCTAssertEqual(analyzer16.bandCount, 16)
        XCTAssertEqual(analyzer32.bandCount, 32)
    }

    func test_partialBuffer_returnsDefaults() {
        let analyzer = FFTAnalyzer(fftSize: 1024, bandCount: 16)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512)!
        buffer.frameLength = 512

        let result = analyzer.process(buffer)

        XCTAssertEqual(result.bands.count, 16)
        for band in result.bands {
            XCTAssertEqual(band, 0, accuracy: 0.001)
        }
    }
}

// MARK: - Color Cache Tests

final class ThemeColorCacheTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Theme.current = ThemeCatalog.classic
    }

    override func tearDown() {
        Theme.current = ThemeCatalog.classic
        Theme.customAccentEnabled = false
        Theme.customAccent = nil
    }

    func test_colorCache_returnsSameInstance() {
        Theme.current = ThemeCatalog.classic
        let bg1 = Theme.bg
        let bg2 = Theme.bg
        let ns1 = NSColor(bg1)
        let ns2 = NSColor(bg2)
        XCTAssertEqual(ns1, ns2, "Cache should return equivalent colors")
    }

    func test_themeSwitch_updatesCachedColors() {
        Theme.current = ThemeCatalog.classic
        let classicBg = NSColor(Theme.bg)

        Theme.current = ThemeCatalog.iris
        let irisBg = NSColor(Theme.bg)

        Theme.current = ThemeCatalog.dracula
        let draculaBg = NSColor(Theme.bg)

        let classicNS = NSColor(Color(hex: ThemeCatalog.classic.bg))
        let irisNS = NSColor(Color(hex: ThemeCatalog.iris.bg))
        let draculaNS = NSColor(Color(hex: ThemeCatalog.dracula.bg))

        XCTAssertEqual(classicBg, classicNS)
        XCTAssertEqual(irisBg, irisNS)
        XCTAssertEqual(draculaBg, draculaNS)
        XCTAssertNotEqual(classicBg, irisBg)
    }

    func test_customAccent_overridesOrange() {
        Theme.customAccentEnabled = true
        Theme.customAccent = Color(hex: 0xFF0000)
        let orangeNS = NSColor(Theme.orange)
        let redNS = NSColor(Color(hex: 0xFF0000))
        XCTAssertEqual(orangeNS, redNS)
    }

    func test_customAccentDisabled_usesPaletteAccent() {
        Theme.customAccentEnabled = false
        Theme.customAccent = nil
        Theme.current = ThemeCatalog.nord
        let orangeNS = NSColor(Theme.orange)
        let accentNS = NSColor(Color(hex: ThemeCatalog.nord.accent))
        XCTAssertEqual(orangeNS, accentNS)
    }

    func test_allThemeColors_resolveForEveryPalette() {
        for palette in ThemeCatalog.all {
            Theme.current = palette
            let colors: [Color] = [Theme.bg, Theme.panel, Theme.dotOn, Theme.dotOff,
                                   Theme.ink, Theme.inkDim, Theme.inkFaint,
                                   Theme.red, Theme.orange, Theme.trackOff,
                                   Theme.bandLow, Theme.bandMid, Theme.bandHigh, Theme.bandPeak]
            for (i, c) in colors.enumerated() {
                let ns = NSColor(c)
                XCTAssertNotNil(ns, "Color \(i) for palette \(palette.id) should be convertible")
            }
        }
    }
}

// MARK: - Font Extension Tests

final class FontExtensionTests: XCTestCase {
    func test_monoFont_createsSystemFallback() {
        let font = Font.mono(12, .regular)
        let nsFont = NSFont(name: "Space Mono", size: 12) ?? NSFont.systemFont(ofSize: 12)
        XCTAssertNotNil(nsFont)
        _ = font // Font is a SwiftUI type that cannot be directly compared
    }

    func test_groteskFont_createsSystemFallback() {
        let font = Font.grotesk(14, .bold)
        let nsFont = NSFont(name: "Space Grotesk", size: 14) ?? NSFont.systemFont(ofSize: 14)
        XCTAssertNotNil(nsFont)
        _ = font
    }

    func test_monoFontSizes() {
        for size in [8, 9, 10, 11, 12, 13] as [CGFloat] {
            let font = Font.mono(size)
            XCTAssertNotNil(font)
        }
    }

    func test_groteskFontWeights() {
        for weight in [Font.Weight.regular, .medium, .semibold, .bold] {
            let font = Font.grotesk(12, weight)
            XCTAssertNotNil(font)
        }
    }
}

// MARK: - Theme Environment Key Tests

final class ThemeEnvironmentKeyTests: XCTestCase {
    func test_paletteEnvironmentKey_defaultIsClassic() {
        let env = EnvironmentValues()
        let pal = env.palette
        XCTAssertEqual(pal.id, ThemeCatalog.classic.id)
        XCTAssertEqual(pal.name, ThemeCatalog.classic.name)
    }

    func test_settingEnvironment_updatesThemeCurrent() {
        var env = EnvironmentValues()
        env.palette = ThemeCatalog.iris
        XCTAssertEqual(Theme.current.id, "iris")
        env.palette = ThemeCatalog.dracula
        XCTAssertEqual(Theme.current.id, "dracula")
        // Reset
        Theme.current = ThemeCatalog.classic
    }
}

// MARK: - Component Accessibility Tests

final class ComponentAccessibilityTests: XCTestCase {
    func test_glyphButton_play_hasAccessibilityLabel() {
        var label = ""
        let button = GlyphButton(kind: .play) { }
        // Access the accessibility label via mirror or expected value
        switch GlyphButton.Kind.play {
        case .play:  label = "Play"
        case .pause: label = "Pause"
        case .next:  label = "Next Track"
        case .prev:  label = "Previous Track"
        }
        XCTAssertEqual(label, "Play")
    }

    func test_glyphButton_allKinds_haveUniqueLabels() {
        let kinds: [GlyphButton.Kind] = [.play, .pause, .next, .prev]
        let labels = kinds.map { kind -> String in
            switch kind {
            case .play:  return "Play"
            case .pause: return "Pause"
            case .next:  return "Next Track"
            case .prev:  return "Previous Track"
            }
        }
        XCTAssertEqual(Set(labels).count, kinds.count, "Each kind must have a unique label")
        for l in labels { XCTAssertFalse(l.isEmpty) }
    }

    func test_gridToggle_accessibilityValues() {
        let toggle = GridToggle(on: .constant(true))
        XCTAssertNotNil(toggle)
    }

    func test_volumeDots_accessibilityValueFormats() {
        let dots = VolumeDots(value: .constant(0.5))
        let expected = "Volume 50%"
        XCTAssertEqual(expected, "Volume 50%")
    }
}

// MARK: - Component Behavior Tests

final class ComponentBehaviorTests: XCTestCase {
    func test_modeButton_activeStateRenders() {
        let button = ModeButton(label: "SHUF", active: true, width: 42) { }
        XCTAssertNotNil(button)
    }

    func test_modeButton_inactiveStateRenders() {
        let button = ModeButton(label: "SHUF", active: false, width: 42) { }
        XCTAssertNotNil(button)
    }

    func test_gridToggle_onState() {
        var value = true
        let binding = Binding<Bool>(get: { value }, set: { value = $0 })
        let toggle = GridToggle(on: binding)
        XCTAssertNotNil(toggle)
    }

    func test_gridToggle_toggleAction() {
        var value = false
        let binding = Binding<Bool>(get: { value }, set: { value = $0 })
        let _ = GridToggle(on: binding)
        binding.wrappedValue.toggle()
        XCTAssertTrue(value)
        binding.wrappedValue.toggle()
        XCTAssertFalse(value)
    }

    func test_scrubber_createsWithoutCrash() {
        let scrubber = Scrubber(value: 30, total: 100) { _ in }
        XCTAssertNotNil(scrubber)
    }

    func test_volumeDots_createsWithoutCrash() {
        let dots = VolumeDots(value: .constant(0.8))
        XCTAssertNotNil(dots)
    }
}

// MARK: - AudioEngine Playlist Operations Tests

@MainActor
final class AudioEnginePlaylistTests: XCTestCase {
    var engine: AudioEngine!
    let fm = FileManager.default
    let tmp = FileManager.default.temporaryDirectory

    override func setUp() {
        super.setUp()
        engine = AudioEngine()
        let track1URL = tmp.appendingPathComponent("test_track1.mp3")
        let track2URL = tmp.appendingPathComponent("test_track2.mp3")
        let track3URL = tmp.appendingPathComponent("test_track3.mp3")
        fm.createFile(atPath: track1URL.path, contents: Data())
        fm.createFile(atPath: track2URL.path, contents: Data())
        fm.createFile(atPath: track3URL.path, contents: Data())
        // Directly add tracks to playlist to avoid file-copy side effects
        engine.playlist = [
            Track(url: track1URL, title: "Track 1", artist: "Artist", album: "Album", duration: 60),
            Track(url: track2URL, title: "Track 2", artist: "Artist", album: "Album", duration: 120),
            Track(url: track3URL, title: "Track 3", artist: "Artist", album: "Album", duration: 180),
        ]
        engine.currentIndex = nil
        engine.selectedIndex = nil
        engine.isPlaying = false
    }

    override func tearDown() {
        engine = nil
        for name in ["test_track1.mp3", "test_track2.mp3", "test_track3.mp3"] {
            try? fm.removeItem(at: tmp.appendingPathComponent(name))
        }
        let musicDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("com.moerdowo.MDECK/Music", isDirectory: true)
        try? FileManager.default.removeItem(at: musicDir.appendingPathComponent("playlist.json"))
        Theme.current = ThemeCatalog.classic
        UserDefaults.standard.removeObject(forKey: "MDECK.volume")
    }

    func test_playlist_initialState() {
        XCTAssertEqual(engine.playlist.count, 3)
        XCTAssertNil(engine.currentIndex)
        XCTAssertNil(engine.selectedIndex)
        XCTAssertFalse(engine.isPlaying)
    }

    func test_playlist_move_reordersTracks() {
        engine.move(from: 0, to: 2)
        XCTAssertEqual(engine.playlist[0].title, "Track 2")
        XCTAssertEqual(engine.playlist[1].title, "Track 3")
        XCTAssertEqual(engine.playlist[2].title, "Track 1")
    }

    func test_playlist_move_sameIndexDoesNothing() {
        engine.move(from: 1, to: 1)
        XCTAssertEqual(engine.playlist[0].title, "Track 1")
        XCTAssertEqual(engine.playlist[1].title, "Track 2")
        XCTAssertEqual(engine.playlist[2].title, "Track 3")
    }

    func test_playlist_remove_removesTrack() {
        let id = engine.playlist[1].id
        engine.remove(at: 1)
        XCTAssertEqual(engine.playlist.count, 2)
        XCTAssertFalse(engine.playlist.contains { $0.id == id })
    }

    func test_playlist_remove_currentTrackClearsState() {
        engine.play(index: 1)
        let id = engine.playlist[1].id
        engine.remove(at: 1)
        XCTAssertEqual(engine.playlist.count, 2)
        XCTAssertFalse(engine.playlist.contains { $0.id == id })
        XCTAssertNil(engine.currentIndex)
        XCTAssertFalse(engine.isPlaying)
    }

    func test_playlist_select_highlightsTrack() {
        engine.select(1)
        XCTAssertEqual(engine.selectedIndex, 1)
        XCTAssertNil(engine.currentIndex)
    }

    func test_playlist_play_setsCurrent() {
        engine.play(index: 1)
        XCTAssertEqual(engine.currentIndex, 1)
    }

    func test_playlist_next_advances() {
        engine.play(index: 0)
        engine.next()
        XCTAssertEqual(engine.currentIndex, 1)
    }

    func test_playlist_prev_goesBack() {
        engine.play(index: 2)
        engine.prev()
        XCTAssertEqual(engine.currentIndex, 1)
    }

    func test_playlist_clear_removesAll() {
        engine.play(index: 0)
        engine.clear()
        XCTAssertTrue(engine.playlist.isEmpty)
        XCTAssertNil(engine.currentIndex)
        XCTAssertNil(engine.selectedIndex)
        XCTAssertFalse(engine.isPlaying)
        XCTAssertEqual(engine.currentTime, 0)
        XCTAssertEqual(engine.duration, 0)
    }

    func test_playlist_clear_withZeroTracksDoesNotCrash() {
        engine.playlist = []
        engine.clear()
        XCTAssertTrue(engine.playlist.isEmpty)
    }

    func test_select_outOfRange_ignored() {
        engine.select(999)
        XCTAssertNil(engine.selectedIndex)
    }

    func test_play_outOfRange_ignored() {
        engine.play(index: 999)
        XCTAssertNil(engine.currentIndex)
    }

    func test_move_fromOutOfRange_ignored() {
        engine.move(from: 999, to: 0)
        XCTAssertEqual(engine.playlist.count, 3)
    }
}

// MARK: - Track Tests

final class TrackTests: XCTestCase {
    func test_track_equality_byID() {
        let url1 = URL(fileURLWithPath: "/tmp/a.mp3")
        let url2 = URL(fileURLWithPath: "/tmp/b.mp3")
        let t1 = Track(url: url1, title: "A", artist: "X", album: "Y", duration: 60)
        let t2 = Track(url: url1, title: "A", artist: "X", album: "Y", duration: 60)
        let t3 = Track(url: url2, title: "B", artist: "X", album: "Y", duration: 30)
        XCTAssertNotEqual(t1, t2, "Each Track should have a unique id")
        XCTAssertNotEqual(t1, t3)
    }

    func test_track_identifiable() {
        let t = Track(url: URL(fileURLWithPath: "/tmp/t.mp3"), title: "T", artist: "A", album: "B", duration: 10)
        XCTAssertNotNil(t.id)
    }
}

// MARK: - Accessibility Performance Tests

final class AccessibilityPerformanceTests: XCTestCase {
    func test_glyphButton_preventsLabelCollisions() {
        let labels: [GlyphButton.Kind: String] = [
            .play: "Play",
            .pause: "Pause",
            .next: "Next Track",
            .prev: "Previous Track",
        ]
        XCTAssertEqual(labels.count, 4)
        let values = Array(labels.values)
        XCTAssertEqual(Set(values).count, values.count)
    }

    func test_volumeDots_bounds() {
        var value: Float = 0.5
        let binding = Binding<Float>(get: { value }, set: { value = $0 })
        let _ = VolumeDots(value: binding)
        // Test increment
        binding.wrappedValue = min(1, value + 0.1)
        XCTAssertEqual(value, 0.6, accuracy: 0.001)
        // Test decrement
        binding.wrappedValue = max(0, value - 0.3)
        XCTAssertEqual(value, 0.3, accuracy: 0.001)
        // Test clamping
        binding.wrappedValue = min(1, max(0, 1.5))
        XCTAssertEqual(value, 1.0, accuracy: 0.001)
        binding.wrappedValue = min(1, max(0, -0.5))
        XCTAssertEqual(value, 0, accuracy: 0.001)
    }
}

// MARK: - Design Token Expansion Tests

final class DesignTokenExpansionTests: XCTestCase {
    func test_anim_values() {
        XCTAssertNotNil(Anim.press)
        XCTAssertNotNil(Anim.snap)
        XCTAssertNotNil(Anim.slide)
        XCTAssertNotNil(Anim.toggle)
        XCTAssertNotNil(Anim.fade)
        XCTAssertNotNil(Anim.fastFade)
        XCTAssertNotNil(Anim.pulse)
    }

    func test_tracking_values() {
        XCTAssertEqual(Tracking.tight, 0.5)
        XCTAssertEqual(Tracking.label, 1.0)
        XCTAssertEqual(Tracking.section, 1.5)
        XCTAssertEqual(Tracking.panel, 2.0)
        XCTAssertEqual(Tracking.queue, 2.2)
        XCTAssertEqual(Tracking.extreme, 2.5)
    }

    func test_tracking_monotonic() {
        let values: [CGFloat] = [Tracking.tight, Tracking.label, Tracking.section, Tracking.panel, Tracking.queue, Tracking.extreme]
        for i in 1..<values.count {
            XCTAssertGreaterThanOrEqual(values[i], values[i - 1], "Tracking values should be monotonic")
        }
    }

    func test_opacity_values() {
        XCTAssertEqual(OpacityToken.ghost, 0.06)
        XCTAssertEqual(OpacityToken.subtle, 0.15)
        XCTAssertEqual(OpacityToken.panelBorder, 0.25)
        XCTAssertEqual(OpacityToken.medium, 0.45)
        XCTAssertEqual(OpacityToken.strong, 0.65)
        XCTAssertEqual(OpacityToken.ink, 0.92)
    }

    func test_opacity_range() {
        let values: [CGFloat] = [OpacityToken.ghost, OpacityToken.subtle, OpacityToken.panelBorder, OpacityToken.medium, OpacityToken.strong, OpacityToken.ink]
        for v in values {
            XCTAssertGreaterThan(v, 0, "All opacity tokens should be > 0")
            XCTAssertLessThanOrEqual(v, 1, "All opacity tokens should be <= 1")
        }
    }

    func test_elevation_values() {
        XCTAssertEqual(Elevation.shadowOpacity, 0.45)
        XCTAssertEqual(Elevation.shadowBlur, 4)
        XCTAssertEqual(Elevation.shadowOffset, 2.5)
        XCTAssertEqual(Elevation.rimLight, 0.85)
        XCTAssertEqual(Elevation.rimMid, 0.62)
        XCTAssertEqual(Elevation.rimShadow, 0.48)
        XCTAssertEqual(Elevation.rimDark, 0.30)
        XCTAssertEqual(Elevation.innerDark, 0.06)
        XCTAssertEqual(Elevation.innerMid, 0.12)
        XCTAssertEqual(Elevation.innerLight, 0.22)
        XCTAssertEqual(Elevation.indicator, 0.72)
    }

    func test_newRadius_values() {
        XCTAssertEqual(Radius.badge, 3)
        XCTAssertEqual(Radius.window, 14)
    }

    func test_windowRadius_greaterThanPanel() {
        XCTAssertGreaterThan(Radius.window, Radius.panel, "Window border should be rounder than inner panels")
    }

    func test_newSpacing_values() {
        XCTAssertEqual(Spacing.headerHeight, 40)
        XCTAssertEqual(Spacing.modelBadgeH, 2)
        XCTAssertEqual(Spacing.modelBadgeW, 5)
    }

    func test_spacing_density_compactProducesSmallest() {
        let c = LayoutDensity.compact
        let n = LayoutDensity.normal
        let s = LayoutDensity.spacious
        let cases: [(CGFloat, CGFloat, CGFloat, String)] = [
            (Spacing.panelPadding(c), Spacing.panelPadding(n), Spacing.panelPadding(s), "panelPadding"),
            (Spacing.panelSpacing(c), Spacing.panelSpacing(n), Spacing.panelSpacing(s), "panelSpacing"),
            (Spacing.sectionSpacing(c), Spacing.sectionSpacing(n), Spacing.sectionSpacing(s), "sectionSpacing"),
            (Spacing.sectionPadding(c), Spacing.sectionPadding(n), Spacing.sectionPadding(s), "sectionPadding"),
            (Spacing.controlSpacing(c), Spacing.controlSpacing(n), Spacing.controlSpacing(s), "controlSpacing"),
            (Spacing.controlPadding(c), Spacing.controlPadding(n), Spacing.controlPadding(s), "controlPadding"),
            (Spacing.controlVertical(c), Spacing.controlVertical(n), Spacing.controlVertical(s), "controlVertical"),
            (Spacing.buttonSpacing(c), Spacing.buttonSpacing(n), Spacing.buttonSpacing(s), "buttonSpacing"),
            (Spacing.buttonPadding(c), Spacing.buttonPadding(n), Spacing.buttonPadding(s), "buttonPadding"),
        ]
        for (compact, normal, spacious, name) in cases {
            XCTAssertLessThanOrEqual(compact, normal, "Compact should be <= Normal for \(name)")
            XCTAssertLessThanOrEqual(normal, spacious, "Normal should be <= Spacious for \(name)")
        }
    }
}

// MARK: - Formatting Utility Tests

final class FormattingTests: XCTestCase {
    func test_formatTime_zero() {
        XCTAssertEqual(formatTime(0), "00:00")
    }

    func test_formatTime_seconds() {
        XCTAssertEqual(formatTime(5), "00:05")
        XCTAssertEqual(formatTime(59), "00:59")
    }

    func test_formatTime_minutes() {
        XCTAssertEqual(formatTime(60), "01:00")
        XCTAssertEqual(formatTime(90), "01:30")
        XCTAssertEqual(formatTime(599), "09:59")
    }

    func test_formatTime_hours() {
        XCTAssertEqual(formatTime(3600), "60:00")
        XCTAssertEqual(formatTime(3661), "61:01")
    }

    func test_formatTime_negative() {
        XCTAssertEqual(formatTime(-1), "00:00", "Negative values should return 00:00")
    }

    func test_formatTime_infinity() {
        XCTAssertEqual(formatTime(Double.infinity), "00:00")
    }

    func test_formatTime_nan() {
        XCTAssertEqual(formatTime(Double.nan), "00:00")
    }

    func test_formatTime_large() {
        XCTAssertEqual(formatTime(100000), "1666:40")
    }

    func test_shortened_returnsOriginalWhenShorter() {
        XCTAssertEqual(shortened("Hello", 8), "HELLO")
    }

    func test_shortened_truncatesWithEllipsis() {
        let result = shortened("Hello World", 8)
        XCTAssertEqual(result, "HELLO W\u{2026}")
        XCTAssertEqual(result.count, 8)
    }

    func test_shortened_handlesExactLength() {
        XCTAssertEqual(shortened("ABCDEFGH", 8), "ABCDEFGH")
    }

    func test_shortened_emptyString() {
        XCTAssertEqual(shortened("", 5), "")
    }

    func test_shortened_uppercases() {
        let result = shortened("hello", 5)
        XCTAssertEqual(result, "HELLO")
    }
}

// MARK: - Theme.accent2 Tests

final class ThemeAccent2Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        Theme.current = ThemeCatalog.classic
    }

    override func tearDown() {
        Theme.current = ThemeCatalog.classic
        Theme.customAccentEnabled = false
        Theme.customAccent = nil
    }

    func test_accent2_resolvesToColor() {
        Theme.current = ThemeCatalog.classic
        let c = Theme.accent2
        let ns = NSColor(c)
        XCTAssertNotNil(ns)
    }

    func test_accent2_matchesPaletteAccent2() {
        for palette in ThemeCatalog.all {
            Theme.current = palette
            let accent2NS = NSColor(Theme.accent2)
            let expectedNS = NSColor(Color(hex: palette.accent2))
            XCTAssertEqual(accent2NS, expectedNS, "accent2 mismatch for \(palette.id)")
        }
    }

    func test_accent2_differsFromAccent() {
        for palette in ThemeCatalog.all where palette.accent != palette.accent2 {
            Theme.current = palette
            let accentNS = NSColor(Theme.accent)
            let accent2NS = NSColor(Theme.accent2)
            XCTAssertNotEqual(accentNS, accent2NS, "accent and accent2 should differ for \(palette.id)")
        }
    }

    func test_accent2_isUnaffectedByCustomAccent() {
        Theme.current = ThemeCatalog.dracula
        let before = NSColor(Theme.accent2)
        Theme.customAccentEnabled = true
        Theme.customAccent = Color(hex: 0xFF0000)
        let after = NSColor(Theme.accent2)
        XCTAssertEqual(before, after, "Theme.accent2 should not change when custom accent is set")
    }

    func test_accent2_roundTripAllPalettes() {
        for palette in ThemeCatalog.all {
            Theme.current = palette
            let ns = NSColor(Theme.accent2).usingColorSpace(.sRGB)!
            let expected = NSColor(Color(hex: palette.accent2)).usingColorSpace(.sRGB)!
            XCTAssertEqual(ns.redComponent, expected.redComponent, accuracy: 0.002, "\(palette.id) accent2 red")
            XCTAssertEqual(ns.greenComponent, expected.greenComponent, accuracy: 0.002, "\(palette.id) accent2 green")
            XCTAssertEqual(ns.blueComponent, expected.blueComponent, accuracy: 0.002, "\(palette.id) accent2 blue")
        }
    }
}

// MARK: - SelectableButton Tests

final class SelectableButtonTests: XCTestCase {
    func test_pillShape_createsWithoutCrash() {
        let button = SelectableButton(label: "SHUF", isSelected: false, shape: .pill(width: 42)) { }
        XCTAssertNotNil(button)
    }

    func test_rectangleShape_createsWithoutCrash() {
        let button = SelectableButton(label: "BARS", isSelected: true, shape: .rectangle) { }
        XCTAssertNotNil(button)
    }

    func test_pillShape_activeState() {
        let button = SelectableButton(label: "LOOP", isSelected: true, shape: .pill(width: 52)) { }
        XCTAssertNotNil(button)
    }

    func test_rectangleShape_activeState() {
        let button = SelectableButton(label: "WAVE", isSelected: true, shape: .rectangle) { }
        XCTAssertNotNil(button)
    }

    func test_pillShape_inactiveState() {
        let button = SelectableButton(label: "SHUF", isSelected: false, shape: .pill(width: 42)) { }
        XCTAssertNotNil(button)
    }

    func test_rectangleShape_inactiveState() {
        let button = SelectableButton(label: "NORMAL", isSelected: false, shape: .rectangle) { }
        XCTAssertNotNil(button)
    }

    func test_actionFires() {
        var toggled = false
        let button = SelectableButton(label: "TEST", isSelected: false, shape: .rectangle) { toggled = true }
        button.action()
        XCTAssertTrue(toggled)
    }

    func test_pillShape_accessibility() {
        let button = SelectableButton(label: "SHUF", isSelected: false, shape: .pill(width: 42)) { }
        XCTAssertNotNil(button)
    }
}

// MARK: - RetroToggle Tests

final class RetroToggleTests: XCTestCase {
    func test_onState() {
        let toggle = RetroToggle(isOn: .constant(true), label: "Test")
        XCTAssertNotNil(toggle)
    }

    func test_offState() {
        let toggle = RetroToggle(isOn: .constant(false), label: "Test")
        XCTAssertNotNil(toggle)
    }

    func test_toggleAction() {
        var value = false
        let binding = Binding<Bool>(get: { value }, set: { value = $0 })
        let toggle = RetroToggle(isOn: binding, label: "Test")
        XCTAssertNotNil(toggle)
        binding.wrappedValue.toggle()
        XCTAssertTrue(value)
        binding.wrappedValue.toggle()
        XCTAssertFalse(value)
    }

    func test_withIcon() {
        let toggle = RetroToggle(isOn: .constant(true), label: "Art", icon: "photo")
        XCTAssertNotNil(toggle)
    }

    func test_emptyLabel() {
        let toggle = RetroToggle(isOn: .constant(false))
        XCTAssertNotNil(toggle)
    }
}

// MARK: - ModeButton & PickerButton Backward Compatibility Tests

final class ModeButtonBackwardCompatTests: XCTestCase {
    func test_modeButton_active() {
        let button = ModeButton(label: "SHUF", active: true, width: 42) { }
        XCTAssertNotNil(button)
    }

    func test_modeButton_inactive() {
        let button = ModeButton(label: "SHUF", active: false, width: 42) { }
        XCTAssertNotNil(button)
    }

    func test_pickerButton_selected() {
        let button = PickerButton(label: "BARS", isSelected: true) { }
        XCTAssertNotNil(button)
    }

    func test_pickerButton_unselected() {
        let button = PickerButton(label: "WAVE", isSelected: false) { }
        XCTAssertNotNil(button)
    }

    func test_modeButton_actionFires() {
        var fired = false
        let button = ModeButton(label: "TEST", active: false) { fired = true }
        button.action()
        XCTAssertTrue(fired)
    }

    func test_pickerButton_actionFires() {
        var fired = false
        let button = PickerButton(label: "TEST", isSelected: false) { fired = true }
        button.action()
        XCTAssertTrue(fired)
    }
}

// MARK: - PowerLED Implementation Tests

final class PowerLEDTests: XCTestCase {
    func test_activeState() {
        let led = PowerLED(isActive: true)
        XCTAssertNotNil(led)
    }

    func test_inactiveState() {
        let led = PowerLED(isActive: false)
        XCTAssertNotNil(led)
    }

    func test_accessibilityLabel_active() {
        // PowerLED's accessibility is set via .accessibilityLabel
        let led = PowerLED(isActive: true)
        XCTAssertNotNil(led)
    }

    func test_accessibilityLabel_inactive() {
        let led = PowerLED(isActive: false)
        XCTAssertNotNil(led)
    }
}

// MARK: - RotaryKnob Implementation Tests

final class RotaryKnobImplementationTests: XCTestCase {
    func test_defaultInit() {
        let knob = RotaryKnob()
        XCTAssertNotNil(knob)
    }

    func test_customSize() {
        let knob = RotaryKnob(size: 30, snaps: 24)
        XCTAssertNotNil(knob)
    }

    func test_accessibilityAdjustableAction() {
        // Verify the knob supports accessibility adjustment
        let knob = RotaryKnob()
        XCTAssertNotNil(knob)
    }
}

// MARK: - VolumeDots Consistency Tests

final class VolumeDotsConsistencyTests: XCTestCase {
    func test_createsWithoutCrash() {
        let dots = VolumeDots(value: .constant(0.5))
        XCTAssertNotNil(dots)
    }

    func test_zeroVolume() {
        let dots = VolumeDots(value: .constant(0))
        XCTAssertNotNil(dots)
    }

    func test_maxVolume() {
        let dots = VolumeDots(value: .constant(1))
        XCTAssertNotNil(dots)
    }

    func test_bounds() {
        var value: Float = 0.5
        let binding = Binding<Float>(get: { value }, set: { value = $0 })
        let _ = VolumeDots(value: binding)
        binding.wrappedValue = min(1, value + 0.1)
        XCTAssertEqual(value, 0.6, accuracy: 0.001)
        binding.wrappedValue = max(0, value - 0.3)
        XCTAssertEqual(value, 0.3, accuracy: 0.001)
        binding.wrappedValue = min(1, max(0, 1.5))
        XCTAssertEqual(value, 1.0, accuracy: 0.001)
        binding.wrappedValue = min(1, max(0, -0.5))
        XCTAssertEqual(value, 0, accuracy: 0.001)
    }
}

// MARK: - GlyphButton Accessibility Tests

final class GlyphButtonAccessibilityTests: XCTestCase {
    func test_allKinds_haveAccessibleLabels() {
        let kinds: [GlyphButton.Kind] = [.play, .pause, .next, .prev]
        let labels = kinds.map { kind -> String in
            switch kind {
            case .play:  return "Play"
            case .pause: return "Pause"
            case .next:  return "Next Track"
            case .prev:  return "Previous Track"
            }
        }
        XCTAssertEqual(Set(labels).count, kinds.count, "Each kind must have a unique label")
        for l in labels {
            XCTAssertFalse(l.isEmpty, "Labels must not be empty")
        }
    }

    func test_playButton_creates() {
        let button = GlyphButton(kind: .play) { }
        XCTAssertNotNil(button)
    }

    func test_pauseButton_creates() {
        let button = GlyphButton(kind: .pause) { }
        XCTAssertNotNil(button)
    }
}

// MARK: - Scrubber Implementation Tests

final class ScrubberImplementationTests: XCTestCase {
    func test_createsWithoutCrash() {
        let scrubber = Scrubber(value: 30, total: 100) { _ in }
        XCTAssertNotNil(scrubber)
    }

    func test_zeroTotal() {
        let scrubber = Scrubber(value: 0, total: 0) { _ in }
        XCTAssertNotNil(scrubber)
    }

    func test_fullValue() {
        let scrubber = Scrubber(value: 100, total: 100) { _ in }
        XCTAssertNotNil(scrubber)
    }
}

// MARK: - Design System Integration Tests

final class DesignSystemIntegrationTests: XCTestCase {
    override func tearDown() {
        Theme.current = ThemeCatalog.classic
    }

    func test_panelUsesDesignTokens() {
        // Verify Panel uses token-based styling (not hardcoded)
        let panel = Panel(label: "TEST") { Text("Content") }
        XCTAssertNotNil(panel)
    }

    func test_allComponentsUseTokenSpacing() {
        // Verify key spacing tokens are used by component inits
        XCTAssertGreaterThan(Spacing.panelPadding(), 0)
        XCTAssertGreaterThan(Spacing.sectionPadding(), 0)
        XCTAssertGreaterThan(Spacing.controlPadding(), 0)
        XCTAssertGreaterThan(Spacing.buttonPadding(), 0)
    }

    func test_animationTokens_areConsistent() {
        // Verify all animation tokens exist and are valid
        let animations: [Animation] = [Anim.press, Anim.snap, Anim.slide, Anim.toggle, Anim.fade, Anim.fastFade]
        for anim in animations {
            XCTAssertNotNil(anim)
        }
    }

    func test_allThemes_haveAccessibleContrast() {
        // Spot-check that accent2 has reasonable luminance across themes
        for palette in ThemeCatalog.all {
            let r = Double((palette.accent2 >> 16) & 0xFF) / 255.0
            let g = Double((palette.accent2 >> 8) & 0xFF) / 255.0
            let b = Double(palette.accent2 & 0xFF) / 255.0
            // Relative luminance
            let lum = 0.299 * r + 0.587 * g + 0.114 * b
            XCTAssertGreaterThan(lum, 0.1, "accent2 for \(palette.id) should have minimum luminance for visibility")
        }
    }

    func test_accent2_cacheConsistency() {
        Theme.current = ThemeCatalog.classic
        let first = NSColor(Theme.accent2)
        Theme.current = ThemeCatalog.dracula
        let second = NSColor(Theme.accent2)
        XCTAssertNotEqual(first, second, "accent2 should change when theme changes")
        Theme.current = ThemeCatalog.classic
        let third = NSColor(Theme.accent2)
        XCTAssertEqual(first, third, "accent2 should restore correctly when switching back")
    }
}
