import SwiftUI

struct RetroToggle: View {
    @Binding var isOn: Bool
    var label: String = ""
    var icon: String = ""

    var body: some View {
        Button {
            withAnimation(Anim.toggle) { isOn.toggle() }
        } label: {
            HStack(spacing: Spacing.controlSpacing) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                        .frame(width: 18)
                }
                if !label.isEmpty {
                    Text(label.uppercased())
                        .font(.mono(Typography.caption))
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Radius.pill, style: .continuous)
                        .fill(isOn ? Theme.accent : Theme.trackOff)
                        .frame(width: 28, height: 14)
                    Circle()
                        .fill(Theme.dotOn)
                        .frame(width: 10, height: 10)
                        .padding(2)
                        .offset(x: isOn ? 14 : 0)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
