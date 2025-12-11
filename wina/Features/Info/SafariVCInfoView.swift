//
//  SafariVCInfoView.swift
//  wina
//

import SwiftUI
import SafariServices

struct SafariVCInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Overview Section
                Section {
                    InfoRow(label: "Class", value: "SFSafariViewController")
                    InfoRow(label: "Framework", value: "SafariServices")
                    InfoRow(label: "Available", value: "iOS 9.0+")
                } header: {
                    Text("Overview")
                }

                // Features Section
                Section {
                    FeatureRow(
                        title: "Shared Cookies & Data",
                        description: "Shares cookies, autofill, and website data with Safari",
                        supported: true
                    )
                    FeatureRow(
                        title: "Reader Mode",
                        description: "Built-in reader mode for articles",
                        supported: true
                    )
                    FeatureRow(
                        title: "Content Blockers",
                        description: "Supports user's Safari content blockers",
                        supported: true
                    )
                    FeatureRow(
                        title: "AutoFill",
                        description: "Access to saved passwords and payment info",
                        supported: true
                    )
                    FeatureRow(
                        title: "Safari Extensions",
                        description: "User's Safari extensions are available",
                        supported: true
                    )
                } header: {
                    Text("Features")
                }

                // Limitations Section
                Section {
                    FeatureRow(
                        title: "Custom JavaScript",
                        description: "Cannot inject or execute custom JavaScript",
                        supported: false
                    )
                    FeatureRow(
                        title: "Navigation Control",
                        description: "Cannot intercept or control navigation",
                        supported: false
                    )
                    FeatureRow(
                        title: "Content Access",
                        description: "Cannot access page content or DOM",
                        supported: false
                    )
                    FeatureRow(
                        title: "Custom UI",
                        description: "Limited UI customization options",
                        supported: false
                    )
                    FeatureRow(
                        title: "URL Updates",
                        description: "Cannot change URL after presentation",
                        supported: false
                    )
                } header: {
                    Text("Limitations")
                }

                // Configuration Section
                Section {
                    ConfigRow(title: "Bar Collapsing", value: "Enabled", info: "Navigation bar collapses on scroll")
                    ConfigRow(title: "Reader Mode", value: "Auto", info: "Enters reader mode if available")
                } header: {
                    Text("Current Configuration")
                }

                // Use Cases Section
                Section {
                    UseCaseRow(
                        title: "OAuth & Login",
                        description: "Best for third-party authentication flows"
                    )
                    UseCaseRow(
                        title: "External Links",
                        description: "Opening links user expects to behave like Safari"
                    )
                    UseCaseRow(
                        title: "Privacy-Sensitive",
                        description: "When users need their Safari privacy settings"
                    )
                } header: {
                    Text("Best Use Cases")
                }

                // Comparison Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("vs WKWebView")
                            .font(.subheadline.weight(.semibold))
                        Text("SFSafariViewController is a full Safari experience with shared data, while WKWebView offers complete control but isolated storage.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Comparison")
                }
            }
            .navigationTitle("SafariVC Info")
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

// MARK: - Helper Views

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

private struct FeatureRow: View {
    let title: String
    let description: String
    let supported: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(supported ? .green : .red)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct ConfigRow: View {
    let title: String
    let value: String
    let info: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
            }
            Text(info)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

private struct UseCaseRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.medium))
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SafariVCInfoView()
}
