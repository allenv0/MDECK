import SwiftUI

struct PickerButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.mono(Typography.label, isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? Theme.dotOn : Theme.inkDim)
                .padding(.horizontal, Spacing.controlSpacing())
                .padding(.vertical, 5)
                .background(isSelected ? Theme.accent.opacity(0.15) : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: Radius.input)
                    .stroke(isSelected ? Theme.accent : Theme.panelStroke, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: Radius.input))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
