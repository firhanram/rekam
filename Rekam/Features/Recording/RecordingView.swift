import SwiftUI

struct RecordingView: View {
    @State private var viewModel = RecordingViewModel()
    @State private var screenAuthorized: Bool = PermissionsHelper.screenRecordingAuthorized

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    if !screenAuthorized {
                        permissionBanner
                    }
                    presetPicker
                    sourceCard
                    statusCard
                }
                .padding(AppSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            RecordingControls(viewModel: viewModel)
        }
        .background(AppColors.canvas)
        .onAppear { refreshPermissions() }
    }

    private var permissionBanner: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(AppColors.warningText)
            VStack(alignment: .leading, spacing: 2) {
                Text("Screen recording permission needed")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.warningText)
                Text("Grant access in System Settings, then return to Rekam.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.warningText.opacity(0.85))
            }
            Spacer()
            Button("Open Settings") {
                PermissionsHelper.openScreenRecordingSettings()
            }
            .buttonStyle(.bordered)
        }
        .padding(AppSpacing.md)
        .background(AppColors.warningBg)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
    }

    private func refreshPermissions() {
        screenAuthorized = PermissionsHelper.screenRecordingAuthorized
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Record")
                .eyebrowStyle()
            Text("Capture a window, region, or display")
                .font(AppFonts.display)
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Quality")
                .eyebrowStyle()
            HStack(spacing: AppSpacing.sm) {
                ForEach(CaptureConfiguration.Preset.allCases) { preset in
                    presetPill(preset)
                }
            }
        }
    }

    private func presetPill(_ preset: CaptureConfiguration.Preset) -> some View {
        let selected = viewModel.configuration.preset == preset
        let bg: Color = {
            guard selected else { return AppColors.surfacePlus }
            switch preset {
            case .smaller: return AppColors.presetSmallerBg
            case .balanced: return AppColors.presetBalancedBg
            case .higher: return AppColors.presetHigherBg
            }
        }()
        let fg: Color = {
            guard selected else { return AppColors.textTertiary }
            switch preset {
            case .smaller: return AppColors.presetSmallerText
            case .balanced: return AppColors.presetBalancedText
            case .higher: return AppColors.presetHigherText
            }
        }()
        return Button {
            viewModel.setPreset(preset)
        } label: {
            Text(preset.label)
                .font(AppFonts.body)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .foregroundStyle(fg)
                .background(bg)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusBadge))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.state.isActive || viewModel.state.isBusy)
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Source")
                .eyebrowStyle()
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(AppColors.surfacePlus)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusInput))

                Text(viewModel.sourceLabel)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                Button {
                    Task { await viewModel.chooseSource() }
                } label: {
                    Text(viewModel.filter == nil ? "Choose source…" : "Change…")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.brand)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.state.isActive || viewModel.state.isBusy)
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        }
    }

    @ViewBuilder
    private var statusCard: some View {
        switch viewModel.state {
        case .failed(let message):
            statusRow(text: message, bg: AppColors.errorBg, fg: AppColors.errorText, icon: "exclamationmark.triangle.fill")
        case .recording:
            statusRow(text: "Recording…", bg: AppColors.recordingBg, fg: AppColors.recording, icon: "record.circle.fill")
        case .preparing:
            statusRow(text: "Preparing…", bg: AppColors.infoBg, fg: AppColors.infoText, icon: "hourglass")
        case .stopping:
            statusRow(text: "Finalizing…", bg: AppColors.infoBg, fg: AppColors.infoText, icon: "hourglass")
        case .idle:
            if let url = viewModel.lastRecordingURL {
                statusRow(text: "Saved \(url.lastPathComponent)", bg: AppColors.successBg, fg: AppColors.successText, icon: "checkmark.circle.fill")
            } else {
                EmptyView()
            }
        }
    }

    private func statusRow(text: String, bg: Color, fg: Color, icon: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(text)
                .font(AppFonts.body)
            Spacer()
        }
        .foregroundStyle(fg)
        .padding(AppSpacing.md)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
    }
}

#Preview {
    RecordingView()
        .frame(width: 720, height: 480)
}
