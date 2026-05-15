import SwiftUI

struct TrimEditorView: View {
    @State private var viewModel: TrimEditorViewModel
    @Environment(\.dismiss) private var dismiss

    init(item: RecordingItem) {
        _viewModel = State(wrappedValue: TrimEditorViewModel(item: item))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            playerArea
            controls
        }
        .background(AppColors.canvas)
        .frame(minWidth: 720, minHeight: 540)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Trim")
                    .eyebrowStyle()
                Text(viewModel.item.name)
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(AppColors.surfacePlus)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusInput))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .overlay(
            Rectangle().fill(AppColors.border).frame(height: 1),
            alignment: .bottom
        )
    }

    private var playerArea: some View {
        PlayerContainer(player: viewModel.player)
            .background(AppColors.surfacePlus)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusPanel))
            .padding(AppSpacing.lg)
    }

    private var controls: some View {
        VStack(spacing: AppSpacing.md) {
            timecodeRow
            TrimSliderView(
                duration: viewModel.item.duration,
                startSeconds: $viewModel.startSeconds,
                endSeconds: $viewModel.endSeconds,
                currentSeconds: viewModel.currentSeconds,
                onScrub: { viewModel.seek(to: $0) }
            )
            transportRow
            volumeRow
            exportRow
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .overlay(
            Rectangle().fill(AppColors.border).frame(height: 1),
            alignment: .top
        )
    }

    private var timecodeRow: some View {
        HStack {
            timeChip(formatTimecode(viewModel.startSeconds), label: "Start")
            Spacer()
            Text(formatTimecode(viewModel.currentSeconds))
                .font(AppFonts.mono)
                .foregroundStyle(AppColors.brand)
            Spacer()
            timeChip(formatTimecode(viewModel.endSeconds), label: "End")
        }
    }

    private func timeChip(_ text: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .eyebrowStyle()
            Text(text)
                .font(AppFonts.mono)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.surfacePlus)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusBadge))
    }

    private var transportRow: some View {
        HStack(spacing: AppSpacing.sm) {
            transportButton(systemImage: "backward.end.fill") {
                viewModel.jumpToStart()
            }
            transportButton(
                systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill",
                primary: true
            ) {
                viewModel.togglePlayback()
            }
            .keyboardShortcut(.space, modifiers: [])
            transportButton(systemImage: "forward.end.fill") {
                viewModel.jumpToEnd()
            }
            Spacer()
            Picker("", selection: $viewModel.preset) {
                ForEach(ExportPreset.allCases) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 160)
            .disabled(viewModel.exportProgress != nil)
        }
    }

    private var volumeRow: some View {
        let disabled = !viewModel.hasAudio || viewModel.exportProgress != nil
        let muted = viewModel.isMuted || viewModel.volume == 0
        let percent = Int((viewModel.volume * 100).rounded())
        return HStack(spacing: AppSpacing.sm) {
            Button {
                viewModel.toggleMute()
            } label: {
                Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(muted ? AppColors.textTertiary : AppColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(AppColors.surfacePlus)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusInput))
            }
            .buttonStyle(.plain)
            .help(muted ? "Unmute" : "Mute")

            Slider(
                value: Binding(
                    get: { viewModel.volume },
                    set: { viewModel.setVolume($0) }
                ),
                in: 0...1
            )

            Text("\(muted ? 0 : percent)%")
                .font(AppFonts.mono)
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: 44, alignment: .trailing)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    private func transportButton(systemImage: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(primary ? .white : AppColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(primary ? AppColors.brand : AppColors.surfacePlus)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusInput))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var exportRow: some View {
        if let progress = viewModel.exportProgress {
            HStack(spacing: AppSpacing.sm) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                Text("\(Int(progress * 100))%")
                    .font(AppFonts.mono)
                    .foregroundStyle(AppColors.textTertiary)
            }
        } else if let url = viewModel.exportedURL {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.successText)
                Text("Saved to \(url.lastPathComponent)")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.successText)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.return)
            }
            .padding(AppSpacing.sm)
            .background(AppColors.successBg)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        } else if let message = viewModel.errorMessage {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColors.errorText)
                Text(message)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.errorText)
                Spacer()
            }
            .padding(AppSpacing.sm)
            .background(AppColors.errorBg)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        } else {
            HStack {
                Spacer()
                Button {
                    Task { await viewModel.export() }
                } label: {
                    Label("Export to Downloads", systemImage: "square.and.arrow.up")
                        .font(AppFonts.title)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .foregroundStyle(.white)
                        .background(viewModel.canExport ? AppColors.brand : AppColors.muted)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusPill))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canExport)
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }

    private func formatTimecode(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00.000" }
        let total = Int(seconds * 1000)
        let ms = total % 1000
        let s = (total / 1000) % 60
        let m = (total / 60_000) % 60
        let h = total / 3_600_000
        return h > 0
            ? String(format: "%d:%02d:%02d.%03d", h, m, s, ms)
            : String(format: "%02d:%02d.%03d", m, s, ms)
    }
}
