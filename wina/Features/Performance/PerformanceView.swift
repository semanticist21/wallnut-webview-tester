//
//  PerformanceView.swift
//  wina
//
//  Performance panel with Web Vitals 2025.
//

import SwiftUI

// MARK: - Performance View

struct PerformanceView: View {
    let performanceManager: PerformanceManager
    let onCollect: () -> Void
    let onReload: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var expandedTypes: Set<ResourceType> = []

    private var hasData: Bool {
        performanceManager.data.navigation != nil || !performanceManager.data.paints.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            performanceHeader

            List {
                if hasData {
                    coreWebVitalsSection
                    tabPickerSection
                    tabContentSection
                } else if performanceManager.lastError != nil {
                    errorSection
                } else {
                    emptySection
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemBackground))
        }
        .onAppear {
            if !hasData {
                onCollect()
            }
        }
    }

    // MARK: - Header

    private var performanceHeader: some View {
        DevToolsHeader(
            title: "Performance",
            leftButtons: [
                .init(icon: "xmark.circle.fill", color: .secondary) {
                    dismiss()
                },
                .init(icon: "trash", isDisabled: !hasData) {
                    performanceManager.clear()
                }
            ],
            rightButtons: [
                .init(
                    icon: performanceManager.isLoading ? "hourglass" : "arrow.clockwise",
                    isDisabled: performanceManager.isLoading
                ) {
                    onReload()
                }
            ]
        )
    }

    // MARK: - Core Web Vitals Section (2025 Bento Grid Style)

    @ViewBuilder
    private var coreWebVitalsSection: some View {
        Section {
            VStack(spacing: 16) {
                overallScoreCard
                coreVitalsGrid
                coreVitalsStatus
            }
            .padding(.vertical, 8)
        }
    }

    private var overallScoreCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: CGFloat(performanceManager.data.totalScore) / 100)
                    .stroke(
                        performanceManager.data.scoreRating.color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("\(performanceManager.data.totalScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(performanceManager.data.scoreRating.color)
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: performanceManager.data.scoreRating.icon)
                    Text(performanceManager.data.scoreRating.rawValue)
                }
                .font(.headline)
                .foregroundStyle(performanceManager.data.scoreRating.color)

                Text("Web Vitals 2025")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if performanceManager.data.navigation != nil {
                    Text("Measured at \(formatTimestamp(performanceManager.data.timestamp))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
    }

    private var coreVitalsGrid: some View {
        HStack(spacing: 12) {
            CoreVitalCard(
                label: "LCP",
                value: formatLCP(performanceManager.data.largestContentfulPaint),
                rating: performanceManager.data.lcpRating,
                description: "Largest Contentful Paint"
            )
            CoreVitalCard(
                label: "CLS",
                value: formatCLS(performanceManager.data.cls),
                rating: performanceManager.data.clsRating,
                description: "Cumulative Layout Shift"
            )
        }
    }

    private var coreVitalsStatus: some View {
        let passed = performanceManager.data.coreWebVitalsPass

        return HStack(spacing: 8) {
            Image(systemName: passed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(passed ? .green : .orange)

            Text(passed ? "Passed Core Web Vitals" : "Needs Improvement")
                .font(.caption.weight(.medium))
                .foregroundStyle(passed ? .green : .orange)

            Spacer()

            Text("LCP + CLS")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Tab Picker

    @ViewBuilder
    private var tabPickerSection: some View {
        Section {
            Picker("View", selection: $selectedTab) {
                Text("Metrics").tag(0)
                Text("Resources").tag(1)
                Text("Timing").tag(2)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
    }

    @ViewBuilder
    private var tabContentSection: some View {
        switch selectedTab {
        case 0: metricsSection
        case 1: resourcesSection
        case 2: timingSection
        default: EmptyView()
        }
    }

    // MARK: - Metrics Section

    @ViewBuilder
    private var metricsSection: some View {
        Section("Loading Performance") {
            if let fcp = performanceManager.data.firstContentfulPaint {
                MetricRow(
                    label: "First Contentful Paint",
                    value: fcp,
                    rating: MetricThresholds.rate(fcp, good: MetricThresholds.fcpGood, poor: MetricThresholds.fcpPoor)
                )
            }

            if let nav = performanceManager.data.navigation {
                MetricRow(
                    label: "Time to First Byte",
                    value: nav.ttfb,
                    rating: MetricThresholds.rate(nav.ttfb, good: MetricThresholds.ttfbGood, poor: MetricThresholds.ttfbPoor),
                    threshold: "≤ 200ms"
                )

                MetricRow(
                    label: "DOM Content Loaded",
                    value: nav.domContentLoadedTime,
                    rating: MetricThresholds.rate(
                        nav.domContentLoadedTime,
                        good: MetricThresholds.dclGood,
                        poor: MetricThresholds.dclPoor
                    )
                )

                MetricRow(
                    label: "Page Load",
                    value: nav.loadEventTime,
                    rating: MetricThresholds.rate(
                        nav.loadEventTime,
                        good: MetricThresholds.lcpGood,
                        poor: MetricThresholds.lcpPoor
                    )
                )
            }

            if performanceManager.data.tbt >= 0 {
                MetricRow(
                    label: "Total Blocking Time",
                    value: performanceManager.data.tbt,
                    rating: MetricThresholds.rate(
                        performanceManager.data.tbt,
                        good: MetricThresholds.tbtGood,
                        poor: MetricThresholds.tbtPoor
                    ),
                    threshold: "≤ 200ms"
                )
            }
        }

        Section("Network") {
            if let nav = performanceManager.data.navigation {
                MetricRow(
                    label: "DNS Lookup",
                    value: nav.dnsTime,
                    rating: MetricThresholds.rate(nav.dnsTime, good: MetricThresholds.dnsGood, poor: MetricThresholds.dnsPoor)
                )

                MetricRow(
                    label: "Connection (TCP+TLS)",
                    value: nav.connectionTime,
                    rating: MetricThresholds.rate(
                        nav.connectionTime,
                        good: MetricThresholds.connectGood,
                        poor: MetricThresholds.connectPoor
                    )
                )

                if nav.redirectTime > 0 {
                    MetricRow(
                        label: "Redirect",
                        value: nav.redirectTime,
                        rating: nav.redirectTime > 100 ? .needsImprovement : .good
                    )
                }
            }
        }

        Section {
            HStack {
                Label("Resources", systemImage: "doc.fill")
                Spacer()
                Text("\(performanceManager.data.totalResources)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("Total Transfer", systemImage: "arrow.down.circle.fill")
                Spacer()
                Text(formatBytes(performanceManager.data.totalTransferSize))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Resources Section

    @ViewBuilder
    private var resourcesSection: some View {
        Section {
            ForEach(resourceTypeSummary, id: \.type) { summary in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedTypes.contains(summary.type) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedTypes.insert(summary.type)
                            } else {
                                expandedTypes.remove(summary.type)
                            }
                        }
                    )
                ) {
                    ForEach(summary.resources.sorted(by: { $0.displaySize > $1.displaySize }).prefix(15)) { resource in
                        ResourceDetailRow(resource: resource)
                    }
                    if summary.resources.count > 15 {
                        Text("+ \(summary.resources.count - 15) more")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } label: {
                    HStack {
                        Text(summary.type.rawValue)

                        Spacer()

                        Text("\(summary.count)")
                            .foregroundStyle(.secondary)

                        Text(summary.size > 0 ? formatBytes(summary.size) : "—")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(summary.size > 0 ? .secondary : .tertiary)
                            .frame(width: 70, alignment: .trailing)
                    }
                }
            }
        } header: {
            HStack {
                Text("By Type")
                Spacer()
                Text(formatBytes(totalResourceSize))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Timing Section

    @ViewBuilder
    private var timingSection: some View {
        if let nav = performanceManager.data.navigation {
            Section("Navigation Breakdown") {
                TimingBreakdownRow(label: "Redirect", value: nav.redirectTime, total: nav.loadEventTime)
                TimingBreakdownRow(label: "DNS", value: nav.dnsTime, total: nav.loadEventTime)
                TimingBreakdownRow(label: "TCP", value: nav.tcpTime, total: nav.loadEventTime)
                TimingBreakdownRow(label: "TLS", value: nav.tlsTime, total: nav.loadEventTime)
                TimingBreakdownRow(label: "Request", value: nav.requestTime, total: nav.loadEventTime)
                TimingBreakdownRow(label: "Response", value: nav.responseTime, total: nav.loadEventTime)
                TimingBreakdownRow(label: "DOM Processing", value: nav.domProcessingTime, total: nav.loadEventTime)
            }

            Section("Timeline") {
                TimelineRow(label: "TTFB", time: nav.ttfb)
                if let fcp = performanceManager.data.firstContentfulPaint {
                    TimelineRow(label: "FCP", time: fcp)
                }
                TimelineRow(label: "DOM Ready", time: nav.domContentLoadedTime)
                TimelineRow(label: "Load", time: nav.loadEventTime)
            }
        }
    }

    // MARK: - Empty/Error Sections

    @ViewBuilder
    private var emptySection: some View {
        Section {
            VStack(spacing: 16) {
                if performanceManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)

                    VStack(spacing: 4) {
                        Text("Collecting Metrics")
                            .font(.headline)
                        Text("Analyzing page performance...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    VStack(spacing: 4) {
                        Text("No Performance Data")
                            .font(.headline)
                        Text("Navigate to a page to collect metrics")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("Failed to collect metrics")
                    .font(.headline)
                Text(performanceManager.lastError ?? "Unknown error")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }

    // MARK: - Helpers

    private var resourceTypeSummary: [(type: ResourceType, count: Int, size: Int, resources: [ResourceTiming])] {
        var summary: [ResourceType: (count: Int, size: Int, resources: [ResourceTiming])] = [:]
        for resource in performanceManager.data.resources {
            let type = resource.resourceType
            var current = summary[type] ?? (0, 0, [])
            current.count += 1
            current.size += resource.displaySize
            current.resources.append(resource)
            summary[type] = current
        }
        return ResourceType.allCases
            .compactMap { type in
                guard let data = summary[type] else { return nil }
                return (type, data.count, data.size, data.resources)
            }
            .sorted { $0.size > $1.size }
    }

    private var totalResourceSize: Int {
        performanceManager.data.resources.reduce(0) { $0 + $1.displaySize }
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes >= 1_000_000 {
            return String(format: "%.1f MB", Double(bytes) / 1_000_000)
        } else if bytes >= 1_000 {
            return String(format: "%.1f KB", Double(bytes) / 1_000)
        }
        return "\(bytes) B"
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatLCP(_ value: Double?) -> String {
        guard let value, value > 0 else { return "N/A" }
        return value >= 1000 ? String(format: "%.2fs", value / 1000) : String(format: "%.0fms", value)
    }

    private func formatCLS(_ value: Double) -> String {
        guard value >= 0 else { return "N/A" }
        return String(format: "%.3f", value)
    }
}

// MARK: - Preview

#Preview("Good Performance") {
    PerformanceView(
        performanceManager: {
            let manager = PerformanceManager()
            manager.data = PerformanceData(
                navigation: NavigationTiming(
                    startTime: 0,
                    redirectTime: 0,
                    dnsTime: 23,
                    tcpTime: 45,
                    tlsTime: 67,
                    requestTime: 50,
                    responseTime: 89,
                    domProcessingTime: 234,
                    domContentLoadedTime: 567,
                    loadEventTime: 1234
                ),
                resources: [
                    ResourceTiming(
                        id: UUID(), name: "https://example.com/script.js",
                        initiatorType: "script", startTime: 100, duration: 200,
                        transferSize: 45000, encodedBodySize: 45000, decodedBodySize: 120000
                    ),
                    ResourceTiming(
                        id: UUID(), name: "https://example.com/style.css",
                        initiatorType: "link", startTime: 50, duration: 150,
                        transferSize: 12000, encodedBodySize: 12000, decodedBodySize: 35000
                    )
                ],
                paints: [
                    PaintTiming(name: "first-paint", startTime: 345),
                    PaintTiming(name: "first-contentful-paint", startTime: 456)
                ],
                cls: 0.05,
                tbt: 150
            )
            return manager
        }(),
        onCollect: {},
        onReload: {}
    )
}
