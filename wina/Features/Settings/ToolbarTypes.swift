//
//  ToolbarTypes.swift
//  wina
//
//  Created by Claude on 12/23/25.
//

import SwiftUI

// MARK: - DevTools Menu Item

enum DevToolsMenuItem: String, CaseIterable, Identifiable {
    case console
    case sources
    case network
    case storage
    case performance
    case accessibility
    case snippets
    case searchInPage
    case screenshot

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .console: return "terminal"
        case .sources: return "chevron.left.forwardslash.chevron.right"
        case .network: return "network"
        case .storage: return "externaldrive"
        case .performance: return "gauge.with.dots.needle.bottom.50percent"
        case .accessibility: return "accessibility"
        case .snippets: return "scroll"
        case .searchInPage: return "doc.text.magnifyingglass"
        case .screenshot: return "camera"
        }
    }

    var label: LocalizedStringKey {
        switch self {
        case .console: return "Console"
        case .sources: return "Sources"
        case .network: return "Network"
        case .storage: return "Storage"
        case .performance: return "Performance"
        case .accessibility: return "Accessibility"
        case .snippets: return "Snippets"
        case .searchInPage: return "Search in Page"
        case .screenshot: return "Screenshot"
        }
    }

    var description: LocalizedStringKey {
        switch self {
        case .console: return "JavaScript console logs"
        case .sources: return "DOM tree, stylesheets, scripts"
        case .network: return "Network requests monitoring"
        case .storage: return "localStorage, sessionStorage, cookies"
        case .performance: return "Web Vitals & timing metrics"
        case .accessibility: return "Accessibility audit (axe-core)"
        case .snippets: return "Run JavaScript snippets"
        case .searchInPage: return "Find text in page"
        case .screenshot: return "Capture page screenshot"
        }
    }

    /// Items that remain visible even when Eruda mode is enabled
    var isAlwaysVisible: Bool {
        switch self {
        case .searchInPage, .screenshot:
            return true
        default:
            return false
        }
    }

    /// Default order of all items
    static var defaultOrder: [DevToolsMenuItem] {
        allCases
    }
}

// MARK: - Toolbar Item State

struct ToolbarItemState: Identifiable, Codable, Equatable {
    var id: String { menuItem.rawValue }
    let menuItem: DevToolsMenuItem
    var isVisible: Bool

    enum CodingKeys: String, CodingKey {
        case menuItem
        case isVisible
    }

    init(menuItem: DevToolsMenuItem, isVisible: Bool) {
        self.menuItem = menuItem
        self.isVisible = isVisible
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .menuItem)
        guard let item = DevToolsMenuItem(rawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .menuItem,
                in: container,
                debugDescription: "Unknown menu item: \(rawValue)"
            )
        }
        self.menuItem = item
        self.isVisible = try container.decode(Bool.self, forKey: .isVisible)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(menuItem.rawValue, forKey: .menuItem)
        try container.encode(isVisible, forKey: .isVisible)
    }
}

// MARK: - Helper for Reading Toolbar Settings

struct ToolbarSettings {
    static func getVisibleItems() -> [DevToolsMenuItem] {
        guard let data = UserDefaults.standard.data(forKey: "toolbarItemsOrder"),
              let items = try? JSONDecoder().decode([ToolbarItemState].self, from: data) else {
            // Default: all items visible
            return DevToolsMenuItem.defaultOrder
        }

        return items.filter { $0.isVisible }.map { $0.menuItem }
    }
}
