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
                RecordingView()
            case .library:
                LibraryView()
            }
        }
        .background(AppColors.canvas)
    }
}

#Preview {
    RootView()
}
