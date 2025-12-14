//
//  PerformanceView.swift
//  wina
//
//  Created by Claude on 12/14/25.
//

import SwiftUI

// MARK: - Performance Score Rating

enum PerformanceRating: String {
    case good = "Good"
    case needsImprovement = "Needs Improvement"
    case poor = "Poor"
    case unknown = "N/A"

    var color: Color {
        switch self {
        case .good: .green
        case .needsImprovement: .orange
        case .poor: .red
        case .unknown: .secondary
        }
    }

    var icon: String {
        switch self {
        case .good: "checkmark.circle.fill"
        case .needsImprovement: "exclamationmark.circle.fill"
        case .poor: "xmark.circle.fill"
        case .unknown: "questionmark.circle"
        }
    }
}

// MARK: - Metric Thresholds (Google Web Vitals 2025)

struct MetricThresholds {
    // Core Web Vitals (Official 2025)
    // LCP: Largest Contentful Paint
    static let lcpGood: Double = 2500  // ≤ 2.5s
    static let lcpPoor: Double = 4000  // > 4s

    // Note: INP removed - Safari/WKWebView doesn't support Event Timing API (until 2026)

    // CLS: Cumulative Layout Shift (unitless)
    static let clsGood: Double = 0.1  // ≤ 0.1
    static let clsPoor: Double = 0.25  // > 0.25

    // Other Web Vitals
    // FCP: First Contentful Paint
    static let fcpGood: Double = 1800  // ≤ 1.8s
    static let fcpPoor: Double = 3000  // > 3s

    // TTFB: Time to First Byte (Google recommends ≤200ms)
    static let ttfbGood: Double = 200  // ≤ 200ms
    static let ttfbPoor: Double = 600  // > 600ms

    // TBT: Total Blocking Time
    static let tbtGood: Double = 200  // ≤ 200ms
    static let tbtPoor: Double = 600  // > 600ms

    // DOM Content Loaded
    static let dclGood: Double = 1500  // ≤ 1.5s
    static let dclPoor: Double = 3000  // > 3s

    // DNS Lookup
    static let dnsGood: Double = 50  // ≤ 50ms
    static let dnsPoor: Double = 200  // > 200ms

    // TCP/TLS Connection
    static let connectGood: Double = 100  // ≤ 100ms
    static let connectPoor: Double = 300  // > 300ms

    static func rate(_ value: Double, good: Double, poor: Double, isLowerBetter: Bool = true) -> PerformanceRating {
        if value < 0 { return .unknown }
        if isLowerBetter {
            if value <= good { return .good }
            if value < poor { return .needsImprovement }
            return .poor
        } else {
            if value >= good { return .good }
            if value > poor { return .needsImprovement }
            return .poor
        }
    }

    static func score(_ value: Double, good: Double, poor: Double, isLowerBetter: Bool = true) -> Int {
        if value < 0 { return 0 }
        if isLowerBetter {
            if value <= good { return 100 }
            if value >= poor { return 0 }
            let ratio = (poor - value) / (poor - good)
            return Int(ratio * 100)
        } else {
            if value >= good { return 100 }
            if value <= poor { return 0 }
            let ratio = (value - poor) / (good - poor)
            return Int(ratio * 100)
        }
    }
}

// MARK: - Navigation Timing

struct NavigationTiming: Codable, Equatable {
    let startTime: Double
    let redirectTime: Double
    let dnsTime: Double
    let tcpTime: Double
    let tlsTime: Double
    let requestTime: Double
    let responseTime: Double
    let domProcessingTime: Double
    let domContentLoadedTime: Double
    let loadEventTime: Double

    // TTFB = time from navigation start to first byte of response
    var ttfb: Double {
        requestTime + responseTime
    }

    // Connection time = TCP + TLS
    var connectionTime: Double {
        tcpTime + tlsTime
    }
}

// MARK: - Resource Timing

