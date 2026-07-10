import SwiftUI
import AVFoundation

struct MDInsertAnimation: View {
    let triggerID: Int
    let trackTitle: String
    let trackArtist: String
    let onFinish: () -> Void

    @State private var mdOffset: CGFloat = 320
    @State private var doorAngle: Double = 0
    @State private var shutterReveal: CGFloat = 0
    @State private var discRotation: Double = 0
    @State private var contentOpacity: CGFloat = 0
    @State private var isSpinning = false

    private let slotW: CGFloat = 230
    private let slotH: CGFloat = 218

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / slotW, geo.size.height / slotH)
            slotBezel
                .scaleEffect(scale)
                .frame(width: slotW * scale, height: slotH * scale)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .opacity(Double(contentOpacity))
        }
        .onAppear(perform: runSequence)
    }

    // MARK: - Slot Bezel

    private var slotBezel: some View {
        ZStack {
            outerBezel
            innerRecess
            ledIndicator
            MiniDiscView(
                shutterReveal: shutterReveal,
                isSpinning: isSpinning,
                discRotation: discRotation,
                trackTitle: trackTitle,
                trackArtist: trackArtist
            )
            .offset(x: mdOffset, y: 0)
            slotDoor
            bezelScrews
            bezelLabel
            rimHighlight
        }
        .frame(width: slotW, height: slotH)
    }

    // MARK: - Bezel Components

    private var outerBezel: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.80),
                        Color(white: 0.70),
                        Color(white: 0.60),
                        Color(white: 0.68),
                        Color(white: 0.56),
                        Color(white: 0.52),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.15),
                                Color.black.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }

    private var innerRecess: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(white: 0.05))
            .frame(width: slotW - 28, height: slotH - 28)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.6), lineWidth: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    .offset(y: -1)
            )
    }

    private var rimHighlight: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.25),
                        Color.clear,
                        Color.clear,
                        Color.black.opacity(0.15),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
    }

    private var bezelScrews: some View {
        ZStack {
            screwDot.offset(x: -slotW / 2 + 12, y: -slotH / 2 + 12)
            screwDot.offset(x: slotW / 2 - 12, y: -slotH / 2 + 12)
            screwDot.offset(x: -slotW / 2 + 12, y: slotH / 2 - 12)
            screwDot.offset(x: slotW / 2 - 12, y: slotH / 2 - 12)
        }
    }

    private var screwDot: some View {
        ZStack {
            Circle().fill(Color(white: 0.3)).frame(width: 6, height: 6)
            Circle().fill(Color(white: 0.5)).frame(width: 4, height: 4)
            Rectangle().fill(Color(white: 0.2)).frame(width: 4, height: 0.5)
                .rotationEffect(.degrees(45))
        }
    }

    private var ledIndicator: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color.green.opacity(0.9))
                .frame(width: 5, height: 5)
                .overlay(Circle().stroke(Color.black.opacity(0.3), lineWidth: 0.5))
                .overlay(
                    Circle().fill(Color.green.opacity(0.4)).frame(width: 8, height: 8).blur(radius: 2)
                )
            Text("MD")
                .font(.system(size: 6, weight: .black, design: .monospaced))
                .foregroundColor(Color(white: 0.25))
        }
        .offset(x: -slotW / 2 + 20, y: -slotH / 2 + 14)
    }

    private var slotDoor: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.85), Color(white: 0.72),
                        Color(white: 0.78), Color(white: 0.62),
                        Color(white: 0.68), Color(white: 0.54),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .frame(width: 12, height: 100)
            .rotation3DEffect(.degrees(doorAngle), axis: (0, 1, 0), anchor: .trailing, perspective: 0.5)
            .offset(x: (slotW - 28) / 2 + 2, y: 26)
    }

    private var bezelLabel: some View {
        HStack(spacing: 3) {
            Text("MD")
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundColor(Color(white: 0.3))
            Text("SLOT")
                .font(.system(size: 7, weight: .regular, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(Color(white: 0.22))
        }
        .offset(y: -slotH / 2 + 12)
    }

    // MARK: - Animation Sequence (50% slower)

    private func runSequence() {
        playInsertSound()

        withAnimation(.easeOut(duration: 0.40)) {
            contentOpacity = 1
        }

        Task {
            try? await Task.sleep(nanoseconds: 135_000_000)

            withAnimation(Anim.mdDoor) { doorAngle = -85 }

            try? await Task.sleep(nanoseconds: 405_000_000)

            withAnimation(Anim.mdInsert) { mdOffset = 0 }

            try? await Task.sleep(nanoseconds: 855_000_000)

            withAnimation(Anim.snap) { doorAngle = 0 }

            try? await Task.sleep(nanoseconds: 405_000_000)

            withAnimation(Anim.mdShutter) { shutterReveal = 1 }

            try? await Task.sleep(nanoseconds: 495_000_000)

            isSpinning = true
            withAnimation(Anim.mdSpin) { discRotation = 720 }

            try? await Task.sleep(nanoseconds: 1_012_500_000)

            withAnimation(.easeOut(duration: 0.45)) {
                contentOpacity = 0
            }

            try? await Task.sleep(nanoseconds: 562_500_000)
            onFinish()
        }
    }
}

// MARK: - Sound Effect Helper

private func playInsertSound() {
    Task {
        guard let url = Bundle.main.url(forResource: "md_insert", withExtension: "wav") else { return }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = 0.4
        player?.play()
    }
}
