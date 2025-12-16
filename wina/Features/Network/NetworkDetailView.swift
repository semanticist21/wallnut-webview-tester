//
//  NetworkDetailView.swift
//  wina
//
//  Network request detail view with headers, request, and response tabs.
//

import SwiftSoup
import SwiftUI
import SwiftUIBackports

// MARK: - Network Detail View

struct NetworkDetailView: View {
    let request: NetworkRequest
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DetailTab = .headers
    @State private var copiedFeedback: String?
    @State private var shareItem: NetworkShareContent?
    @State private var shareFileURL: URL?

    // Response search state
    @State private var responseSearchText: String = ""
    @State private var currentMatchIndex: Int = 0
    @State private var totalMatches: Int = 0

    // URL expand/collapse state
    @State private var isURLExpanded: Bool = false
    private let urlCollapseThreshold = 80

    enum DetailTab: String, CaseIterable {
        case headers = "Headers"
        case request = "Request"
        case response = "Response"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                requestSummary

                Divider()

                Picker("Tab", selection: $selectedTab) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    switch selectedTab {
                    case .headers:
                        headersContent
                    case .request:
                        requestContent
                    case .response:
                        responseContent
                    }
                }
            }
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        shareRequest()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let feedback = copiedFeedback {
                    CopiedFeedbackToast(message: feedback)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: copiedFeedback)
            .sheet(item: $shareItem) { item in
                NetworkShareSheet(content: item.content)
            }
            .sheet(item: $shareFileURL) { url in
                NetworkFileShareSheet(fileURL: url)
            }
        }
    }

    // MARK: - Summary

    private var isURLLong: Bool {
        request.url.count > urlCollapseThreshold
    }

    private var requestSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(request.method)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(methodColor, in: RoundedRectangle(cornerRadius: 6))

                if let status = request.status {
                    Text("\(status)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(request.statusColor)
                }

                Text(request.durationText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer()

                // Quick copy URL button
                CopyIconButton(text: request.url) {
                    showCopiedFeedback("URL")
                }
            }

            // Collapsible URL with selectable text
            if isURLLong {
                VStack(alignment: .leading, spacing: 4) {
                    if isURLExpanded {
                        SelectableTextView(
                            text: request.url,
                            font: .monospacedSystemFont(ofSize: 12, weight: .regular),
                            padding: .zero
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(String(request.url.prefix(urlCollapseThreshold)) + "...")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.primary)
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isURLExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isURLExpanded ? "Show less" : "Show full URL")
                                .font(.system(size: 11, weight: .medium))
                            Image(systemName: isURLExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                }
            } else {
                SelectableTextView(
                    text: request.url,
                    font: .monospacedSystemFont(ofSize: 12, weight: .regular),
                    padding: .zero
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Mixed Content warning
            if request.isMixedContent {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text("Mixed Content")
                        .font(.system(size: 12, weight: .medium))
                    Text("– insecure request on secure page")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            }

            if let error = request.error {
                Text("Error: \(error)")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
    }

    // MARK: - Headers Tab

    @ViewBuilder
    private var headersContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // General info section
            DetailSection(title: "General", rawText: generalRawText, onCopy: copyToClipboard) {
                DetailTableRow(key: "Request URL", value: request.url, onCopy: copyToClipboard)
                DetailTableRow(key: "Request Method", value: request.method, onCopy: copyToClipboard)
                if let status = request.status, let statusText = request.statusText {
                    DetailTableRow(key: "Status Code", value: "\(status) \(statusText)", onCopy: copyToClipboard)
                } else if let status = request.status {
                    DetailTableRow(key: "Status Code", value: "\(status)", onCopy: copyToClipboard)
                }
                DetailTableRow(
                    key: "Type",
                    value: request.requestType.rawValue.capitalized,
                    onCopy: copyToClipboard,
                    showBorder: false
                )
            }

            // Response headers
            if let headers = request.responseHeaders, !headers.isEmpty {
                let sortedHeaders = headers.sorted(by: { $0.key.lowercased() < $1.key.lowercased() })
                DetailSection(
                    title: "Response Headers",
                    rawText: formatHeadersForCopy(headers),
                    onCopy: copyToClipboard
                ) {
                    ForEach(Array(sortedHeaders.enumerated()), id: \.element.key) { index, pair in
                        DetailTableRow(
                            key: pair.key,
                            value: pair.value,
                            onCopy: copyToClipboard,
                            showBorder: index < sortedHeaders.count - 1
                        )
                    }
                }
            }

            // Request headers
            if let headers = request.requestHeaders, !headers.isEmpty {
                let sortedHeaders = headers.sorted(by: { $0.key.lowercased() < $1.key.lowercased() })
                DetailSection(
                    title: "Request Headers",
                    rawText: formatHeadersForCopy(headers),
                    onCopy: copyToClipboard
                ) {
                    ForEach(Array(sortedHeaders.enumerated()), id: \.element.key) { index, pair in
                        DetailTableRow(
                            key: pair.key,
                            value: pair.value,
                            onCopy: copyToClipboard,
                            showBorder: index < sortedHeaders.count - 1
                        )
                    }
                }
            }

            if request.requestHeaders == nil && request.responseHeaders == nil {
                emptyState(message: "No headers available")
            }
        }
        .padding()
    }

    private var generalRawText: String {
        var lines: [String] = []
        lines.append("Request URL: \(request.url)")
        lines.append("Request Method: \(request.method)")
        if let status = request.status, let statusText = request.statusText {
            lines.append("Status Code: \(status) \(statusText)")
        } else if let status = request.status {
            lines.append("Status Code: \(status)")
        }
        lines.append("Type: \(request.requestType.rawValue.capitalized)")
        return lines.joined(separator: "\n")
    }

    // MARK: - Request Tab

    @ViewBuilder
    private var requestContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // URL breakdown
            if let urlComponents = URLComponents(string: request.url) {
                DetailSection(title: "URL", rawText: urlRawText(urlComponents), onCopy: copyToClipboard) {
                    if let scheme = urlComponents.scheme {
                        DetailTableRow(key: "Scheme", value: scheme, onCopy: copyToClipboard)
                    }
                    if let host = urlComponents.host {
                        DetailTableRow(key: "Host", value: host, onCopy: copyToClipboard)
                    }
                    if let port = urlComponents.port {
                        DetailTableRow(key: "Port", value: "\(port)", onCopy: copyToClipboard)
                    }
                    DetailTableRow(
                        key: "Path",
                        value: urlComponents.path.isEmpty ? "/" : urlComponents.path,
                        onCopy: copyToClipboard,
                        showBorder: false
                    )
                }

                // Query parameters
                if let queryItems = urlComponents.queryItems, !queryItems.isEmpty {
                    DetailSection(
                        title: "Query Parameters",
                        rawText: queryParametersRawText(queryItems),
                        onCopy: copyToClipboard
                    ) {
                        ForEach(Array(queryItems.enumerated()), id: \.element.name) { index, item in
                            DetailTableRow(
                                key: item.name,
                                value: item.value ?? "(empty)",
                                onCopy: copyToClipboard,
                                showBorder: index < queryItems.count - 1
                            )
                        }
                    }
                }
            }

            // Request body
            if let body = request.requestBody, !body.isEmpty {
                let contentType = detectContentType(body: body, headers: request.requestHeaders)
                let bodySize = body.data(using: .utf8)?.count ?? 0
                DetailSection(title: "Request Body", rawText: body, onCopy: copyToClipboard) {
                    BodyHeaderView(contentType: contentType, size: bodySize)
                    FormattedBodyView(bodyText: body, contentType: contentType)
                }
            } else {
                emptyState(message: "No request body")
            }
        }
        .padding()
    }

    private func urlRawText(_ components: URLComponents) -> String {
        var lines: [String] = []
        if let scheme = components.scheme {
            lines.append("Scheme: \(scheme)")
        }
        if let host = components.host {
            lines.append("Host: \(host)")
        }
        if let port = components.port {
            lines.append("Port: \(port)")
        }
        lines.append("Path: \(components.path.isEmpty ? "/" : components.path)")
        return lines.joined(separator: "\n")
    }

    private func queryParametersRawText(_ items: [URLQueryItem]) -> String {
        items.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
    }

    // MARK: - Response Tab

    @ViewBuilder
    private var responseContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let body = request.responseBody, !body.isEmpty {
                // Search bar
                ResponseSearchBar(
                    searchText: $responseSearchText,
                    currentMatch: currentMatchIndex,
                    totalMatches: totalMatches,
                    onPrevious: {
                        if totalMatches > 0 {
                            currentMatchIndex = (currentMatchIndex - 1 + totalMatches) % totalMatches
                        }
                    },
                    onNext: {
                        if totalMatches > 0 {
                            currentMatchIndex = (currentMatchIndex + 1) % totalMatches
                        }
                    }
                )
                .onChange(of: responseSearchText) { _, _ in
                    currentMatchIndex = 0
                }

                VStack(alignment: .leading, spacing: 20) {
                    let contentType = detectContentType(body: body, headers: request.responseHeaders)
                    let bodySize = body.data(using: .utf8)?.count ?? 0
                    DetailSection(
                        title: "Response Body",
                        rawText: body,
                        onCopy: copyToClipboard,
                        onShare: {
                            shareResponseBodyAsFile(body: body, contentType: contentType)
                        },
                        content: {
                            BodyHeaderView(contentType: contentType, size: bodySize)
                            FormattedBodyView(
                                bodyText: body,
                                contentType: contentType,
                                searchText: responseSearchText,
                                currentMatchIndex: currentMatchIndex,
                                onMatchCountChanged: { count in
                                    totalMatches = count
                                }
                            )
                        }
                    )
                }
                .padding()
            } else {
                SecurityRestrictionBanner(type: .staticResourceBody)
                    .padding()
            }
        }
    }

    // MARK: - Helpers

    private func emptyState(message: String, subtitle: String? = nil) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "eye.slash")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 40)
    }

    private func copyToClipboard(_ text: String, label: String) {
        UIPasteboard.general.string = text
        showCopiedFeedback(label)
    }

    private func showCopiedFeedback(_ label: String) {
        copiedFeedback = "\(label) copied"
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                if copiedFeedback == "\(label) copied" {
                    copiedFeedback = nil
                }
            }
        }
    }

    private func formatHeadersForCopy(_ headers: [String: String]) -> String {
        headers
            .sorted(by: { $0.key.lowercased() < $1.key.lowercased() })
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
    }

    private func shareRequest() {
        var text = """
        \(request.method) \(request.url)
        Status: \(request.status.map { "\($0)" } ?? "Pending")
        Duration: \(request.durationText)
        Type: \(request.requestType.rawValue.capitalized)
        """

        if let headers = request.requestHeaders, !headers.isEmpty {
            text += "\n\n--- Request Headers ---\n"
            text += formatHeadersForCopy(headers)
        }

        if let body = request.requestBody, !body.isEmpty {
            text += "\n\n--- Request Body ---\n"
            text += body
        }

        if let headers = request.responseHeaders, !headers.isEmpty {
            text += "\n\n--- Response Headers ---\n"
            text += formatHeadersForCopy(headers)
        }

        if let body = request.responseBody, !body.isEmpty {
            text += "\n\n--- Response Body ---\n"
            text += body
        }

        shareItem = NetworkShareContent(content: text)
    }

    private func shareResponseBodyAsFile(body: String, contentType: NetworkContentType) {
        // Determine file extension based on content type
        let fileExtension: String
        switch contentType {
        case .json:
            fileExtension = "json"
        case .html:
            fileExtension = "html"
        case .xml:
            fileExtension = "xml"
        case .formUrlEncoded, .text:
            fileExtension = "txt"
        }

        // Build filename: host_path_timestamp.ext
        let host = request.host
            .replacingOccurrences(of: "www.", with: "")
            .replacingOccurrences(of: ".", with: "_")
        let pathComponent = request.path.split(separator: "/").last.map(String.init) ?? "response"
        let sanitizedPath = pathComponent.replacingOccurrences(
            of: "[^a-zA-Z0-9_-]",
            with: "_",
            options: .regularExpression
        )
        let timestamp = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HHmmss"
            return formatter.string(from: Date())
        }()
        let fileName = "\(host)_\(sanitizedPath)_\(timestamp).\(fileExtension)"

        // Write to temp directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try body.write(to: fileURL, atomically: true, encoding: .utf8)
            shareFileURL = fileURL
        } catch {
            // Fallback to text share if file creation fails
            shareItem = NetworkShareContent(content: body)
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

    private func detectContentType(body: String, headers: [String: String]?) -> NetworkContentType {
        // Check Content-Type header first
        if let contentTypeHeader = headers?["Content-Type"] ?? headers?["content-type"] {
            if contentTypeHeader.contains("application/json") {
                return .json
            } else if contentTypeHeader.contains("text/html") {
                return .html
            } else if contentTypeHeader.contains("text/xml") || contentTypeHeader.contains("application/xml") {
                return .xml
            } else if contentTypeHeader.contains("text/plain") {
                return .text
            } else if contentTypeHeader.contains("application/x-www-form-urlencoded") {
                return .formUrlEncoded
            }
        }

        // Fallback: detect from body content
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            // Validate JSON
            if let data = body.data(using: .utf8),
               (try? JSONSerialization.jsonObject(with: data)) != nil {
                return .json
            }
        }
        if trimmed.hasPrefix("<!DOCTYPE") || trimmed.hasPrefix("<html") {
            return .html
        }
        if trimmed.hasPrefix("<?xml") || trimmed.hasPrefix("<") {
            return .xml
        }
        if trimmed.contains("=") && trimmed.contains("&") {
            return .formUrlEncoded
        }
        return .text
    }
}

