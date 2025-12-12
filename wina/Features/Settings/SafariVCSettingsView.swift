//
//  SafariVCSettingsView.swift
//  wina
//
//  Created by Claude on 12/11/25.
//

import SwiftUI

// MARK: - SafariVC Configuration Settings (Requires Reload)

struct SafariVCConfigurationSettingsView: View {
    @Binding var webViewID: UUID

    // Store initial values for change detection
    @State private var initialValues: [String: AnyHashable] = [:]
    @State private var hasChanges: Bool = false

    // SafariVC Configuration
    @AppStorage("safariEntersReaderIfAvailable") private var entersReaderIfAvailable: Bool = false
    @AppStorage("safariBarCollapsingEnabled") private var barCollapsingEnabled: Bool = true
    @AppStorage("safariDismissButtonStyle") private var dismissButtonStyle: Int = 0
    @AppStorage("safariControlTintColorHex") private var controlTintColorHex: String = ""
    @AppStorage("safariBarTintColorHex") private var barTintColorHex: String = ""

    private var currentValues: [String: AnyHashable] {
        [
            "entersReaderIfAvailable": entersReaderIfAvailable,
            "barCollapsingEnabled": barCollapsingEnabled,
            "dismissButtonStyle": dismissButtonStyle,
            "controlTintColorHex": controlTintColorHex,
            "barTintColorHex": barTintColorHex
        ]
    }

    var body: some View {
        List {
            if hasChanges {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Changes will reload SafariVC")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                SettingToggleRow(
                    title: "Reader Mode",
                    isOn: $entersReaderIfAvailable,
                    info: "Automatically enters Reader mode if available for the page."
                )
                SettingToggleRow(
                    title: "Bar Collapsing",
                    isOn: $barCollapsingEnabled,
                    info: "Allows the navigation bar to collapse when scrolling down."
                )
            } header: {
                Text("Behavior")
            }

            Section {
                Picker("Dismiss Button", selection: $dismissButtonStyle) {
                    Text("Done").tag(0)
                    Text("Close").tag(1)
                    Text("Cancel").tag(2)
                }
            } header: {
                Text("UI Style")
            }

            Section {
                ColorPickerRow(
                    title: "Control Tint",
                    colorHex: $controlTintColorHex,
                    info: "Tint color for buttons and other controls."
                )
                ColorPickerRow(
                    title: "Bar Tint",
                    colorHex: $barTintColorHex,
                    info: "Background color of the navigation bar."
                )
            } header: {
                Text("Colors")
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    resetToDefaults()
                }
                .foregroundStyle(.red)
            }
        }
        .onAppear {
            initialValues = currentValues
        }
        .onChange(of: entersReaderIfAvailable) { updateChangeState() }
        .onChange(of: barCollapsingEnabled) { updateChangeState() }
        .onChange(of: dismissButtonStyle) { updateChangeState() }
        .onChange(of: controlTintColorHex) { updateChangeState() }
        .onChange(of: barTintColorHex) { updateChangeState() }
        .onDisappear {
            if hasChanges {
                webViewID = UUID()
            }
        }
    }

    private func updateChangeState() {
        hasChanges = initialValues != currentValues
    }

    private func resetToDefaults() {
        entersReaderIfAvailable = false
        barCollapsingEnabled = true
        dismissButtonStyle = 0
        controlTintColorHex = ""
        barTintColorHex = ""
    }
}

// MARK: - SafariVC Loaded Settings View (Menu Style)

struct SafariVCLoadedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var webViewID: UUID

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        SafariVCConfigurationSettingsView(webViewID: $webViewID)
                    } label: {
                        SafariSettingsCategoryRow(
                            icon: "gearshape.fill",
                            iconColor: .orange,
                            title: "Configuration",
                            description: "Changes reload SafariVC"
                        )
                    }
                } footer: {
                    Text("SafariViewController settings are applied at creation time. All changes require reload.")
                        .font(.caption)
                }
            }
            .navigationTitle("SafariVC Settings")
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

// MARK: - SafariVC Settings Category Row

private struct SafariSettingsCategoryRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - SafariVC Settings View (Initial Setup)

struct SafariVCSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // SafariVC Configuration
    @AppStorage("safariEntersReaderIfAvailable") private var entersReaderIfAvailable: Bool = false
    @AppStorage("safariBarCollapsingEnabled") private var barCollapsingEnabled: Bool = true
    @AppStorage("safariDismissButtonStyle") private var dismissButtonStyle: Int = 0 // 0: done, 1: close, 2: cancel
    @AppStorage("safariControlTintColorHex") private var controlTintColorHex: String = ""
    @AppStorage("safariBarTintColorHex") private var barTintColorHex: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SettingToggleRow(
                        title: "Reader Mode",
                        isOn: $entersReaderIfAvailable,
                        info: "Automatically enters Reader mode if available for the page."
                    )
                    SettingToggleRow(
                        title: "Bar Collapsing",
                        isOn: $barCollapsingEnabled,
                        info: "Allows the navigation bar to collapse when scrolling down."
                    )
                } header: {
                    Text("Behavior")
                }

                Section {
                    Picker("Dismiss Button", selection: $dismissButtonStyle) {
                        Text("Done").tag(0)
                        Text("Close").tag(1)
                        Text("Cancel").tag(2)
                    }
                } header: {
                    Text("UI Style")
                }

                Section {
                    ColorPickerRow(
                        title: "Control Tint",
                        colorHex: $controlTintColorHex,
                        info: "Tint color for buttons and other controls."
                    )
                    ColorPickerRow(
                        title: "Bar Tint",
                        colorHex: $barTintColorHex,
                        info: "Background color of the navigation bar."
                    )
                } header: {
                    Text("Colors")
                }

            }
            .navigationTitle("SafariVC Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        resetToDefaults()
                    }
                    .foregroundStyle(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func resetToDefaults() {
        entersReaderIfAvailable = false
        barCollapsingEnabled = true
        dismissButtonStyle = 0
        controlTintColorHex = ""
        barTintColorHex = ""
    }
}

#Preview("SafariVC Settings") {
    SafariVCSettingsView()
}

#Preview("SafariVC Loaded Settings") {
    @Previewable @State var id = UUID()
    SafariVCLoadedSettingsView(webViewID: $id)
}

#Preview("SafariVC Configuration") {
    @Previewable @State var id = UUID()
    NavigationStack {
        SafariVCConfigurationSettingsView(webViewID: $id)
    }
}
