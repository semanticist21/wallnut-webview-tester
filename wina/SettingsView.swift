//
//  SettingsView.swift
//  wina
//
//  Created by Claude on 12/7/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // WebView Settings
    @AppStorage("enableJavaScript") private var enableJavaScript: Bool = true
    @AppStorage("enableCookies") private var enableCookies: Bool = true
    @AppStorage("allowZoom") private var allowZoom: Bool = true
    @AppStorage("mediaAutoplay") private var mediaAutoplay: Bool = false
    @AppStorage("inlineMediaPlayback") private var inlineMediaPlayback: Bool = true
    @AppStorage("customUserAgent") private var customUserAgent: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("JavaScript", isOn: $enableJavaScript)
                    Toggle("Cookies", isOn: $enableCookies)
                    Toggle("Zoom", isOn: $allowZoom)
                } header: {
                    Text("Core Settings")
                }

                Section {
                    Toggle("Auto-play Media", isOn: $mediaAutoplay)
                    Toggle("Inline Playback", isOn: $inlineMediaPlayback)
                } header: {
                    Text("Media")
                }

                Section {
                    TextField("Custom User-Agent", text: $customUserAgent, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.system(size: 14, design: .monospaced))
                } header: {
                    Text("User-Agent")
                } footer: {
                    Text("Leave empty to use default")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
