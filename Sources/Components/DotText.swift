import SwiftUI

enum DotFont {
    static let w = 5, h = 7
    private static let glyphs: [Character: [String]] = [
        "0": ["01110","10001","10011","10101","11001","10001","01110"],
        "1": ["00100","01100","00100","00100","00100","00100","01110"],
        "2": ["01110","10001","00001","00010","00100","01000","11111"],
        "3": ["11111","00010","00100","00010","00001","10001","01110"],
        "4": ["00010","00110","01010","10010","11111","00010","00010"],
        "5": ["11111","10000","11110","00001","00001","10001","01110"],
        "6": ["00110","01000","10000","11110","10001","10001","01110"],
        "7": ["11111","00001","00010","00100","01000","01000","01000"],
        "8": ["01110","10001","10001","01110","10001","10001","01110"],
        "9": ["01110","10001","10001","01111","00001","00010","01100"],
        "A": ["01110","10001","10001","11111","10001","10001","10001"],
        "B": ["11110","10001","10001","11110","10001","10001","11110"],
        "C": ["01110","10001","10000","10000","10000","10001","01110"],
        "D": ["11100","10010","10001","10001","10001","10010","11100"],
        "E": ["11111","10000","10000","11110","10000","10000","11111"],
        "F": ["11111","10000","10000","11110","10000","10000","10000"],
        "G": ["01110","10001","10000","10111","10001","10001","01111"],
        "H": ["10001","10001","10001","11111","10001","10001","10001"],
        "I": ["01110","00100","00100","00100","00100","00100","01110"],
        "J": ["00111","00010","00010","00010","00010","10010","01100"],
        "K": ["10001","10010","10100","11000","10100","10010","10001"],
        "L": ["10000","10000","10000","10000","10000","10000","11111"],
        "M": ["10001","11011","10101","10101","10001","10001","10001"],
        "N": ["10001","10001","11001","10101","10011","10001","10001"],
        "O": ["01110","10001","10001","10001","10001","10001","01110"],
        "P": ["11110","10001","10001","11110","10000","10000","10000"],
        "Q": ["01110","10001","10001","10001","10101","10010","01101"],
        "R": ["11110","10001","10001","11110","10100","10010","10001"],
        "S": ["01111","10000","10000","01110","00001","00001","11110"],
        "T": ["11111","00100","00100","00100","00100","00100","00100"],
        "U": ["10001","10001","10001","10001","10001","10001","01110"],
        "V": ["10001","10001","10001","10001","10001","01010","00100"],
        "W": ["10001","10001","10001","10101","10101","11011","10001"],
        "X": ["10001","10001","01010","00100","01010","10001","10001"],
        "Y": ["10001","10001","01010","00100","00100","00100","00100"],
        "Z": ["11111","00001","00010","00100","01000","10000","11111"],
        " ": ["00000","00000","00000","00000","00000","00000","00000"],
        ":": ["00000","00100","00100","00000","00100","00100","00000"],
        "-": ["00000","00000","00000","11111","00000","00000","00000"],
        ".": ["00000","00000","00000","00000","00000","00100","00100"],
        ",": ["00000","00000","00000","00000","00100","00100","01000"],
        "/": ["00001","00001","00010","00100","01000","10000","10000"],
        "'": ["00100","00100","01000","00000","00000","00000","00000"],
        "?": ["01110","10001","00001","00110","00100","00000","00100"],
        "!": ["00100","00100","00100","00100","00100","00000","00100"],
        "(": ["00010","00100","01000","01000","01000","00100","00010"],
        ")": ["01000","00100","00010","00010","00010","00100","01000"],
        "+": ["00000","00100","00100","11111","00100","00100","00000"],
        "#": ["01010","01010","11111","01010","11111","01010","01010"],
        "&": ["01100","10010","10100","01000","10101","10010","01101"],
        "%": ["11001","11010","00100","01000","01011","10011","00000"],
        ">": ["00000","00100","00010","11111","00010","00100","00000"],
        "▶": ["00000","00100","00110","00111","00110","00100","00000"],
    ]

    static func rows(for ch: Character) -> [String] {
        glyphs[Character(ch.uppercased())] ?? glyphs["?"]!
    }
}

struct DotText: View {
    let text: String
    var dot: CGFloat = 4
    var gap: CGFloat = 2
    var spacing: CGFloat = 5
    var color: Color = Theme.dotOn
    var ghost: Bool = true

    private var cell: CGFloat { dot + gap }
    private var charWidth: CGFloat { CGFloat(DotFont.w) * cell }
    private var glyphGap: CGFloat { gap + spacing }

    private var totalWidth: CGFloat {
        guard !text.isEmpty else { return 0 }
        return CGFloat(text.count) * charWidth + CGFloat(text.count - 1) * glyphGap
    }
    private var totalHeight: CGFloat { CGFloat(DotFont.h) * cell }

    static func width(_ text: String, dot: CGFloat, gap: CGFloat, spacing: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let cell = dot + gap
        let charWidth = CGFloat(DotFont.w) * cell
        let glyphGap = gap + spacing
        return CGFloat(text.count) * charWidth + CGFloat(text.count - 1) * glyphGap
    }
    static func height(dot: CGFloat, gap: CGFloat) -> CGFloat { CGFloat(DotFont.h) * (dot + gap) }

    var body: some View {
        Canvas { ctx, _ in
            var x: CGFloat = 0
            for ch in text {
                let rows = DotFont.rows(for: ch)
                for (r, row) in rows.enumerated() {
                    for (c, bit) in row.enumerated() {
                        let on = (bit == "1")
                        if !on && !ghost { continue }
                        let rect = CGRect(x: x + CGFloat(c) * cell,
                                          y: CGFloat(r) * cell,
                                          width: dot, height: dot)
                        ctx.fill(Path(ellipseIn: rect),
                                 with: .color(on ? color : Theme.dotOff))
                    }
                }
                x += charWidth + glyphGap
            }
        }
        .frame(width: totalWidth, height: totalHeight)
        .accessibilityLabel(text)
    }
}

struct MarqueeDotText: View {
    let text: String
    var dot: CGFloat = 4
    var gap: CGFloat = 2
    var spacing: CGFloat = 5
    var color: Color = Theme.dotOn
    var speed: CGFloat = 36
    var ghost: Bool = false

    private var contentW: CGFloat { DotText.width(text, dot: dot, gap: gap, spacing: spacing) }
    private var h: CGFloat { DotText.height(dot: dot, gap: gap) }
    private var glyph: some View { DotText(text: text, dot: dot, gap: gap, spacing: spacing, color: color, ghost: ghost) }

    var body: some View {
        GeometryReader { geo in
            let avail = geo.size.width
            let gapBetween = max(40, avail * 0.35)
            let period = max(0.5, Double((contentW + gapBetween) / speed))
            Group {
                if contentW <= avail {
                    glyph
                } else {
                    TimelineView(.animation) { tl in
                        let t = tl.date.timeIntervalSinceReferenceDate
                        let phase = t.truncatingRemainder(dividingBy: period) / period
                        let x = -CGFloat(phase) * (contentW + gapBetween)
                        HStack(spacing: gapBetween) {
                            glyph
                            glyph
                        }
                        .offset(x: x)
                    }
                    .frame(width: avail, alignment: .leading)
                    .clipped()
                }
            }
            .frame(width: avail, height: h, alignment: .leading)
        }
        .frame(height: h)
    }
}
