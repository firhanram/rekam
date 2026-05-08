import CoreMedia
import SwiftUI

struct LibraryView: View {
    @State private var viewModel = LibraryViewModel()
    @State private var editingItem: RecordingItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().background(AppColors.border)
            content
        }
        .background(AppColors.canvas)
        .task { await viewModel.refresh() }
        .sheet(item: $editingItem) { item in
            TrimEditorView(item: item)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Library")
                .eyebrowStyle()
            Text("Your recordings")
                .font(AppFonts.display)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(AppSpacing.xl)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.items.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.items) { item in
                        Button {
                            editingItem = item
                        } label: {
                            LibraryRow(
                                item: item,
                                isExporting: viewModel.exportingItemID == item.id
                            )
                        }
                        .buttonStyle(.plain)
                            .contextMenu {
                                Button("Open in Trim Editor") {
                                    editingItem = item
                                }
                                Button("Export to Downloads") {
                                    Task { await viewModel.exportToDownloads(item) }
                                }
                                Button("Reveal in Finder") {
                                    viewModel.revealInFinder(item)
                                }
                                Button("Delete", role: .destructive) {
                                    Task { await viewModel.delete(item) }
                                }
                            }
                    }
                }
                .padding(AppSpacing.xl)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "film.stack")
                .font(.system(size: 32))
                .foregroundStyle(AppColors.textFaint)
            Text("No recordings yet")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textSecondary)
            Text("Recordings you make will show up here.")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LibraryRow: View {
    let item: RecordingItem
    var isExporting: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "film")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: 56, height: 32)
                .background(AppColors.surfacePlus)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusInput))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(item.name)
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: AppSpacing.sm) {
                    Text(formatDuration(item.duration))
                    Text("·")
                    Text(formatSize(item.sizeBytes))
                    Text("·")
                    Text(formatDate(item.createdAt))
                }
                .font(AppFonts.mono)
                .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            if isExporting {
                ProgressView()
                    .scaleEffect(0.6)
                    .controlSize(.small)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.textFaint)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
    }

    private func formatDuration(_ time: CMTime) -> String {
        let seconds = CMTimeGetSeconds(time)
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    private func formatSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    LibraryView()
        .frame(width: 720, height: 480)
}
