import Foundation

func formatTime(_ t: Double) -> String {
    guard t.isFinite, t >= 0 else { return "00:00" }
    let s = Int(t)
    return String(format: "%02d:%02d", s / 60, s % 60)
}

func shortened(_ s: String, _ n: Int) -> String {
    let up = s.uppercased()
    return up.count <= n ? up : String(up.prefix(n - 1)) + "\u{2026}"
}
