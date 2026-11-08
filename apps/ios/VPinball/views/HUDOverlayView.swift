import SwiftUI

struct HUDOverlayView: View {
    @ObservedObject var vpinballModel = VPinballModel.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 18) {
                    Text(vpinballModel.hudTitle ?? " ")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.primary)

                    ProgressView(value: Double(vpinballModel.hudProgress),
                                 total: 100)
                        .progressViewStyle(.linear)
                        .tint(Color.vpxDarkYellow)

                    Text(vpinballModel.hudStatus ?? " ")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
                .padding(22)
                .glassPanel(cornerRadius: 26)
                .environment(\.colorScheme, .dark)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    HUDOverlayView()
}

// MARK: - In-game menu

/// Touch-first replacement for the built-in in-game home menu: shown (game paused) when the menu button is pressed.
/// Common actions up front with a plain explanation each; everything else stays reachable under Advanced.
struct GameMenuView: View {
    @ObservedObject var vpinballModel = VPinballModel.shared
    @State private var state: PlayerStateData?
    @State private var musicVolume: Double = 100
    @State private var soundVolume: Double = 100
    @State private var showAdvanced = false
    @State private var confirmQuit = false

    private let manager = VPinballManager.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { resume() }

            GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    section("Game") {
                        row("play.fill", .green, "Resume", "Back to the game") { resume() }
                        row("arrow.counterclockwise", .orange, "Restart Table", "Start this table over from the beginning") {
                            close()
                            manager.quitPlay(restart: true)
                        }
                        if state?.hasRules == true {
                            row("book.fill", .blue, "Table Rules", "How to play, and what scores the most points") {
                                close()
                                manager.openVPXMenu("table/rules")
                            }
                        }
                        if state?.touchRails == true {
                            row("wrench.and.screwdriver.fill", .yellow, "Machine Setup",
                                "Coin door buttons for the machine's own settings and volume") {
                                close()
                                manager.showServiceButtons()
                            }
                        }
                        row("xmark.circle.fill", .red, "Quit to Tables", "End the game and go back to your table list") {
                            confirmQuit = true
                        }
                    }

                    section("Sound") {
                        slider("music.note", "Music & Callouts", "The machine's music, voices and effects", value: $musicVolume)
                        slider("speaker.wave.2.fill", "Table Sounds", "Flippers, bumpers, the ball rolling", value: $soundVolume)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { showAdvanced.toggle() }
                        } label: {
                            HStack {
                                Text("Advanced")
                                    .font(.subheadline.weight(.semibold))
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .rotationEffect(.degrees(showAdvanced ? 180 : 0))
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if showAdvanced {
                            VStack(spacing: 0) {
                                if state?.hasOptions == true {
                                    row("slider.horizontal.3", .purple, "Table Options", "Extra settings from the table's author, like lighting or mods") {
                                        close()
                                        manager.openVPXMenu("table/options")
                                    }
                                    divider
                                }
                                row("gearshape.2.fill", .gray, "All Settings", "The full Visual Pinball menu: graphics, controls, displays, plugins") {
                                    close()
                                    manager.openVPXMenu("homepage")
                                }
                            }
                            .background(rowBackground)
                        }
                    }
                }
                .padding(20)
                // Explicit width: a fixed width (not maxWidth) guarantees long explanations wrap instead of
                // widening the panel past the screen edges.
                .frame(width: min(480, geo.size.width - 32), alignment: .leading)
                .glassPanel(cornerRadius: 30)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            }
        }
        .environment(\.colorScheme, .dark)
        .onAppear(perform: refresh)
        .confirmationDialog("Quit this game?", isPresented: $confirmQuit, titleVisibility: .visible) {
            Button("Quit to Tables", role: .destructive) {
                close()
                manager.quitPlay()
            }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("Your current game will end.")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Paused")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vpxAccent)
                Text(state?.tableName ?? vpinballModel.activeTable?.name ?? "")
                    .font(.title2.bold())
                    .lineLimit(2)
            }
            Spacer()
            Button { resume() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Resume")
        }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white.opacity(0.08))
    }

    private var divider: some View {
        Divider().padding(.leading, 64)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            VStack(spacing: 0) {
                content()
            }
            .background(rowBackground)
        }
    }

    private func icon(_ systemName: String, _ color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(color.gradient))
    }

    private func row(_ systemName: String, _ color: Color, _ title: String, _ subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.play(lowFrequencySpeed: 0.3, highFrequencySpeed: 0.3, durationMs: 20)
            action()
        } label: {
            HStack(spacing: 14) {
                icon(systemName, color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func slider(_ systemName: String, _ title: String, _ subtitle: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                icon(systemName, .teal)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.body.weight(.semibold))
                    Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(Int(value.wrappedValue))%")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
            }
            Slider(value: value, in: 0 ... 100, step: 1) { editing in
                if !editing { applyVolumes() }
            }
            .tint(Color.vpxAccent)
            .onChange(of: value.wrappedValue) { applyVolumes() }
        }
        .padding(14)
    }

    private func refresh() {
        state = manager.playerState()
        musicVolume = Double(state?.musicVolume ?? 100)
        soundVolume = Double(state?.soundVolume ?? 100)
    }

    private func applyVolumes() {
        manager.setVolumes(music: Int(musicVolume), sound: Int(soundVolume))
    }

    private func close() {
        vpinballModel.showGameMenu = false
    }

    private func resume() {
        close()
        manager.resumePlay()
    }
}
