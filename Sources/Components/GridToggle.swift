import SwiftUI

struct GridToggle: View {
    @Binding var on: Bool

    var body: some View {
        Button {
            withAnimation(Anim.toggle) { on.toggle() }
        } label: {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Radius.pill, style: .continuous)
                    .fill(on ? Theme.accent : Theme.trackOff)
                pixelKnob
                    .frame(width: 13, height: 13)
                    .offset(x: on ? 36 - 13 - 2 : 2)
            }
            .frame(width: 36, height: 17)
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
                             with: .color(Theme.dotOn))
                }
            }
        }
    }
}
