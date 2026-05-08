import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case record
    case library

    var id: String { rawValue }

    var title: String {
        switch self {
        case .record: "Record"
        case .library: "Library"
        }
    }

    var icon: String {
        switch self {
        case .record: "record.circle"
        case .library: "film.stack"
        }
    }
}

struct RootView: View {
    @State private var selection: SidebarItem? = .record

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                NavigationLink(value: item) {
                    Label(item.title, systemImage: item.icon)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selection ?? .record {
            case .record:
                RecordPlaceholder()
            case .library:
                LibraryPlaceholder()
            }
        }
        .background(AppColors.canvas)
    }
}

private struct RecordPlaceholder: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Record")
                .eyebrowStyle()
            Text("Recording UI lands in Phase 2")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textTertiary)
            #if DEBUG
            DebugRecordButton()
                .padding(.top, AppSpacing.lg)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
    }
}

#if DEBUG
private struct DebugRecordButton: View {
    @State private var status: String = "Idle"
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Button {
                Task { await runSmokeTest() }
            } label: {
                Label("Smoke test: pick + record 5s", systemImage: "ladybug")
                    .font(AppFonts.body)
            }
            .disabled(isRunning)

            Text(status)
                .font(AppFonts.mono)
                .foregroundStyle(AppColors.textTertiary)
                .textSelection(.enabled)
        }
    }

    @MainActor
    private func runSmokeTest() async {
        isRunning = true
        defer { isRunning = false }

        do {
            status = "Picking source…"
            let picker = ContentPicker()
            let filter = try await picker.pick()

            let recorder = ScreenRecorder()
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("rekam-smoke-\(Int(Date().timeIntervalSince1970)).mp4")

            status = "Recording 5s…"
            try await recorder.start(filter: filter, configuration: .balanced, outputURL: url)
            try await Task.sleep(nanoseconds: 5_000_000_000)
            let result = try await recorder.stop()

            let size = (try? FileManager.default.attributesOfItem(atPath: result.path)[.size] as? Int) ?? 0
            status = "OK: \(result.lastPathComponent) (\(size) bytes)"
            NSWorkspace.shared.activateFileViewerSelecting([result])
        } catch {
            status = "Failed: \(error.localizedDescription)"
        }
    }
}
#endif

private struct LibraryPlaceholder: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Library")
                .eyebrowStyle()
            Text("Library UI lands in Phase 3")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.canvas)
    }
}

#Preview {
    RootView()
}
