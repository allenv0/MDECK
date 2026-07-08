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
        let n = 3
        let gap: CGFloat = 1
        let cell = (13 - gap * CGFloat(n - 1)) / CGFloat(n)
        return VStack(spacing: gap) {
            ForEach(0..<n, id: \.self) { r in
                HStack(spacing: gap) {
                    ForEach(0..<n, id: \.self) { c in
                        let delay = Double(r + c) * 0.04
                        Rectangle()
                            .fill(Theme.dotOn)
                            .frame(width: cell, height: cell)
                            .scaleEffect(on ? 1 : 0, anchor: .center)
                            .animation(Anim.toggle.delay(delay), value: on)
                    }
                }
            }
        }
    }
}
