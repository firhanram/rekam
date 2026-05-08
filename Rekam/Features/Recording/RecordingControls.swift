import SwiftUI

struct RecordingControls: View {
    @Bindable var viewModel: RecordingViewModel

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            recordButton
            elapsedLabel
            Spacer()
            audioToggles
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.surface)
        .overlay(
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1),
            alignment: .top
        )
    }

    private var recordButton: some View {
        Button {
            Task { await viewModel.toggleRecording() }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: viewModel.state.isActive ? "stop.fill" : "record.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .symbolEffect(.pulse, options: .repeating, isActive: viewModel.state.isActive)
                Text(viewModel.state.isActive ? "Stop" : "Record")
                    .font(AppFonts.title)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
            .foregroundStyle(buttonForeground)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusPill))
        }
        .buttonStyle(.plain)
        .disabled(disableRecord)
    }

    private var disableRecord: Bool {
        viewModel.state.isBusy || (viewModel.filter == nil && !viewModel.state.isActive)
    }

    private var buttonBackground: Color {
        if disableRecord { return AppColors.muted }
        return viewModel.state.isActive ? AppColors.recordingBg : AppColors.brand
    }

    private var buttonForeground: Color {
        viewModel.state.isActive ? AppColors.recording : .white
    }

    private var elapsedLabel: some View {
        Text(formatElapsed(viewModel.elapsed))
            .font(AppFonts.mono)
            .foregroundStyle(viewModel.state.isActive ? AppColors.recording : AppColors.textTertiary)
            .monospacedDigit()
    }

    private var audioToggles: some View {
        HStack(spacing: AppSpacing.sm) {
            audioToggle(
                isOn: $viewModel.configuration.captureSystemAudio,
                onIcon: "speaker.wave.2.fill",
                offIcon: "speaker.slash"
            )
            audioToggle(
                isOn: $viewModel.configuration.captureMicrophone,
                onIcon: "mic.fill",
                offIcon: "mic.slash"
            )
        }
    }

    private func audioToggle(isOn: Binding<Bool>, onIcon: String, offIcon: String) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Image(systemName: isOn.wrappedValue ? onIcon : offIcon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isOn.wrappedValue ? AppColors.brand : AppColors.textTertiary)
                .frame(width: 28, height: 28)
                .background(isOn.wrappedValue ? AppColors.brandTint50 : AppColors.surfacePlus)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusInput))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.state.isActive || viewModel.state.isBusy)
    }

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
