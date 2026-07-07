import SwiftUI

struct Scrubber: View {
    let value: Double
    let total: Double
    let onSeek: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let frac = total > 0 ? CGFloat(min(1, max(0, value / total))) : 0
            let dots = max(1, Int(w / 9))
            Canvas { ctx, size in
                let lit = Int(CGFloat(dots) * frac)
                for i in 0..<dots {
                    let x = (CGFloat(i) + 0.5) * (size.width / CGFloat(dots))
                    let on = i <= lit
                    let d: CGFloat = on ? 5 : 3.5
                    ctx.fill(Path(ellipseIn: CGRect(x: x - d/2, y: size.height/2 - d/2, width: d, height: d)),
                             with: .color(on ? Theme.dotOn : Theme.dotOff))
                }
            }
            .accessibilityLabel("Seek")
            .accessibilityValue(Text("\(Int(value)) of \(Int(total)) seconds"))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                let f = min(1, max(0, g.location.x / w))
                onSeek(Double(f) * total)
            })
        }
    }
}
