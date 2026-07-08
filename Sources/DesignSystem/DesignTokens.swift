import SwiftUI

enum Spacing {
    // Base unit
    static let grid: CGFloat = 16

    // Panels — function of density
    static func panelPadding(_ density: LayoutDensity = .normal) -> CGFloat {
        switch density {
        case .compact:  return 10
        case .normal:   return 14
        case .spacious: return 18
        }
    }
    static var panelPadding: CGFloat { panelPadding() }
    static func panelSpacing(_ density: LayoutDensity = .normal) -> CGFloat {
        switch density {
        case .compact:  return 8
        case .normal:   return 10
        case .spacious: return 14
        }
    }
    static var panelSpacing: CGFloat { panelSpacing() }
    static let panelLabelPadding: CGFloat = 4

    // Sections
    static func sectionSpacing(_ density: LayoutDensity = .normal) -> CGFloat {
        switch density {
        case .compact:  return 8
        case .normal:   return 12
        case .spacious: return 16
        }
    }
    static var sectionSpacing: CGFloat { sectionSpacing() }
    static func sectionPadding(_ density: LayoutDensity = .normal) -> CGFloat {
        switch density {
        case .compact:  return 12
        case .normal:   return 16
        case .spacious: return 20
        }
    }
    static var sectionPadding: CGFloat { sectionPadding() }

    // Controls
    static func controlSpacing(_ density: LayoutDensity = .normal) -> CGFloat {
        switch density {
        case .compact:  return 6
        case .normal:   return 10
        case .spacious: return 14
        }
    }
    static var controlSpacing: CGFloat { controlSpacing() }
    static func controlPadding(_ density: LayoutDensity = .normal) -> CGFloat {
        switch density {
        case .compact:  return 6
        case .normal:   return 8
        case .spacious: return 10
        }
    }
    static var controlPadding: CGFloat { controlPadding() }
    static func controlVertical(_ density: LayoutDensity = .normal) -> CGFloat {
        switch density {
        case .compact:  return 5
        case .normal:   return 7
        case .spacious: return 10
        }
    }
    static var controlVertical: CGFloat { controlVertical() }

    // Buttons
    static func buttonSpacing(_ density: LayoutDensity = .normal) -> CGFloat {
        switch density {
        case .compact:  return 4
        case .normal:   return 6
        case .spacious: return 8
        }
    }
    static var buttonSpacing: CGFloat { buttonSpacing() }
    static func buttonPadding(_ density: LayoutDensity = .normal) -> CGFloat {
        switch density {
        case .compact:  return 4
        case .normal:   return 6
        case .spacious: return 8
        }
    }
    static var buttonPadding: CGFloat { buttonPadding() }

    // Layout density mapping (top-level gutter)
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
