//
//  DeviceUtilities.swift
//  wina
//
//  Shared device and settings utility functions
//

import SwiftUI

// MARK: - UIDevice Extension

extension UIDevice {
    /// Returns true if the current device is an iPad
    var isIPad: Bool {
        userInterfaceIdiom == .pad
    }
}

// MARK: - Screen Utilities

enum ScreenUtility {
    /// Returns the current screen size from UIWindowScene
    static var screenSize: CGSize {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return CGSize(width: 393, height: 852) // Default iPhone size
        }
        return scene.screen.bounds.size
    }
}

// MARK: - Settings Formatters

enum SettingsFormatter {
    /// Formats content mode integer to display string
    static func contentModeText(_ mode: Int) -> String {
        switch mode {
        case 1: return "Mobile"
        case 2: return "Desktop"
        default: return "Recommended"
        }
    }

    /// Formats data detector flags to display string
    static func activeDataDetectors(
        phone: Bool,
        links: Bool,
        address: Bool,
        calendar: Bool
    ) -> String {
        var detectors: [String] = []
        if phone { detectors.append("Phone") }
        if links { detectors.append("Links") }
        if address { detectors.append("Address") }
        if calendar { detectors.append("Calendar") }
        return detectors.isEmpty ? "None" : detectors.joined(separator: ", ")
    }

    /// Formats boolean to "Enabled" or "Disabled"
    static func enabledStatus(_ enabled: Bool) -> String {
        enabled ? "Enabled" : "Disabled"
    }

    /// Formats Safari dismiss button style integer to display string
    static func dismissButtonStyleText(_ style: Int) -> String {
        switch style {
        case 1: return "Close"
        case 2: return "Cancel"
        default: return "Done"
        }
    }
}
