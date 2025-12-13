//
//  ConsoleView.swift
//  wina
//
//  Created by Claude on 12/13/25.
//

import SwiftUI

// MARK: - Console Log Model

struct ConsoleLog: Identifiable, Equatable {
    let id = UUID()
    let type: LogType
    let message: String
    let timestamp: Date

    enum LogType: String, CaseIterable {
        case log
        case info
        case warn
        case error
        case debug

        var icon: String {
            switch self {
            case .log: return "text.bubble"
            case .info: return "info.circle"
            case .warn: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .debug: return "ladybug"
            }
        }

        var color: Color {
            switch self {
            case .log: return .primary
            case .info: return .blue
            case .warn: return .orange
            case .error: return .red
            case .debug: return .purple
            }
        }
    }
}

// MARK: - Console Manager

@Observable
class ConsoleManager {
    var logs: [ConsoleLog] = []
    var isCapturing: Bool = true

    func addLog(type: String, message: String) {
        guard isCapturing else { return }
        let logType = ConsoleLog.LogType(rawValue: type) ?? .log
        let log = ConsoleLog(type: logType, message: message, timestamp: Date())
        DispatchQueue.main.async {
            self.logs.append(log)
        }
    }

    func clear() {
        logs.removeAll()
    }

    func toggleCapturing() {
        isCapturing.toggle()
    }
}

// MARK: - Console View

struct ConsoleView: View {
    let consoleManager: ConsoleManager
    @Environment(\.dismiss) private var dismiss
    @State private var filterType: ConsoleLog.LogType?
    @State private var searchText: String = ""

    private var filteredLogs: [ConsoleLog] {
        var result = consoleManager.logs

        // Filter by type
        if let filterType {
            result = result.filter { $0.type == filterType }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter bar
                filterBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()

                // Log list
                if filteredLogs.isEmpty {
                    emptyState
                } else {
                    logList
                }
            }
            .navigationTitle("Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        consoleManager.clear()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(consoleManager.logs.isEmpty)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            consoleManager.toggleCapturing()
                        } label: {
                            Image(systemName: consoleManager.isCapturing ? "pause.fill" : "play.fill")
                        }

                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search logs")
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: filterType == nil) {
                    filterType = nil
                }

                ForEach(ConsoleLog.LogType.allCases, id: \.self) { type in
                    FilterChip(
                        label: type.rawValue.capitalized,
                        icon: type.icon,
                        color: type.color,
                        isSelected: filterType == type
                    ) {
                        filterType = type
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "terminal")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(consoleManager.logs.isEmpty ? "No logs captured" : "No matching logs")
                .font(.headline)
                .foregroundStyle(.secondary)
            if !consoleManager.isCapturing {
                Text("Capturing is paused")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }

    private var logList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(filteredLogs) { log in
                    LogRow(log: log)
                        .id(log.id)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }
            .listStyle(.plain)
            .onChange(of: consoleManager.logs.count) { _, _ in
                // Auto-scroll to bottom on new log
                if let lastLog = filteredLogs.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - Log Row

private struct LogRow: View {
    let log: ConsoleLog

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: log.timestamp)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: log.type.icon)
                .font(.system(size: 12))
                .foregroundStyle(log.type.color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.message)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)

                Text(formattedTime)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    var icon: String?
    var color: Color = .primary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color.clear, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let manager = ConsoleManager()
    manager.addLog(type: "log", message: "Hello, world!")
    manager.addLog(type: "info", message: "Page loaded successfully")
    manager.addLog(type: "warn", message: "Deprecated API usage detected")
    manager.addLog(type: "error", message: "Failed to fetch resource: 404 Not Found")
    manager.addLog(type: "debug", message: "User clicked button #submit")

    return ConsoleView(consoleManager: manager)
}
