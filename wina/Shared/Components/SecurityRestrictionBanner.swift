//
//  SecurityRestrictionBanner.swift
//  wina
//
//  Shared banner component for security-related information omissions.
//

import SwiftUI

// MARK: - Security Restriction Banner

/// A banner indicating that some information was omitted due to security restrictions
struct SecurityRestrictionBanner: View {
    let type: RestrictionType

    enum RestrictionType {
        case crossOriginTiming
        case crossOriginStylesheet(count: Int)
        case staticResourceBody

        var icon: String {
            switch self {
            case .crossOriginTiming: "clock.badge.exclamationmark"
            case .crossOriginStylesheet: "lock.shield"
            case .staticResourceBody: "eye.slash"
            }
        }

        var message: LocalizedStringKey {
            switch self {
            case .crossOriginTiming:
                "Timing details unavailable for cross-origin resource"
            case .crossOriginStylesheet(let count):
                "\(count) stylesheet(s) blocked by CORS"
            case .staticResourceBody:
                "Response body unavailable for static resources"
            }
        }

        var color: Color {
            .orange
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 12))
                .foregroundStyle(type.color)

            Text(type.message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            InfoPopoverButton(
                text: infoText
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(type.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private var infoText: LocalizedStringKey {
        switch type {
        case .crossOriginTiming:
            "Detailed timing data (DNS, TCP, TLS, etc.) is unavailable for cross-origin resources unless the server includes a Timing-Allow-Origin header. This is a browser security restriction."
        case .crossOriginStylesheet:
            "Styles from external CDNs (Tailwind, Bootstrap, etc.) cannot be inspected due to browser CORS security policy."
        case .staticResourceBody:
            "Static resources like scripts and stylesheets are loaded directly by the browser and cannot be intercepted by JavaScript. Only fetch/XHR requests can capture response bodies."
        }
    }
}

#Preview("Cross-Origin Timing") {
    SecurityRestrictionBanner(type: .crossOriginTiming)
        .padding()
}

#Preview("CORS Stylesheet") {
    SecurityRestrictionBanner(type: .crossOriginStylesheet(count: 3))
        .padding()
}

#Preview("Static Resource Body") {
    SecurityRestrictionBanner(type: .staticResourceBody)
        .padding()
}
