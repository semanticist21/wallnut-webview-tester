//
//  SafariVCInfoView.swift
//  wina
//

import SwiftUI
import SafariServices

struct SafariVCInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettings = false
    @State private var searchText = ""

    // Current configuration values
    @AppStorage("safariEntersReaderIfAvailable") private var entersReaderIfAvailable: Bool = false
    @AppStorage("safariBarCollapsingEnabled") private var barCollapsingEnabled: Bool = true
    @AppStorage("safariDismissButtonStyle") private var dismissButtonStyle: Int = 0
    @AppStorage("safariControlTintColorHex") private var controlTintColorHex: String = ""
    @AppStorage("safariBarTintColorHex") private var barTintColorHex: String = ""

    private var dismissButtonStyleText: String {
        switch dismissButtonStyle {
        case 1: return "Close"
        case 2: return "Cancel"
        default: return "Done"
        }
    }

    private var allItems: [SafariInfoSearchItem] {
        var items: [SafariInfoSearchItem] = []

        // Active Settings
        items.append(contentsOf: [
            SafariInfoSearchItem(category: "Active Settings", label: "Reader Mode", value: entersReaderIfAvailable ? "Enabled" : "Disabled"),
            SafariInfoSearchItem(category: "Active Settings", label: "Bar Collapsing", value: barCollapsingEnabled ? "Enabled" : "Disabled"),
            SafariInfoSearchItem(category: "Active Settings", label: "Dismiss Button", value: dismissButtonStyleText),
            SafariInfoSearchItem(category: "Active Settings", label: "Control Tint", value: controlTintColorHex.isEmpty ? "System" : controlTintColorHex),
            SafariInfoSearchItem(category: "Active Settings", label: "Bar Tint", value: barTintColorHex.isEmpty ? "System" : barTintColorHex)
        ])

        // Safari Features
        items.append(contentsOf: [
            SafariInfoSearchItem(category: "Safari Features", label: "Reader Mode", value: "iOS 9.0+"),
            SafariInfoSearchItem(category: "Safari Features", label: "AutoFill", value: "iOS 9.0+"),
            SafariInfoSearchItem(category: "Safari Features", label: "Fraudulent Website Detection", value: "iOS 9.0+"),
            SafariInfoSearchItem(category: "Safari Features", label: "Content Blockers", value: "iOS 9.0+"),
            SafariInfoSearchItem(category: "Safari Features", label: "Safari Extensions", value: "iOS 15.0+")
        ])

        // API Availability
        items.append(contentsOf: [
            SafariInfoSearchItem(category: "API Availability", label: "SFSafariViewController", value: "iOS 9.0"),
            SafariInfoSearchItem(category: "API Availability", label: "Configuration", value: "iOS 11.0"),
            SafariInfoSearchItem(category: "API Availability", label: "preferredBarTintColor", value: "iOS 10.0"),
            SafariInfoSearchItem(category: "API Availability", label: "preferredControlTintColor", value: "iOS 10.0"),
            SafariInfoSearchItem(category: "API Availability", label: "dismissButtonStyle", value: "iOS 11.0"),
            SafariInfoSearchItem(category: "API Availability", label: "prewarmConnections", value: "iOS 15.0"),
            SafariInfoSearchItem(category: "API Availability", label: "Activity Button", value: "iOS 15.0")
        ])

        // Privacy & Data
        items.append(contentsOf: [
            SafariInfoSearchItem(category: "Privacy & Data", label: "Cookie Isolation", value: "iOS 11.0"),
            SafariInfoSearchItem(category: "Privacy & Data", label: "LocalStorage Isolation", value: "iOS 11.0"),
            SafariInfoSearchItem(category: "Privacy & Data", label: "Session Isolation", value: "iOS 11.0")
        ])

        // Delegate Events
        items.append(contentsOf: [
            SafariInfoSearchItem(category: "Delegate Events", label: "safariViewControllerDidFinish", value: "Method"),
            SafariInfoSearchItem(category: "Delegate Events", label: "didCompleteInitialLoad", value: "Method"),
            SafariInfoSearchItem(category: "Delegate Events", label: "activityItemsFor", value: "Method"),
            SafariInfoSearchItem(category: "Delegate Events", label: "initialLoadDidRedirectTo", value: "Method"),
            SafariInfoSearchItem(category: "Delegate Events", label: "willOpenInBrowser", value: "Method"),
            SafariInfoSearchItem(category: "Delegate Events", label: "excludedActivityTypes", value: "Method")
        ])

        // Limitations
        items.append(contentsOf: [
            SafariInfoSearchItem(category: "Limitations", label: "No JavaScript Injection", value: "Limitation"),
            SafariInfoSearchItem(category: "Limitations", label: "No DOM Access", value: "Limitation"),
            SafariInfoSearchItem(category: "Limitations", label: "No Navigation Control", value: "Limitation"),
            SafariInfoSearchItem(category: "Limitations", label: "No URL Changes", value: "Limitation"),
            SafariInfoSearchItem(category: "Limitations", label: "Limited UI Customization", value: "Limitation")
        ])

        return items
    }

    private var filteredItems: [String: [SafariInfoSearchItem]] {
        let filtered = searchText.isEmpty ? allItems : allItems.filter {
            $0.label.localizedCaseInsensitiveContains(searchText) ||
            $0.value.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
        return Dictionary(grouping: filtered, by: { $0.category })
    }

    private var isSearching: Bool {
        !searchText.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    // Search Results
                    if filteredItems.isEmpty {
                        Section {
                            Text("No results for \"\(searchText)\"")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(Array(filteredItems.keys.sorted()), id: \.self) { category in
                            Section {
                                ForEach(filteredItems[category] ?? [], id: \.id) { item in
                                    SearchResultRow(item: item)
                                }
                            } header: {
                                Text(category)
                            }
                        }
                    }
                } else {
                    // Active Settings Section
                    Section {
                    HStack {
                        Spacer()
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Open Settings", systemImage: "gear")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    ActiveSettingRow(
                        title: "Reader Mode",
                        isEnabled: entersReaderIfAvailable,
                        info: "Automatically enters Reader mode when available"
                    )
                    ActiveSettingRow(
                        title: "Bar Collapsing",
                        isEnabled: barCollapsingEnabled,
                        info: "Navigation bar collapses on scroll"
                    )
                    SafariInfoRow(
                        label: "Dismiss Button",
                        value: dismissButtonStyleText,
                        info: "Button style shown in top-left corner"
                    )
                    SafariInfoRow(
                        label: "Control Tint",
                        value: controlTintColorHex.isEmpty ? "System" : controlTintColorHex,
                        info: "Tint color for buttons and controls"
                    )
                    SafariInfoRow(
                        label: "Bar Tint",
                        value: barTintColorHex.isEmpty ? "System" : barTintColorHex,
                        info: "Background color of navigation bar"
                    )
                } header: {
                    Text("Active Settings")
                }

                // Safari Features Section
                Section {
                    SafariFeatureRow(
                        title: "Reader Mode",
                        description: "Distraction-free article view with customizable appearance",
                        availability: "iOS 9.0+"
                    )
                    SafariFeatureRow(
                        title: "AutoFill",
                        description: "Access to saved passwords via iCloud Keychain",
                        availability: "iOS 9.0+"
                    )
                    SafariFeatureRow(
                        title: "Fraudulent Website Detection",
                        description: "Warns users about suspected phishing sites",
                        availability: "iOS 9.0+"
                    )
                    SafariFeatureRow(
                        title: "Content Blockers",
                        description: "User's installed Safari content blockers are applied",
                        availability: "iOS 9.0+"
                    )
                    SafariFeatureRow(
                        title: "Safari Extensions",
                        description: "User's Safari web extensions are available",
                        availability: "iOS 15.0+"
                    )
                } header: {
                    Text("Safari Features")
                }

                // API Availability Section
                Section {
                    SafariAPIRow(
                        api: "SFSafariViewController",
                        description: "Core Safari view controller",
                        minVersion: "iOS 9.0",
                        supported: true
                    )
                    SafariAPIRow(
                        api: "Configuration",
                        description: "Reader mode, bar collapsing options",
                        minVersion: "iOS 11.0",
                        supported: true
                    )
                    SafariAPIRow(
                        api: "preferredBarTintColor",
                        description: "Navigation bar background color",
                        minVersion: "iOS 10.0",
                        supported: true
                    )
                    SafariAPIRow(
                        api: "preferredControlTintColor",
                        description: "Button and control tint color",
                        minVersion: "iOS 10.0",
                        supported: true
                    )
                    SafariAPIRow(
                        api: "dismissButtonStyle",
                        description: "Done/Close/Cancel button style",
                        minVersion: "iOS 11.0",
                        supported: true
                    )
                    SafariAPIRow(
                        api: "prewarmConnections",
                        description: "Pre-load URLs before presenting",
                        minVersion: "iOS 15.0",
                        supported: true
                    )
                    SafariAPIRow(
                        api: "Activity Button",
                        description: "Custom Share Extension in toolbar",
                        minVersion: "iOS 15.0",
                        supported: true
                    )
                } header: {
                    Text("API Availability")
                }

                // Privacy & Data Section
                Section {
                    SafariPrivacyRow(
                        title: "Cookie Isolation",
                        description: "Cookies are NOT shared with Safari app",
                        since: "iOS 11.0"
                    )
                    SafariPrivacyRow(
                        title: "LocalStorage Isolation",
                        description: "Website data is sandboxed per app",
                        since: "iOS 11.0"
                    )
                    SafariPrivacyRow(
                        title: "Session Isolation",
                        description: "Each SFSafariViewController instance has separate storage",
                        since: "iOS 11.0"
                    )
                } header: {
                    Text("Privacy & Data")
                }

                // Delegate Events Section
                Section {
                    SafariDelegateRow(
                        method: "safariViewControllerDidFinish(_:)",
                        description: "Called when user taps Done button"
                    )
                    SafariDelegateRow(
                        method: "didCompleteInitialLoad",
                        description: "Called when initial page load completes (success or failure)"
                    )
                    SafariDelegateRow(
                        method: "activityItemsFor(_:title:)",
                        description: "Provide custom activities for Share sheet"
                    )
                    SafariDelegateRow(
                        method: "initialLoadDidRedirectTo(_:)",
                        description: "Called when initial load redirects to new URL"
                    )
                    SafariDelegateRow(
                        method: "willOpenInBrowser()",
                        description: "Called before opening URL in Safari app"
                    )
                    SafariDelegateRow(
                        method: "excludedActivityTypes",
                        description: "Exclude specific activities from Share sheet"
                    )
                } header: {
                    Text("Delegate Events")
                }

                // Limitations Section
                Section {
                    SafariLimitationRow(
                        title: "No JavaScript Injection",
                        description: "Cannot execute custom JavaScript code"
                    )
                    SafariLimitationRow(
                        title: "No DOM Access",
                        description: "Cannot read or modify page content"
                    )
                    SafariLimitationRow(
                        title: "No Navigation Control",
                        description: "Cannot intercept or redirect navigation"
                    )
                    SafariLimitationRow(
                        title: "No URL Changes",
                        description: "Cannot change URL after presentation"
                    )
                    SafariLimitationRow(
                        title: "Limited UI Customization",
                        description: "Only colors and dismiss button style can be changed"
                    )
                } header: {
                    Text("Limitations")
                }
                }
            }
            .searchable(text: $searchText, prompt: "Search settings and features")
            .navigationTitle("SafariVC Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SafariVCSettingsView()
            }
        }
    }
}

