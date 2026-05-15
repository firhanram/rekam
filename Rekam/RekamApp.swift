//
//  RekamApp.swift
//  Rekam
//
//  Created by Firhan Ramadhan on 07/05/26.
//

import SwiftUI

@main
struct RekamApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }

        WindowGroup("Preview", id: "preview", for: URL.self) { $url in
            PreviewWindow(url: url)
        }
        .windowResizability(.contentMinSize)
    }
}

private struct PreviewWindow: View {
    let url: URL?
    @State private var item: RecordingItem?

    var body: some View {
        Group {
            if let item {
                TrimEditorView(item: item)
                    .navigationTitle(item.name)
            } else {
                missing
            }
        }
        .task(id: url) {
            guard let url else {
                item = nil
                return
            }
            item = await RecordingStore().item(for: url)
        }
    }

    private var missing: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "questionmark.video")
                .font(.system(size: 32))
                .foregroundStyle(AppColors.textFaint)
            Text("Recording unavailable")
                .font(AppFonts.title)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(minWidth: 480, minHeight: 320)
        .background(AppColors.canvas)
    }
}