struct ResourceTiming: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let initiatorType: String
    let startTime: Double
    let duration: Double
    let transferSize: Int
    let encodedBodySize: Int
    let decodedBodySize: Int

    var resourceType: ResourceType {
        ResourceType.from(initiatorType: initiatorType, name: name)
    }

    var shortName: String {
        if let url = URL(string: name) {
            return url.lastPathComponent.isEmpty ? url.host() ?? name : url.lastPathComponent
        }
        return String(name.suffix(30))
    }

    /// Best available size (transferSize > encodedBodySize > decodedBodySize > 0)
    /// transferSize can be 0 for cached resources or cross-origin without CORS
    var displaySize: Int {
        if transferSize > 0 { return transferSize }
        if encodedBodySize > 0 { return encodedBodySize }
        if decodedBodySize > 0 { return decodedBodySize }
        return 0
    }
}

// MARK: - Resource Type

enum ResourceType: String, CaseIterable {
    case document = "Document"
    case script = "Script"
    case stylesheet = "Stylesheet"
    case image = "Image"
    case font = "Font"
    case fetch = "Fetch/XHR"
    case other = "Other"

    var icon: String {
        switch self {
        case .document: "doc.fill"
        case .script: "curlybraces"
        case .stylesheet: "paintbrush.fill"
        case .image: "photo.fill"
        case .font: "textformat"
        case .fetch: "arrow.down.circle.fill"
        case .other: "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .document: .blue
        case .script: .yellow
        case .stylesheet: .purple
        case .image: .green
        case .font: .orange
        case .fetch: .cyan
        case .other: .gray
        }
    }

    static func from(initiatorType: String, name: String) -> ResourceType {
        switch initiatorType.lowercased() {
        case "navigation": return .document
        case "script": return .script
        case "link", "css": return .stylesheet
        case "img", "image": return .image
        case "font": return .font
        case "fetch", "xmlhttprequest": return .fetch
        default:
            // Fallback to extension-based detection
            let ext = (name as NSString).pathExtension.lowercased()
            switch ext {
            case "js", "mjs": return .script
            case "css": return .stylesheet
            case "png", "jpg", "jpeg", "gif", "webp", "svg", "ico": return .image
            case "woff", "woff2", "ttf", "otf", "eot": return .font
            default: return .other
            }
        }
    }
}

// MARK: - Paint Timing

struct PaintTiming: Codable, Equatable {
    let name: String
    let startTime: Double
}

// MARK: - Performance Data

struct PerformanceData: Equatable {
    var navigation: NavigationTiming?
    var resources: [ResourceTiming] = []
    var paints: [PaintTiming] = []
    var timestamp = Date()

    // Core Web Vitals (2025)
    var cls: Double = -1  // Cumulative Layout Shift (unitless), -1 = not measured
    var tbt: Double = -1  // Total Blocking Time (ms), -1 = not measured

    var totalResources: Int { resources.count }
    var totalTransferSize: Int {
        resources.reduce(0) { $0 + $1.displaySize }
    }

    var firstContentfulPaint: Double? {
        paints.first { $0.name == "first-contentful-paint" }?.startTime
    }

    var firstPaint: Double? {
        paints.first { $0.name == "first-paint" }?.startTime
    }

    // LCP approximation from load event (real LCP requires PerformanceObserver)
    var largestContentfulPaint: Double? {
        navigation?.loadEventTime
    }

    // MARK: - Core Web Vitals Scores

    var lcpScore: Int {
        guard let lcp = largestContentfulPaint else { return 0 }
        return MetricThresholds.score(lcp, good: MetricThresholds.lcpGood, poor: MetricThresholds.lcpPoor)
    }

    var lcpRating: PerformanceRating {
        guard let lcp = largestContentfulPaint else { return .unknown }
        return MetricThresholds.rate(lcp, good: MetricThresholds.lcpGood, poor: MetricThresholds.lcpPoor)
    }

    var clsScore: Int {
        guard cls >= 0 else { return 0 }
        return MetricThresholds.score(cls, good: MetricThresholds.clsGood, poor: MetricThresholds.clsPoor)
    }

    var clsRating: PerformanceRating {
        guard cls >= 0 else { return .unknown }
        return MetricThresholds.rate(cls, good: MetricThresholds.clsGood, poor: MetricThresholds.clsPoor)
    }

