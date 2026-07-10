import SwiftUI

// MARK: - Spacing

enum Spacing {
    static let grid: CGFloat = 16

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

    static func density(_ density: LayoutDensity) -> CGFloat {
        switch density {
        case .compact:  return 12
        case .normal:   return 16
        case .spacious: return 24
        }
    }

    static let hairline: CGFloat = 2
    static let snug: CGFloat = 4

    static let headerHeight: CGFloat = 40
    static let modelBadgeH: CGFloat = 2
    static let modelBadgeW: CGFloat = 5
}

// MARK: - Corner Radius

enum Radius {
    static let panel: CGFloat = 10
    static let art: CGFloat = 8
    static let button: CGFloat = 6
    static let pill: CGFloat = 5
    static let input: CGFloat = 4
    static let swatch: CGFloat = 2
    static let swatchInner: CGFloat = 1.5
    static let badge: CGFloat = 3
    static let window: CGFloat = 14
}

// MARK: - Typography Sizes

enum Typography {
    static let badge: CGFloat = 8
    static let label: CGFloat = 9
    static let caption: CGFloat = 10
    static let body: CGFloat = 12
    static let title: CGFloat = 13
}

// MARK: - Animation Tokens

enum Anim {
    static let press = Animation.spring(response: 0.18, dampingFraction: 0.45)
    static let snap = Animation.spring(response: 0.25, dampingFraction: 0.6)
    static let slide = Animation.spring(response: 0.32, dampingFraction: 0.82)
    static let toggle = Animation.easeInOut(duration: 0.28)
    static let fade = Animation.easeInOut(duration: 0.15)
    static let fastFade = Animation.easeInOut(duration: 0.1)
    static let pulse = Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
    static let theme = Animation.easeInOut(duration: 0.4)
    static let mdDoor = Animation.spring(response: 0.45, dampingFraction: 0.45)
    static let mdInsert = Animation.spring(response: 0.80, dampingFraction: 0.72)
    static let mdShutter = Animation.spring(response: 0.63, dampingFraction: 0.68)
    static let mdSpin = Animation.linear(duration: 0.80)
}

// MARK: - Letter-Spacing Tokens

enum Tracking {
    static let tight: CGFloat = 0.5
    static let label: CGFloat = 1.0
    static let section: CGFloat = 1.5
    static let panel: CGFloat = 2.0
    static let queue: CGFloat = 2.2
    static let extreme: CGFloat = 2.5
}

// MARK: - Opacity Tokens

enum OpacityToken {
    static let ghost: CGFloat = 0.06
    static let panelBorder: CGFloat = 0.25
    static let subtle: CGFloat = 0.15
    static let medium: CGFloat = 0.45
    static let strong: CGFloat = 0.65
    static let ink: CGFloat = 0.92
}

// MARK: - Surface Elevation Tokens

enum Elevation {
    static let shadowOpacity: CGFloat = 0.45
    static let shadowBlur: CGFloat = 4
    static let shadowOffset: CGFloat = 2.5
    static let rimLight: CGFloat = 0.85
    static let rimMid: CGFloat = 0.62
    static let rimShadow: CGFloat = 0.48
    static let rimDark: CGFloat = 0.30
    static let innerDark: CGFloat = 0.06
    static let innerMid: CGFloat = 0.12
    static let innerLight: CGFloat = 0.22
    static let indicator: CGFloat = 0.72
}
