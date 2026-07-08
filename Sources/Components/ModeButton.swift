import SwiftUI

/// Wraps SelectableButton for backward compatibility.
/// Prefer using SelectableButton directly with `isSelected:`.
struct ModeButton: View {
    let label: String
    let active: Bool
    var width: CGFloat = 40
    let action: () -> Void

    var body: some View {
        SelectableButton(
            label: label,
            isSelected: active,
            shape: .pill(width: width),
            action: action
        )
    }
}