    // MARK: - Overall Score (Core Web Vitals weighted)

    var totalScore: Int {
        var scores: [Int] = []
        var weights: [Int] = []

        // Core Web Vitals (higher weight) - LCP and CLS only
        // Note: INP not supported in Safari/WKWebView until 2026
        if largestContentfulPaint != nil {
            scores.append(lcpScore)
            weights.append(3)  // LCP weight: 3x
        }
        if cls >= 0 {
            scores.append(clsScore)
            weights.append(2)  // CLS weight: 2x
        }

        // Other vitals (lower weight)
        if let fcp = firstContentfulPaint {
            scores.append(MetricThresholds.score(fcp, good: MetricThresholds.fcpGood, poor: MetricThresholds.fcpPoor))
            weights.append(1)
        }
        if let nav = navigation {
            scores.append(MetricThresholds.score(nav.ttfb, good: MetricThresholds.ttfbGood, poor: MetricThresholds.ttfbPoor))
            weights.append(1)
        }

        guard !scores.isEmpty else { return 0 }

        let weightedSum = zip(scores, weights).reduce(0) { $0 + $1.0 * $1.1 }
        let totalWeight = weights.reduce(0, +)
        return weightedSum / totalWeight
    }

    var scoreRating: PerformanceRating {
        let score = totalScore
        if score == 0 { return .unknown }
        if score >= 90 { return .good }
        if score >= 50 { return .needsImprovement }
        return .poor
    }

    // Core Web Vitals pass/fail (LCP + CLS only)
    // Note: INP not supported in Safari/WKWebView until 2026
    var coreWebVitalsPass: Bool {
        lcpRating == .good && clsRating == .good
    }
}

// MARK: - Performance Manager

@Observable
class PerformanceManager {
    var data = PerformanceData()
    var isLoading: Bool = false
    var lastError: String?

    // JavaScript to inject PerformanceObservers at page load (for LCP, CLS)
    // Note: INP removed - Safari/WKWebView doesn't support Event Timing API (until 2026)
    static let observerInjectionScript = """
    (function() {
        if (window.__webVitals_initialized) return;
        window.__webVitals_initialized = true;

        // LCP tracking
        window.__webVitals_lcp = -1;
        try {
            new PerformanceObserver((list) => {
                const entries = list.getEntries();
                if (entries.length > 0) {
                    window.__webVitals_lcp = entries[entries.length - 1].startTime;
                }
            }).observe({ type: 'largest-contentful-paint', buffered: true });
        } catch (e) {}

        // CLS tracking
        window.__webVitals_cls = 0;
        try {
            new PerformanceObserver((list) => {
                for (const entry of list.getEntries()) {
                    if (!entry.hadRecentInput) {
                        window.__webVitals_cls += entry.value;
                    }
                }
            }).observe({ type: 'layout-shift', buffered: true });
        } catch (e) {}
    })();
    """