// MARK: - Helper Views

private struct SafariInfoRow: View {
    let label: String
    let value: String
    var info: String? = nil

    @State private var showInfo = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
            if let info {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showInfo) {
                    Text(info)
                        .font(.callout)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
            }
        }
    }
}

private struct ActiveSettingRow: View {
    let title: String
    let isEnabled: Bool
    var info: String? = nil

    @State private var showInfo = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(isEnabled ? "Enabled" : "Disabled")
                .foregroundStyle(isEnabled ? .green : .secondary)
            if let info {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showInfo) {
                    Text(info)
                        .font(.callout)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
            }
        }
    }
}

private struct SafariFeatureRow: View {
    let title: String
    let description: String
    let availability: String

    @State private var showInfo = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
            }

            Spacer()

            Text(availability)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                showInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showInfo) {
                Text(description)
                    .font(.callout)
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct SafariAPIRow: View {
    let api: String
    let description: String
    let minVersion: String
    let supported: Bool

    @State private var showInfo = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(supported ? .green : .red)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(api)
                    .font(.subheadline.monospaced())
            }

            Spacer()

            Text(minVersion)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                showInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showInfo) {
                Text(description)
                    .font(.callout)
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct SafariPrivacyRow: View {
    let title: String
    let description: String
    let since: String

    @State private var showInfo = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.blue)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
            }

            Spacer()

            Text(since)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                showInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showInfo) {
                Text(description)
                    .font(.callout)
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct SafariDelegateRow: View {
    let method: String
    let description: String

    @State private var showInfo = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "function")
                .foregroundStyle(.purple)
                .font(.body)

            Text(method)
                .font(.caption.monospaced())
                .lineLimit(1)

            Spacer()

            Button {
                showInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showInfo) {
                Text(description)
                    .font(.callout)
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct SafariLimitationRow: View {
    let title: String
    let description: String

    @State private var showInfo = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.body)

            Text(title)
                .font(.subheadline)

            Spacer()

            Button {
                showInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showInfo) {
                Text(description)
                    .font(.callout)
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Search Item Model

private struct SafariInfoSearchItem: Identifiable {
    let id = UUID()
    let category: String
    let label: String
    let value: String
}

private struct SearchResultRow: View {
    let item: SafariInfoSearchItem

    var body: some View {
        HStack {
            Text(item.label)
            Spacer()
            Text(item.value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SafariVCInfoView()
}
