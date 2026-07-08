import SwiftUI

struct SettingsView: View {
    @ObservedObject var theme: ThemeManager
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.controlPadding) {
                Text("SETTINGS").font(.mono(11, .bold)).foregroundStyle(Theme.ink).tracking(1)
                Spacer()
            }
            .padding(.horizontal, Spacing.sectionPadding).padding(.top, Spacing.panelPadding).padding(.bottom, Spacing.controlSpacing)

            Rectangle().fill(Theme.inkFaint).frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    colorThemeSection
                    sectionDivider
                    visualizerSection
                    sectionDivider
                    accentSection
                    sectionDivider
                    displaySection
                    sectionDivider
                    visibilitySection
                }
                .padding(.bottom, Spacing.controlPadding)
            }
        }
        .frame(width: 320)
        .background(Theme.panel)
    }

    // MARK: - Section Divider

    private var sectionDivider: some View {
        Rectangle().fill(Theme.inkFaint.opacity(0.35)).frame(height: 1).padding(.horizontal, Spacing.sectionPadding)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.mono(Typography.label, .medium)).foregroundStyle(Theme.inkDim).tracking(1.5)
            .padding(.horizontal, Spacing.sectionPadding).padding(.top, Spacing.panelPadding).padding(.bottom, Spacing.buttonSpacing)
    }

    // MARK: - Color Theme

    private var colorThemeSection: some View {
        VStack(spacing: 0) {
            sectionHeader("COLOR THEME")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.hairline), count: 4), spacing: Spacing.buttonSpacing) {
                ForEach(theme.palettes) { palette in
                    themeCell(palette)
                }
            }
            .padding(.horizontal, Spacing.sectionPadding)
            .padding(.bottom, Spacing.sectionSpacing)
        }
    }

    private func themeCell(_ p: Palette) -> some View {
        let isSelected = theme.selectedID == p.id
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { theme.select(p) }
        } label: {
            VStack(spacing: Spacing.snug) {
                RoundedRectangle(cornerRadius: Radius.pill)
                    .fill(Color(hex: p.accent))
                    .frame(height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.pill)
                            .stroke(isSelected ? Theme.dotOn : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? Color(hex: p.accent).opacity(0.4) : .clear, radius: 4)
                Text(p.name)
                    .font(.mono(Typography.badge, isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Theme.dotOn : Theme.ink)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, Spacing.snug)
            .padding(.horizontal, 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Visualizer

    private var visualizerSection: some View {
        VStack(spacing: 0) {
            sectionHeader("VISUALIZER")

            HStack(spacing: Spacing.buttonSpacing) {
                Text("STYLE")
                    .font(.mono(Typography.label)).tracking(1.5).foregroundStyle(Theme.inkFaint)
                    .frame(width: 38, alignment: .leading)
                ForEach(SpectrumStyle.allCases, id: \.self) { style in
                    PickerButton(
                        label: style.label.uppercased(),
                        isSelected: settings.spectrumStyle == style
                    ) {
                        withAnimation(.easeInOut(duration: 0.12)) { settings.spectrumStyle = style }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.sectionPadding).padding(.vertical, Spacing.snug)

            HStack(spacing: Spacing.controlSpacing) {
                Text("ROWS")
                    .font(.mono(Typography.label)).tracking(1.5).foregroundStyle(Theme.inkFaint)
                    .frame(width: 38, alignment: .leading)
                Button { if settings.spectrumRows > 6 { settings.spectrumRows -= 2 } } label: {
                    Image(systemName: "minus").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.inkFaint)
                        .frame(width: 22, height: 22)
                        .overlay(RoundedRectangle(cornerRadius: Radius.input).stroke(Theme.panelStroke))
                }.buttonStyle(.plain)
                Text("\(settings.spectrumRows)")
                    .font(.mono(Typography.title, .bold)).foregroundStyle(Theme.dotOn)
                    .frame(width: 30)
                Button { if settings.spectrumRows < 32 { settings.spectrumRows += 2 } } label: {
                    Image(systemName: "plus").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.inkFaint)
                        .frame(width: 22, height: 22)
                        .overlay(RoundedRectangle(cornerRadius: Radius.input).stroke(Theme.panelStroke))
                }.buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, Spacing.sectionPadding).padding(.vertical, Spacing.snug)

            HStack(spacing: Spacing.controlSpacing) {
                Text("SMOOTH")
                    .font(.mono(Typography.label)).tracking(1.5).foregroundStyle(Theme.inkFaint)
                    .frame(width: 38, alignment: .leading)
                Slider(value: $settings.spectrumSmoothing, in: 0.0...1.0)
                    .tint(Theme.accent)
                Text(String(format: "%.1f", settings.spectrumSmoothing))
                    .font(.mono(Typography.caption)).foregroundStyle(Theme.inkDim).frame(width: 24, alignment: .trailing)
            }
            .padding(.horizontal, Spacing.sectionPadding).padding(.vertical, Spacing.snug)
            .padding(.bottom, Spacing.snug)
        }
    }

    // MARK: - Custom Accent

    private var accentSection: some View {
        VStack(spacing: 0) {
            sectionHeader("CUSTOM ACCENT")

            HStack(spacing: Spacing.controlSpacing) {
                Toggle(isOn: $settings.accentOverrideEnabled) {
                    Text("OVERRIDE").font(.mono(Typography.label)).tracking(1.5).foregroundStyle(Theme.inkFaint)
                }
                .toggleStyle(.switch).tint(Theme.accent)
                Spacer()
                if settings.accentOverrideEnabled, let hex = settings.accentOverrideHex {
                    RoundedRectangle(cornerRadius: Radius.input)
                        .fill(Color(hex: hex))
                        .frame(width: 20, height: 20)
                        .overlay(RoundedRectangle(cornerRadius: Radius.input).stroke(Theme.panelStroke))
                }
            }
            .padding(.horizontal, Spacing.sectionPadding).padding(.vertical, Spacing.snug)

            if settings.accentOverrideEnabled {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.buttonSpacing), count: 9), spacing: Spacing.buttonSpacing) {
                    ForEach(accentPresets, id: \.hex) { preset in
                        let isSelected = settings.accentOverrideHex == preset.hex
                        Button {
                            withAnimation(.easeInOut(duration: 0.1)) { settings.selectAccent(preset.hex) }
                        } label: {
                            RoundedRectangle(cornerRadius: Radius.pill)
                                .fill(Color(hex: preset.hex))
                                .frame(height: 28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.pill)
                                        .stroke(isSelected ? Theme.dotOn : Color.clear, lineWidth: 2)
                                )
                                .shadow(color: isSelected ? Color(hex: preset.hex).opacity(0.5) : .clear, radius: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.sectionPadding).padding(.vertical, Spacing.buttonSpacing)

                Button {
                    withAnimation { settings.selectAccent(nil) }
                } label: {
                    Text("RESET ACCENT").font(.mono(Typography.badge, .bold)).tracking(1.2)
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.horizontal, Spacing.sectionSpacing).padding(.vertical, Spacing.buttonSpacing)
                        .background(Theme.inkFaint.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: Radius.input).stroke(Theme.panelStroke))
                        .clipShape(RoundedRectangle(cornerRadius: Radius.input))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.sectionPadding).padding(.bottom, Spacing.buttonSpacing)
            }
        }
    }

    // MARK: - Display

    private func densityBar(count: Int, height: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 1) {
            ForEach(0..<count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Theme.inkDim)
                    .frame(width: 3, height: height * CGFloat(i + 1) / CGFloat(count))
            }
        }
        .frame(width: 14, alignment: .center)
    }

    private var displaySection: some View {
        VStack(spacing: 0) {
            sectionHeader("DISPLAY")

            HStack(spacing: Spacing.buttonSpacing) {
                Text("DENSITY")
                    .font(.mono(Typography.label)).tracking(1.5).foregroundStyle(Theme.inkFaint)
                    .frame(width: 50, alignment: .leading)
                ForEach(LayoutDensity.allCases, id: \.self) { density in
                    HStack(spacing: Spacing.snug) {
                        densityBar(
                            count: density == .compact ? 3 : (density == .normal ? 4 : 5),
                            height: density == .compact ? 8 : (density == .normal ? 11 : 14)
                        )
                        PickerButton(
                            label: density.label.uppercased(),
                            isSelected: settings.layoutDensity == density
                        ) {
                            withAnimation { settings.layoutDensity = density }
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.sectionPadding).padding(.vertical, Spacing.buttonSpacing)
            .padding(.bottom, Spacing.snug)
        }
    }

    // MARK: - Visibility

    private var visibilitySection: some View {
        VStack(spacing: 0) {
            sectionHeader("VISIBILITY")

            VStack(spacing: Spacing.hairline) {
                toggleRow(label: "Album Art", icon: "photo", binding: $settings.showAlbumArt)
                toggleRow(label: "Spectrum", icon: "waveform", binding: $settings.showSpectrum)
            }
            .padding(.horizontal, Spacing.sectionPadding).padding(.bottom, Spacing.controlPadding)
        }
    }

    private func toggleRow(label: String, icon: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: Spacing.controlSpacing) {
            Image(systemName: icon)
                .font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
                .frame(width: 18)
            Text(label.uppercased())
                .font(.mono(Typography.caption)).foregroundStyle(Theme.ink)
            Spacer()
            Toggle(isOn: binding) { EmptyView() }
                .toggleStyle(.switch).tint(Theme.accent)
                .scaleEffect(0.85)
        }
        .padding(.horizontal, Spacing.sectionPadding).padding(.vertical, Spacing.buttonSpacing)
    }
}