    // JavaScript to collect Performance API data (Web Vitals 2025)
    static let collectionScript = """
    (function() {
        const result = {
            navigation: null,
            resources: [],
            paints: [],
            lcp: -1,
            cls: -1,
            tbt: -1
        };

        // Navigation Timing
        const navEntries = performance.getEntriesByType('navigation');
        if (navEntries.length > 0) {
            const nav = navEntries[0];
            result.navigation = {
                startTime: nav.startTime,
                redirectTime: nav.redirectEnd - nav.redirectStart,
                dnsTime: nav.domainLookupEnd - nav.domainLookupStart,
                tcpTime: nav.connectEnd - nav.connectStart,
                tlsTime: nav.secureConnectionStart > 0 ? nav.connectEnd - nav.secureConnectionStart : 0,
                requestTime: nav.responseStart - nav.requestStart,
                responseTime: nav.responseEnd - nav.responseStart,
                domProcessingTime: nav.domComplete - nav.domInteractive,
                domContentLoadedTime: nav.domContentLoadedEventEnd - nav.startTime,
                loadEventTime: nav.loadEventEnd - nav.startTime
            };
        }

        // Resource Timing
        const resourceEntries = performance.getEntriesByType('resource');
        result.resources = resourceEntries.map(r => ({
            name: r.name,
            initiatorType: r.initiatorType,
            startTime: r.startTime,
            duration: r.duration,
            transferSize: r.transferSize || 0,
            encodedBodySize: r.encodedBodySize || 0,
            decodedBodySize: r.decodedBodySize || 0
        }));

        // Paint Timing
        const paintEntries = performance.getEntriesByType('paint');
        result.paints = paintEntries.map(p => ({
            name: p.name,
            startTime: p.startTime
        }));

        // LCP (Largest Contentful Paint)
        // Prefer observer value, fallback to getEntriesByType
        try {
            if (typeof window.__webVitals_lcp === 'number' && window.__webVitals_lcp >= 0) {
                result.lcp = window.__webVitals_lcp;
            } else {
                const lcpEntries = performance.getEntriesByType('largest-contentful-paint');
                if (lcpEntries.length > 0) {
                    result.lcp = lcpEntries[lcpEntries.length - 1].startTime;
                }
            }
        } catch (e) {}

        // CLS (Cumulative Layout Shift)
        // Prefer observer value (accumulates all shifts), fallback to getEntriesByType
        try {
            if (typeof window.__webVitals_cls === 'number' && window.__webVitals_cls >= 0) {
                result.cls = window.__webVitals_cls;
            } else {
                const layoutShifts = performance.getEntriesByType('layout-shift');
                let clsValue = 0;
                for (const entry of layoutShifts) {
                    if (!entry.hadRecentInput) {
                        clsValue += entry.value;
                    }
                }
                result.cls = clsValue;
            }
        } catch (e) {}

        // TBT approximation - sum of long task blocking time
        try {
            const longTasks = performance.getEntriesByType('longtask');
            let tbt = 0;
            for (const task of longTasks) {
                const blockingTime = task.duration - 50; // 50ms threshold
                if (blockingTime > 0) {
                    tbt += blockingTime;
                }
            }
            result.tbt = tbt;
        } catch (e) {}

        return JSON.stringify(result);
    })()
    """

    func parseData(from jsonString: String) {
        guard let jsonData = jsonString.data(using: .utf8) else {
            lastError = "Failed to convert string to data"
            return
        }

        do {
            let decoded = try JSONDecoder().decode(RawPerformanceData.self, from: jsonData)
            data = PerformanceData(
                navigation: decoded.navigation,
                resources: decoded.resources.map { raw in
                    ResourceTiming(
                        id: UUID(),
                        name: raw.name,
                        initiatorType: raw.initiatorType,
                        startTime: raw.startTime,
                        duration: raw.duration,
                        transferSize: raw.transferSize,
                        encodedBodySize: raw.encodedBodySize,
                        decodedBodySize: raw.decodedBodySize
                    )
                },
                paints: decoded.paints,
                timestamp: Date(),
                cls: decoded.cls,
                tbt: decoded.tbt
            )
            lastError = nil
        } catch {
            lastError = "Parse error: \(error.localizedDescription)"
        }
    }

    func clear() {
        data = PerformanceData()
        lastError = nil
    }
}

// Raw JSON structures for decoding
private struct RawPerformanceData: Codable {
    let navigation: NavigationTiming?
    let resources: [RawResourceTiming]
    let paints: [PaintTiming]
    let lcp: Double
    let cls: Double
    let tbt: Double
}

