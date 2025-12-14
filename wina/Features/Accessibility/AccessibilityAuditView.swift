//
//  AccessibilityAuditView.swift
//  wina
//
//  Accessibility audit tool for detecting a11y issues in web pages.
//

import SwiftUI

// MARK: - Accessibility Issue Model

struct AccessibilityIssue: Identifiable, Equatable {
    let id = UUID()
    let severity: Severity
    let category: Category
    let message: String
    let element: String  // Simplified element representation
    let selector: String?  // CSS selector for the element

    enum Severity: String, CaseIterable {
        case error
        case warning
        case info

        var icon: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }

        var label: String {
            switch self {
            case .error: return "Errors"
            case .warning: return "Warnings"
            case .info: return "Info"
            }
        }
    }

    enum Category: String, CaseIterable {
        case images
        case links
        case buttons
        case forms
        case headings
        case aria
        case contrast
        case other

        var icon: String {
            switch self {
            case .images: return "photo"
            case .links: return "link"
            case .buttons: return "hand.tap"
            case .forms: return "list.bullet.rectangle"
            case .headings: return "textformat.size"
            case .aria: return "accessibility"
            case .contrast: return "circle.lefthalf.filled"
            case .other: return "questionmark.circle"
            }
        }

        var label: String {
            switch self {
            case .images: return "Images"
            case .links: return "Links"
            case .buttons: return "Buttons"
            case .forms: return "Forms"
            case .headings: return "Headings"
            case .aria: return "ARIA"
            case .contrast: return "Contrast"
            case .other: return "Other"
            }
        }
    }
}

// MARK: - Accessibility Audit View

struct AccessibilityAuditView: View {
    let navigator: WebViewNavigator?

    @Environment(\.dismiss) private var dismiss
    @State private var issues: [AccessibilityIssue] = []
    @State private var isScanning: Bool = false
    @State private var hasScanned: Bool = false
    @State private var filterSeverity: AccessibilityIssue.Severity?
    @State private var searchText: String = ""

