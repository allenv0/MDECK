import SwiftUI

struct MiniDiscView: View {
    let shutterReveal: CGFloat
    let isSpinning: Bool
    let discRotation: Double
    let trackTitle: String
    let trackArtist: String

    private let w: CGFloat = 176
    private let h: CGFloat = 164

    var body: some View {
        ZStack {
            shadow
            bodyBevel
            brushedBody
            edgeNotchLeft
            edgeNotchRight
            writeProtectTab
            labelArea
            discLayer
                .mask(
                    Circle()
                        .frame(width: 52, height: 52)
                        .offset(x: (1 - shutterReveal) * 30)
                )
            shutterLayer
            shutterRailTop
            shutterRailBot
            directionArrow
        }
        .frame(width: w, height: h)
    }

    // MARK: - Shadow

    private var shadow: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.black.opacity(0.4))
            .frame(width: w + 6, height: h + 6)
            .offset(y: 6)
            .blur(radius: 12)
    }

    // MARK: - Bevel

    private var bodyBevel: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.08),
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.4),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
    }

    // MARK: - Brushed Body

    private var brushedBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.78),
                            Color(white: 0.72),
                            Color(white: 0.64),
                            Color(white: 0.60),
                            Color(white: 0.56),
                            Color(white: 0.62),
                            Color(white: 0.52),
                            Color(white: 0.48),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Brushed metal grain
            ForEach(0..<40) { i in
                let y = CGFloat(i) * (h / 40) - h / 2
                Rectangle()
                    .fill(Color.white.opacity(i % 3 == 0 ? 0.04 : (i % 3 == 1 ? 0.02 : 0)))
                    .frame(width: w - 10, height: 0.5)
                    .offset(y: y)
            }

            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.08),
                            Color.black.opacity(0.2),
                            Color.black.opacity(0.3),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
    }

    // MARK: - Edge Notches

    private var edgeNotchLeft: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.2))
                .frame(width: 4, height: 6)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 6)
                        .offset(x: -1),
                    alignment: .leading
                )
            Spacer()
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.2))
                .frame(width: 4, height: 6)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 6)
                        .offset(x: -1),
                    alignment: .leading
                )
        }
        .frame(height: 60)
        .offset(x: -w / 2 + 1, y: 8)
    }

    private var edgeNotchRight: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.2))
                .frame(width: 4, height: 6)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 6)
                        .offset(x: 1),
                    alignment: .trailing
                )
            Spacer()
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.2))
                .frame(width: 4, height: 6)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 6)
                        .offset(x: 1),
                    alignment: .trailing
                )
        }
        .frame(height: 60)
        .offset(x: w / 2 - 1, y: 8)
    }

    // MARK: - Write-Protect Tab

    private var writeProtectTab: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.55), Color(white: 0.45), Color(white: 0.40)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 8, height: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
            )
            .offset(x: w / 2 - 14, y: -h / 2 + 10)
    }

    // MARK: - Label

    private var labelArea: some View {
        VStack(spacing: 0) {
            // Outer decorative border
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                .frame(width: w - 20, height: 54)

            // Label content
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Text("MD")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(Color(white: 0.12))
                    Spacer()
                    Text("MDECK")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .tracking(2.5)
                        .foregroundColor(Color(white: 0.3))
                }
                .padding(.horizontal, 16)
                .padding(.top, 5)

                // Decorative divider
                Rectangle()
                    .fill(Color(white: 0.7))
                    .frame(width: w - 44, height: 0.5)
                    .padding(.top, 2)

                Text(trackTitle.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(white: 0.12))
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                Text(trackArtist.uppercased())
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(white: 0.35))
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    .padding(.top, 1)
            }
            .frame(width: w - 22, height: 52)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(white: 0.94),
                                    Color(white: 0.90),
                                    Color(white: 0.87),
                                    Color(white: 0.84),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.black.opacity(0.06),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 1.5, x: 0, y: 1)
        }
        .offset(y: -40)
    }

    // MARK: - Disc

    private var discLayer: some View {
        ZStack {
            // Rainbow sheen base
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(red: 0.3, green: 0.3, blue: 0.5).opacity(0.3),
                            Color(red: 0.2, green: 0.4, blue: 0.3).opacity(0.2),
                            Color(red: 0.4, green: 0.2, blue: 0.4).opacity(0.3),
                            Color(red: 0.3, green: 0.3, blue: 0.5).opacity(0.3),
                        ],
                        center: .center
                    )
                )
                .frame(width: 52, height: 52)

            // Disc surface
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(white: 0.28),
                            Color(white: 0.15),
                            Color(white: 0.10),
                            Color(white: 0.06),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 26
                    )
                )
                .frame(width: 52, height: 52)

            // Data tracks (concentric rings)
            ForEach([50, 46, 42, 38, 34, 30, 26, 22, 18], id: \.self) { r in
                Circle()
                    .stroke(Color.white.opacity(0.03), lineWidth: 0.5)
                    .frame(width: CGFloat(r), height: CGFloat(r))
            }
            ForEach([48, 44, 40, 36, 32, 28, 24, 20], id: \.self) { r in
                Circle()
                    .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                    .frame(width: CGFloat(r), height: CGFloat(r))
            }

            // Rim highlight
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .frame(width: 50, height: 50)

            // Clamp ring
            Circle()
                .fill(Color(white: 0.4))
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color(white: 0.3),
                                    Color.black.opacity(0.3),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )

            // Inner clamp detail
            Circle()
                .fill(Color(white: 0.55))
                .frame(width: 10, height: 10)

            // Spindle hole
            Circle()
                .fill(Color(white: 0.08))
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        }
        .rotationEffect(.degrees(discRotation))
        .offset(y: 24)
    }

    // MARK: - Shutter (bottom portion with metallic finish and window)

    private var shutterLayer: some View {
        let sx = (w - 12) / 2 + (1 - shutterReveal) * 30
        let sy: CGFloat = 38
        return ZStack {
            ShutterShape(holeX: sx, holeY: sy)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.88),
                            Color(white: 0.80),
                            Color(white: 0.72),
                            Color(white: 0.84),
                            Color(white: 0.68),
                            Color(white: 0.78),
                            Color(white: 0.58),
                            Color(white: 0.70),
                            Color(white: 0.52),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: FillStyle(eoFill: true)
                )

            // Shutter horizontal brush lines
            ForEach(0..<18) { i in
                let y = CGFloat(i) * (68 / 18) - 34
                Rectangle()
                    .fill(Color.white.opacity(i % 2 == 0 ? 0.04 : 0))
                    .frame(width: w - 14, height: 0.5)
                    .offset(y: y)
            }

            ShutterShape(holeX: sx, holeY: sy)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.1),
                            Color.black.opacity(0.15),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .frame(width: w - 12, height: 68)
        .offset(y: 22)
    }

    // MARK: - Shutter Rails

    private var shutterRailTop: some View {
        Rectangle()
            .fill(Color(white: 0.35))
            .frame(width: w - 16, height: 1.5)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 0.5),
                alignment: .top
            )
            .offset(y: -11)
    }

    private var shutterRailBot: some View {
        Rectangle()
            .fill(Color(white: 0.35))
            .frame(width: w - 16, height: 1.5)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 0.5),
                alignment: .top
            )
            .offset(y: 57)
    }

    // MARK: - Direction Arrow

    private var directionArrow: some View {
        Image(systemName: "arrowtriangle.right.fill")
            .font(.system(size: 9))
            .foregroundColor(Color(white: 0.35))
            .offset(x: w / 2 - 16, y: 58)
    }
}

// MARK: - Shutter Shape (rect with circular hole)

struct ShutterShape: Shape {
    let holeX: CGFloat
    let holeY: CGFloat

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addRoundedRect(in: rect, cornerSize: CGSize(width: 5, height: 5))
            p.addEllipse(in: CGRect(
                x: holeX - 26, y: holeY - 26, width: 52, height: 52
            ))
        }
    }
}
