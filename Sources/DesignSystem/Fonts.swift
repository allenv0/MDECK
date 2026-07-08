import SwiftUI

extension Font {
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        if NSFont(name: "Space Mono", size: size) != nil {
            return .custom("Space Mono", size: size)
        }
        return .system(size: size, weight: weight, design: .monospaced)
    }
    static func grotesk(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        if NSFont(name: "Space Grotesk", size: size) != nil {
            return .custom("Space Grotesk", size: size)
        }
        return .system(size: size, weight: weight, design: .default)
    }
}