// MARK: - Detail Section

struct DetailSection<Content: View>: View {
    let title: String
    let rawText: String?
    var onCopy: ((String, String) -> Void)?
    var onShare: (() -> Void)?
    @ViewBuilder let content: () -> Content
    @State private var showRaw: Bool = false

    init(
        title: String,
        rawText: String? = nil,
        onCopy: ((String, String) -> Void)? = nil,
        onShare: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.rawText = rawText
        self.onCopy = onCopy
        self.onShare = onShare
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header with Raw toggle, Share, and Copy buttons
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if let rawText, !rawText.isEmpty {
                    // Raw/Table toggle button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showRaw.toggle()
                        }
                    } label: {
                        Text(showRaw ? "Table" : "Raw")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .backport.glassEffect(in: .capsule)

                    // Share button (optional)
                    if let onShare {
                        GlassIconButton(
                            icon: "square.and.arrow.up",
                            size: .small,
                            accessibilityLabel: "Share"
                        ) {
                            onShare()
                        }
                    }

                    // Copy button
                    GlassIconButton(
                        icon: "doc.on.doc",
                        size: .small,
                        accessibilityLabel: "Copy to clipboard"
                    ) {
                        onCopy?(rawText, title)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                if showRaw, let rawText {
                    // Raw text view with UITextView for proper text selection
                    SelectableTextView(text: rawText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    content()
                }
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Detail Table Row

struct DetailTableRow: View {
    let key: String
    let value: String
    var onCopy: ((String, String) -> Void)?
    var showBorder: Bool = true
    @State private var isExpanded: Bool = false

    init(key: String, value: String, onCopy: ((String, String) -> Void)? = nil, showBorder: Bool = true) {
        self.key = key
        self.value = value
        self.onCopy = onCopy
        self.showBorder = showBorder
    }

    private var isLongValue: Bool {
        value.count > 60 || value.contains("\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 12) {
                Text(key)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.blue)
                    .frame(width: 100, alignment: .leading)
                    .fixedSize(horizontal: true, vertical: false)

                if isLongValue && !isExpanded {
                    Text(value.replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(value)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isLongValue {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .frame(width: 16)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isLongValue {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if showBorder {
                Divider()
                    .background(Color(uiColor: .separator))
            }
        }
        .contextMenu {
            Button {
                onCopy?(value, key)
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
        }
    }
}

// MARK: - Body Header View

struct BodyHeaderView: View {
    let contentType: NetworkContentType
    let size: Int

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            contentType.badge

            Text(formatBytes(size))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(uiColor: .tertiarySystemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

// MARK: - Response Search Bar

struct ResponseSearchBar: View {
    @Binding var searchText: String
    let currentMatch: Int
    let totalMatches: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    private var hasMatches: Bool { !searchText.isEmpty && totalMatches > 0 }

    var body: some View {
        HStack(spacing: 8) {
            // Search input field - fixed height to prevent layout shift on focus
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                TextField("Search in response...", text: $searchText)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Placeholder to maintain consistent width
                    Color.clear
                        .frame(width: 14, height: 14)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(Color(uiColor: .tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

            // Fixed-width navigation area to prevent layout shift
            HStack(spacing: 4) {
                if hasMatches {
                    Text("\(currentMatch + 1)/\(totalMatches)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else if !searchText.isEmpty {
                    Text("0/0")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }

                Button(action: onPrevious) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!hasMatches)

                Button(action: onNext) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!hasMatches)
            }
            .foregroundStyle(hasMatches ? .primary : .tertiary)
            .frame(width: 110, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

// MARK: - Formatted Body View

struct FormattedBodyView: View {
    let bodyText: String
    let contentType: NetworkContentType
    var searchText: String = ""
    var currentMatchIndex: Int = 0
    var onMatchCountChanged: ((Int) -> Void)?
    @State private var showTreeView: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // JSON: Show tree/raw toggle and appropriate view
            if contentType == .json && searchText.isEmpty {
                // Toggle between Tree and Raw view
                HStack {
                    Spacer()
                    Picker("View Mode", selection: $showTreeView) {
                        Text("Tree").tag(true)
                        Text("Raw").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    .padding(.trailing, 12)
                    .padding(.top, 8)
                }

                if showTreeView {
                    JSONTreeView(jsonString: bodyText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    SelectableTextView(text: formattedBody)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if !searchText.isEmpty {
                SearchableTextView(
                    text: formattedBody,
                    searchText: searchText,
                    currentMatchIndex: currentMatchIndex,
                    onMatchCountChanged: onMatchCountChanged
                )
                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 400, alignment: .leading)
            } else {
                SelectableTextView(text: formattedBody)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var formattedBody: String {
        switch contentType {
        case .json:
            return formatJSON(bodyText)
        case .html, .xml:
            return formatMarkup(bodyText)
        case .formUrlEncoded:
            return formatFormData(bodyText)
        case .text:
            return bodyText
        }
    }

    private func formatJSON(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(
                  withJSONObject: jsonObject,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return jsonString
        }
        return prettyString
    }

    private func formatMarkup(_ markup: String) -> String {
        // Try to use SwiftSoup for HTML parsing
        do {
            let document = try SwiftSoup.parse(markup)
            // Use SwiftSoup's output settings for indentation
            document.outputSettings()
                .indentAmount(indentAmount: 2)
                .outline(outlineMode: false)
            let formatted = try document.html()
            return formatted
        } catch {
            // Fallback to manual formatting if SwiftSoup fails
            return formatMarkupManual(markup)
        }
    }

    private func formatMarkupManual(_ markup: String) -> String {
        var result = ""
        var indentLevel = 0
        let indentString = "  "

        // Normalize: add newlines around tags
        let normalized = markup
            .replacingOccurrences(of: ">", with: ">\n")
            .replacingOccurrences(of: "<", with: "\n<")

        let lines = normalized.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for line in lines {
            // Check if it's a closing tag
            if line.hasPrefix("</") {
                indentLevel = max(0, indentLevel - 1)
                result += String(repeating: indentString, count: indentLevel) + line + "\n"
            }
            // Self-closing tag or DOCTYPE/comment
            else if line.hasSuffix("/>") ||
                        line.hasPrefix("<!") ||
                        line.hasPrefix("<?") {
                result += String(repeating: indentString, count: indentLevel) + line + "\n"
            }
            // Opening tag
            else if line.hasPrefix("<") && !line.hasPrefix("</") {
                result += String(repeating: indentString, count: indentLevel) + line + "\n"
                // Don't indent for void elements
                let voidElements = [
                    "area", "base", "br", "col", "embed", "hr", "img",
                    "input", "link", "meta", "param", "source", "track", "wbr"
                ]
                let tagName = extractTagName(from: line)
                if !voidElements.contains(tagName.lowercased()) {
                    indentLevel += 1
                }
            }
            // Text content
            else {
                result += String(repeating: indentString, count: indentLevel) + line + "\n"
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractTagName(from tag: String) -> String {
        var name = tag
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "/", with: "")

        // Get just the tag name (before any attributes)
        if let spaceIndex = name.firstIndex(of: " ") {
            name = String(name[..<spaceIndex])
        }
        return name
    }

    private func formatFormData(_ formString: String) -> String {
        formString
            .components(separatedBy: "&")
            .map { pair -> String in
                let parts = pair.components(separatedBy: "=")
                let key = parts.first?.removingPercentEncoding ?? parts.first ?? ""
                let value = parts.count > 1 ? (parts[1].removingPercentEncoding ?? parts[1]) : ""
                return "\(key) = \(value)"
            }
            .joined(separator: "\n")
    }
}

// MARK: - Share Sheets

struct NetworkShareSheet: UIViewControllerRepresentable {
    let content: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [content], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct NetworkFileShareSheet: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
