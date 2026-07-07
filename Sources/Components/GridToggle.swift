import SwiftUI

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
                    .fill(on ? Theme.orange : Theme.trackOff)
                pixelKnob
                    .frame(width: thumb, height: thumb)
                    .offset(x: on ? trackW - thumb - 2 : 2)
            }
            .frame(width: trackW, height: trackH)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Playlist Queue")
        .accessibilityValue(on ? "Visible" : "Hidden")
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
