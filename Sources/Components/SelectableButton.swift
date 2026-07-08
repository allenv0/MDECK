import SwiftUI

struct SelectableButton: View {
    enum Shape: Equatable {
        case pill(width: CGFloat = 40)
        case rectangle
    }

    let label: String
    let isSelected: Bool
    let shape: Shape
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            switch shape {
            case .pill(let width):
                Text(label)
                    .font(.mono(Typography.badge, .bold))
                    .tracking(Tracking.tight)
                    .foregroundStyle(isSelected ? Theme.dotOn : Theme.inkFaint)
                    .lineLimit(1).fixedSize()
                    .frame(width: width, height: 28)
                    .background(
                        (isSelected ? Theme.accent : Color.clear)
                            .opacity(isSelected ? OpacityToken.subtle : 0)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.pill, style: .continuous)
                            .stroke(isSelected ? Theme.accent : Theme.panelStroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.pill, style: .continuous))

            case .rectangle:
                Text(label)
                    .font(.mono(Typography.label, isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Theme.dotOn : Theme.inkDim)
                    .padding(.horizontal, Spacing.controlSpacing())
                    .padding(.vertical, Spacing.controlVertical())
                    .background(
                        (isSelected ? Theme.accent : Color.clear)
                            .opacity(isSelected ? OpacityToken.subtle : 0)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.input)
                            .stroke(isSelected ? Theme.accent : Theme.panelStroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.input))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