private struct RawResourceTiming: Codable {
    let name: String
    let initiatorType: String
    let startTime: Double
    let duration: Double
    let transferSize: Int
    let encodedBodySize: Int
    let decodedBodySize: Int
}

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
                // Overall Score
                overallScoreCard

                // Core Web Vitals Grid
                coreVitalsGrid

                // Pass/Fail Status
                coreVitalsStatus
            }
            .padding(.vertical, 8)
        }
    }

    private var overallScoreCard: some View {
        HStack(spacing: 16) {
            // Score Ring
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
            // LCP
            CoreVitalCard(
                label: "LCP",
                value: formatLCP(performanceManager.data.largestContentfulPaint),
                rating: performanceManager.data.lcpRating,
                description: "Largest Contentful Paint"
            )

            // CLS
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
            .sorted { $0.size > $1.size }  // Sort by size (largest first)
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

// MARK: - Core Vital Card (Bento Grid Item)

private struct CoreVitalCard: View {
    let label: String
    let value: String
    let rating: PerformanceRating
    let description: String

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(rating.color)

            Image(systemName: rating.icon)
                .font(.caption)
                .foregroundStyle(rating.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(rating.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Metric Row

private struct MetricRow: View {
    let label: String
    let value: Double
    let rating: PerformanceRating
    var threshold: String?

    var body: some View {
        HStack {
            Image(systemName: rating.icon)
                .foregroundStyle(rating.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                if let threshold {
                    Text(threshold)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(formatTime(value))
                .foregroundStyle(rating.color)
                .fontWeight(.medium)
        }
    }

    private func formatTime(_ ms: Double) -> String {
        if ms >= 1000 {
            return String(format: "%.2fs", ms / 1000)
        }
        return String(format: "%.0fms", ms)
    }
}

// MARK: - Resource Detail Row (Expandable List Item)

private struct ResourceDetailRow: View {
    let resource: ResourceTiming

    var body: some View {
        HStack(spacing: 8) {
            Text(resource.shortName)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            Text(formatTime(resource.duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)

            Text(resource.displaySize > 0 ? formatBytes(resource.displaySize) : "—")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
    }

    private func formatTime(_ ms: Double) -> String {
        if ms >= 1000 {
            return String(format: "%.2fs", ms / 1000)
        }
        return String(format: "%.0fms", ms)
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes >= 1_000_000 {
            return String(format: "%.1f MB", Double(bytes) / 1_000_000)
        } else if bytes >= 1_000 {
            return String(format: "%.1f KB", Double(bytes) / 1_000)
        }
        return "\(bytes) B"
    }
}

// MARK: - Resource Row (Legacy - kept for compatibility)

private struct ResourceRow: View {
    let resource: ResourceTiming

    var body: some View {
        HStack {
            Image(systemName: resource.resourceType.icon)
                .foregroundStyle(resource.resourceType.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(resource.shortName)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(formatTime(resource.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if resource.displaySize > 0 {
                Text(formatBytes(resource.displaySize))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func formatTime(_ ms: Double) -> String {
        if ms >= 1000 {
            return String(format: "%.2fs", ms / 1000)
        }
        return String(format: "%.0fms", ms)
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes >= 1_000_000 {
            return String(format: "%.1f MB", Double(bytes) / 1_000_000)
        } else if bytes >= 1_000 {
            return String(format: "%.1f KB", Double(bytes) / 1_000)
        }
        return "\(bytes) B"
    }
}

// MARK: - Timing Breakdown Row

private struct TimingBreakdownRow: View {
    let label: String
    let value: Double
    let total: Double

    var body: some View {
        HStack {
            Text(label)

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                let width = geometry.size.width
                let barWidth = total > 0 ? (value / total) * width : 0

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 8)
                        .clipShape(Capsule())

                    Rectangle()
                        .fill(.blue)
                        .frame(width: barWidth, height: 8)
                        .clipShape(Capsule())
                }
            }
            .frame(width: 80, height: 8)

            Text(formatTime(value))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
    }

    private func formatTime(_ ms: Double) -> String {
        if ms >= 1000 {
            return String(format: "%.2fs", ms / 1000)
        }
        return String(format: "%.0fms", ms)
    }
}

// MARK: - Timeline Row

private struct TimelineRow: View {
    let label: String
    let time: Double

    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(formatTime(time))
                .foregroundStyle(.secondary)
        }
    }

    private func formatTime(_ ms: Double) -> String {
        if ms >= 1000 {
            return String(format: "%.2fs", ms / 1000)
        }
        return String(format: "%.0fms", ms)
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
