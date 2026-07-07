import SwiftUI

enum Spacing {
    // Base unit
    static let grid: CGFloat = 16

    // Panels
    static let panelPadding: CGFloat = 14
    static let panelSpacing: CGFloat = 10
    static let panelLabelPadding: CGFloat = 4

    // Sections
    static let sectionSpacing: CGFloat = 12
    static let sectionPadding: CGFloat = 16

    // Controls
    static let controlSpacing: CGFloat = 10
    static let controlPadding: CGFloat = 8
    static let controlVertical: CGFloat = 7

    // Buttons
    static let buttonSpacing: CGFloat = 6
    static let buttonPadding: CGFloat = 6

    // Layout density mapping
    static func density(_ density: LayoutDensity) -> CGFloat {
        switch density {
        case .compact:  return 12
        case .normal:   return 16
        case .spacious: return 24
        }
    }

    // Tiny
    static let hairline: CGFloat = 2
    static let snug: CGFloat = 4
}

enum Radius {
    static let panel: CGFloat = 10
    static let art: CGFloat = 8
    static let button: CGFloat = 6
    static let pill: CGFloat = 5
    static let input: CGFloat = 4
    static let swatch: CGFloat = 2
    static let swatchInner: CGFloat = 1.5
}

enum Typography {
    static let badge: CGFloat = 8
    static let label: CGFloat = 9
    static let caption: CGFloat = 10
    static let body: CGFloat = 12
    static let title: CGFloat = 13
}