    private var filteredIssues: [AccessibilityIssue] {
        var result = issues

        if let severity = filterSeverity {
            result = result.filter { $0.severity == severity }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.message.localizedCaseInsensitiveContains(searchText)
                    || $0.element.localizedCaseInsensitiveContains(searchText)
                    || $0.category.label.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private var issueCountBySeverity: [AccessibilityIssue.Severity: Int] {
        Dictionary(grouping: issues, by: \.severity).mapValues(\.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            filterTabs

            Divider()

            if isScanning {
                scanningState
            } else if !hasScanned {
                initialState
            } else if filteredIssues.isEmpty {
                emptyState
            } else {
                issuesList
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        DevToolsHeader(
            title: "Accessibility",
            leftButtons: [
                .init(icon: "xmark.circle.fill", color: .secondary) {
                    dismiss()
                },
                .init(
                    icon: "trash",
                    isDisabled: issues.isEmpty || isScanning
                ) {
                    issues = []
                    hasScanned = false
                }
            ],
            rightButtons: [
                .init(
                    icon: "arrow.clockwise",
                    isDisabled: isScanning
                ) {
                    Task { await runAudit() }
                }
            ]
        )
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter issues", text: $searchText)
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
                FilterTab(
                    label: "All",
                    count: issues.count,
                    isSelected: filterSeverity == nil
                ) {
                    filterSeverity = nil
                }

                ForEach(AccessibilityIssue.Severity.allCases, id: \.self) { severity in
                    FilterTab(
                        label: severity.label,
                        count: issueCountBySeverity[severity] ?? 0,
                        isSelected: filterSeverity == severity,
                        color: severity.color
                    ) {
                        filterSeverity = severity
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 36)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    // MARK: - States

    private var initialState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "accessibility")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Accessibility Audit")
                .font(.headline)
            Text("Scan the current page for accessibility issues")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GlassActionButton("Run Audit", icon: "play.fill", style: .primary) {
                Task { await runAudit() }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    private var scanningState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Scanning...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)
            Text(issues.isEmpty ? "No issues found" : "No matching issues")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if issues.isEmpty {
                Text("Great! This page passes basic accessibility checks.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Issues List

    private var issuesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredIssues) { issue in
                    IssueRow(issue: issue)
                }
            }
        }
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Audit Logic

    private func runAudit() async {
        guard let navigator else { return }

        isScanning = true
        issues = []

        let script = AccessibilityAuditScripts.fullAudit

        if let result = await navigator.evaluateJavaScript(script) as? String,
           let data = result.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            issues = parseIssues(from: parsed)
        }

        isScanning = false
        hasScanned = true
    }

    private func parseIssues(from jsonArray: [[String: Any]]) -> [AccessibilityIssue] {
        return jsonArray.compactMap { item -> AccessibilityIssue? in
            guard let severityStr = item["severity"] as? String,
                  let categoryStr = item["category"] as? String,
                  let message = item["message"] as? String,
                  let element = item["element"] as? String else {
                return nil
            }

            let severity = AccessibilityIssue.Severity(rawValue: severityStr) ?? .info
            let category = AccessibilityIssue.Category(rawValue: categoryStr) ?? .other
            let selector = item["selector"] as? String

            return AccessibilityIssue(
                severity: severity,
                category: category,
                message: message,
                element: element,
                selector: selector
            )
        }
    }
}

// MARK: - Filter Tab

private struct FilterTab: View {
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

// MARK: - Issue Row

private struct IssueRow: View {
    let issue: AccessibilityIssue

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Severity icon
            Image(systemName: issue.severity.icon)
                .font(.system(size: 14))
                .foregroundStyle(issue.severity.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                // Category badge + message
                HStack(spacing: 6) {
                    Label(issue.category.label, systemImage: issue.category.icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(issue.severity.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(issue.severity.color.opacity(0.15), in: Capsule())
                }

                // Message
                Text(issue.message)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)

                // Element
                Text(issue.element)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(issue.severity == .error ? Color.red.opacity(0.05) : Color.clear)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, 42)
        }
    }
}

// MARK: - Accessibility Audit Scripts

private enum AccessibilityAuditScripts {
    static let fullAudit = """
        (function() {
            const issues = [];

            function addIssue(severity, category, message, el, selector) {
                let elementStr = '';
                if (el) {
                    const tag = el.tagName.toLowerCase();
                    const id = el.id ? '#' + el.id : '';
                    const cls = el.className && typeof el.className === 'string'
                        ? '.' + el.className.split(' ').filter(c => c).slice(0, 2).join('.')
                        : '';
                    elementStr = '<' + tag + id + cls + '>';
                }
                issues.push({
                    severity: severity,
                    category: category,
                    message: message,
                    element: elementStr,
                    selector: selector || null
                });
            }

            // Check images without alt
            document.querySelectorAll('img').forEach((img, i) => {
                if (!img.hasAttribute('alt')) {
                    addIssue('error', 'images', 'Image missing alt attribute', img, 'img:nth-of-type(' + (i+1) + ')');
                } else if (img.alt.trim() === '' && !img.getAttribute('role')) {
                    addIssue('warning', 'images', 'Image has empty alt but no role="presentation"', img);
                }
            });

            // Check links without accessible name
            document.querySelectorAll('a').forEach((link, i) => {
                const text = link.textContent.trim();
                const ariaLabel = link.getAttribute('aria-label');
                const title = link.getAttribute('title');
                if (!text && !ariaLabel && !title && !link.querySelector('img[alt]')) {
                    addIssue('error', 'links', 'Link has no accessible name', link, 'a:nth-of-type(' + (i+1) + ')');
                }
            });

            // Check buttons without accessible name
            document.querySelectorAll('button, [role="button"]').forEach((btn, i) => {
                const text = btn.textContent.trim();
                const ariaLabel = btn.getAttribute('aria-label');
                const title = btn.getAttribute('title');
                if (!text && !ariaLabel && !title) {
                    addIssue('error', 'buttons', 'Button has no accessible name', btn);
                }
            });

            // Check form inputs without labels
            document.querySelectorAll('input, select, textarea').forEach((input, i) => {
                if (input.type === 'hidden' || input.type === 'submit' || input.type === 'button') return;
                const id = input.id;
                const ariaLabel = input.getAttribute('aria-label');
                const ariaLabelledby = input.getAttribute('aria-labelledby');
                const placeholder = input.getAttribute('placeholder');
                const hasLabel = id && document.querySelector('label[for="' + id + '"]');

                if (!hasLabel && !ariaLabel && !ariaLabelledby) {
                    const msg = placeholder
                        ? 'Form input relies only on placeholder for label'
                        : 'Form input has no associated label';
                    const severity = placeholder ? 'warning' : 'error';
                    addIssue(severity, 'forms', msg, input);
                }
            });

            // Check heading structure
            const headings = Array.from(document.querySelectorAll('h1, h2, h3, h4, h5, h6'));
            let prevLevel = 0;
            let h1Count = 0;
            headings.forEach((h, i) => {
                const level = parseInt(h.tagName[1]);
                if (level === 1) h1Count++;
                if (prevLevel > 0 && level > prevLevel + 1) {
                    addIssue('warning', 'headings', 'Heading level skipped from h' + prevLevel + ' to h' + level, h);
                }
                prevLevel = level;
            });
            if (h1Count === 0) {
                addIssue('warning', 'headings', 'Page has no h1 heading', null);
            } else if (h1Count > 1) {
                addIssue('info', 'headings', 'Page has multiple h1 headings (' + h1Count + ')', null);
            }

            // Check ARIA issues
            document.querySelectorAll('[aria-hidden="true"]').forEach(el => {
                if (el.querySelector('a, button, input, [tabindex]:not([tabindex="-1"])')) {
                    addIssue('error', 'aria', 'aria-hidden contains focusable elements', el);
                }
            });

            document.querySelectorAll('[role]').forEach(el => {
                const role = el.getAttribute('role');
                const invalidRoles = ['presentation', 'none'];
                if (invalidRoles.includes(role) && el.hasAttribute('tabindex') && el.tabIndex >= 0) {
                    addIssue('warning', 'aria', 'Element with role="' + role + '" should not be focusable', el);
                }
            });

            // Check for missing lang attribute
            if (!document.documentElement.hasAttribute('lang')) {
                addIssue('error', 'other', 'Document missing lang attribute on <html>', document.documentElement);
            }

            // Check for autoplaying media
            document.querySelectorAll('video, audio').forEach(media => {
                if (media.autoplay && !media.muted) {
                    addIssue('warning', 'other', 'Autoplaying media without muted attribute', media);
                }
            });

            return JSON.stringify(issues);
        })();
    """
}

#Preview {
    AccessibilityAuditView(navigator: WebViewNavigator())
}
