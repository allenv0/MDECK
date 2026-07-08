import SwiftUI

/// Wraps SelectableButton for backward compatibility.
/// Prefer using SelectableButton directly with `isSelected:`.
struct PickerButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectableButton(
            label: label,
            isSelected: isSelected,
            shape: .rectangle,
            action: action
        )
    }
}
