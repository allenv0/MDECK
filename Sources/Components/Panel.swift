import SwiftUI

struct Panel<Content: View>: View {
    var label: String? = nil
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.panelSpacing) {
            if let label {
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Theme.inkFaint.opacity(0.4))
                        .frame(width: 8, height: 1)
                    Text(label.uppercased())
                        .font(.mono(Typography.label, .regular))
                        .tracking(Tracking.extreme)
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            content
        }
        .padding(Spacing.panelPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                .fill(Theme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                .stroke(Color.white.opacity(OpacityToken.ghost), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                .offset(y: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
    }
}
