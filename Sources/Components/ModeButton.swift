import SwiftUI

struct ModeButton: View {
    let label: String
    let active: Bool
    var width: CGFloat = 40
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.mono(Typography.badge, .bold)).tracking(0.5)
                .foregroundStyle(active ? .white : Theme.inkFaint)
                .lineLimit(1).fixedSize()
                .frame(width: width, height: 28)
                .background((active ? Theme.accent : Color.clear).opacity(active ? 0.18 : 0))
                .overlay(RoundedRectangle(cornerRadius: Radius.pill, style: .continuous)
                    .stroke(active ? Theme.accent : Theme.panelStroke, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: Radius.pill, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) mode")
        .accessibilityValue(active ? "On" : "Off")
    }
}
