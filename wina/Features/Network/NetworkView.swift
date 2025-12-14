//
//  NetworkView.swift
//  wina
//
//  Network request monitoring view for WKWebView.
//  Captures fetch/XMLHttpRequest via JavaScript injection.
//

import SwiftUI

// MARK: - Network View

struct NetworkView: View {
    let networkManager: NetworkManager
    @Environment(\.dismiss) private var dismiss
    @State private var filterType: NetworkRequest.RequestType?
    @State private var showErrorsOnly: Bool = false
    @State private var showMixedOnly: Bool = false
    @State private var searchText: String = ""
    @State private var shareItem: NetworkShareContent?
    @State private var showSettings: Bool = false
    @State private var selectedRequest: NetworkRequest?
    @AppStorage("networkPreserveLog") private var preserveLog: Bool = false

    private var filteredRequests: [NetworkRequest] {
        var result = networkManager.requests

        if showErrorsOnly {
            result = result.filter { $0.error != nil || ($0.status ?? 0) >= 400 }
        } else if let filterType {
            result = result.filter { $0.requestType == filterType }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.url.localizedCaseInsensitiveContains(searchText)
                    || $0.method.localizedCaseInsensitiveContains(searchText)
                    || ($0.statusText?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result
    }

    private var settingsActive: Bool {
        preserveLog
    }

    var body: some View {
        VStack(spacing: 0) {
            networkHeader
            searchBar
            filterTabs

            Divider()

            if filteredRequests.isEmpty {
                emptyState
            } else {
                requestList
            }
        }
        .sheet(item: $shareItem) { item in
            NetworkShareSheet(content: item.content)
        }
        .sheet(isPresented: $showSettings) {
            NetworkSettingsSheet()
        }
        .sheet(item: $selectedRequest) { request in
            NetworkDetailView(request: request)
        }
    }

    // MARK: - Network Header

    private var networkHeader: some View {
        DevToolsHeader(
            title: "Network",
            leftButtons: [
                .init(icon: "xmark.circle.fill", color: .secondary) {
                    dismiss()
                },
                .init(
                    icon: "trash",
                    isDisabled: networkManager.requests.isEmpty
                ) {
                    networkManager.clear()
                },
                .init(
                    icon: "square.and.arrow.up",
                    isDisabled: networkManager.requests.isEmpty
                ) {
                    shareItem = NetworkShareContent(content: exportAsText())
                }
            ],
            rightButtons: [
                .init(
                    icon: "play.fill",
                    activeIcon: "pause.fill",
                    color: .green,
                    activeColor: .red,
                    isActive: networkManager.isCapturing
                ) {
                    networkManager.isCapturing.toggle()
                },
                .init(
                    icon: "gearshape",
                    activeIcon: "gearshape.fill",
                    color: .secondary,
                    activeColor: .blue,
                    isActive: settingsActive
                ) {
                    showSettings = true
                }
            ]
        )
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                NetworkFilterTab(
                    label: "All",
                    count: networkManager.requests.count,
                    isSelected: filterType == nil && !showErrorsOnly
                ) {
                    filterType = nil
                    showErrorsOnly = false
                }

                ForEach(NetworkRequest.RequestType.allCases, id: \.self) { type in
                    NetworkFilterTab(
                        label: type.label,
                        count: networkManager.requests.filter { $0.requestType == type }.count,
                        isSelected: filterType == type && !showErrorsOnly
                    ) {
                        filterType = type
                        showErrorsOnly = false
                    }
                }

                NetworkFilterTab(
                    label: "Errors",
                    count: networkManager.errorCount,
                    isSelected: showErrorsOnly,
                    color: .red
                ) {
                    filterType = nil
                    showErrorsOnly = true
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 36)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "network")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text(networkManager.requests.isEmpty ? "No requests" : "No matches")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !networkManager.isCapturing {
                Label("Paused", systemImage: "pause.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Request List

    private var requestList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredRequests) { request in
                        NetworkRequestRow(request: request)
                            .id(request.id)
                            .onTapGesture {
                                selectedRequest = request
                            }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemBackground))
            .scrollContentBackground(.hidden)
            .onChange(of: networkManager.requests.count) { _, _ in
                if let lastRequest = filteredRequests.last {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(lastRequest.id, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Export

    private func exportAsText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"

        // Build header with filter info
        var header = "Network Log Export"
        if let filterType {
            header += " (Filter: \(filterType.label))"
        }
        if !searchText.isEmpty {
            header += " (Search: \(searchText))"
        }
        header += "\nExported: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))"
        header += "\nTotal: \(filteredRequests.count) requests"
        header += "\n" + String(repeating: "─", count: 50) + "\n\n"

        let body = filteredRequests
            .map { req in
                var line = "[\(dateFormatter.string(from: req.startTime))] \(req.method) \(req.url)"
                if let status = req.status {
                    line += " → \(status)"
                }
                if let duration = req.duration {
                    line += " (\(String(format: "%.0fms", duration * 1000)))"
                }
                if let error = req.error {
                    line += " ERROR: \(error)"
                }
                return line
            }
            .joined(separator: "\n\n")

        return header + body
    }
}

// MARK: - Network Filter Tab

private struct NetworkFilterTab: View {
    let label: String
    let count: Int
    let isSelected: Bool
    var color: Color = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                if count != 0 {  // swiftlint:disable:this empty_count
                    Text("\(count)")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ? color.opacity(0.2) : Color.secondary.opacity(0.15),
                            in: Capsule()
                        )
                }
            }
            .foregroundStyle(isSelected ? color : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle()
                        .fill(color)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Network Request Row

private struct NetworkRequestRow: View {
    let request: NetworkRequest

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Status indicator
            Circle()
                .fill(request.isPending ? Color.orange : request.statusColor)
                .frame(width: 8, height: 8)

            // Method badge
            Text(request.method)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(methodColor, in: RoundedRectangle(cornerRadius: 4))

            // URL
            VStack(alignment: .leading, spacing: 2) {
                Text(request.path)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(request.host)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Right side info
            VStack(alignment: .trailing, spacing: 2) {
                // Status code or pending
                if let status = request.status {
                    Text("\(status)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(request.statusColor)
                } else if request.error != nil {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                } else {
                    ProgressView()
                        .scaleEffect(0.6)
                }

                // Duration
                Text(request.durationText)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            // Response content type
            Text(request.responseContentType)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(request.responseContentTypeColor)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(request.error != nil ? Color.red.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, 12)
        }
    }

    private var methodColor: Color {
        switch request.method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .secondary
        }
    }
}

// MARK: - Network Settings Sheet

private struct NetworkSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("networkPreserveLog") private var preserveLog: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Logging") {
                    Toggle("Preserve Log on Reload", isOn: $preserveLog)
                }
            }
            .navigationTitle("Network Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let manager = NetworkManager()
    manager.addRequest(
        id: UUID().uuidString,
        method: "GET",
        url: "https://api.example.com/users",
        requestType: "fetch",
        headers: ["Authorization": "Bearer token123"],
        body: nil
    )

    return NetworkView(networkManager: manager)
        .presentationDetents([.fraction(0.35), .medium, .large])
}
