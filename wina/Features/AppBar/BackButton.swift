//
//  BackButton.swift
//  wina
//

import SwiftUI

/// Home button - navigates back to URL input screen
struct HomeButton: View {
    let action: () -> Void

    var body: some View {
        GlassIconButton(
            icon: "house",
            accessibilityLabel: "Go to home"
        ) {
            action()
        }
    }
}

/// WebView back navigation button
struct WebBackButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18))
                .foregroundStyle(isEnabled ? .primary : .tertiary)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .glassEffect(in: .circle)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("Go back")
        .accessibilityAddTraits(.isButton)
    }
}

/// WebView forward navigation button
struct WebForwardButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.right")
                .font(.system(size: 18))
                .foregroundStyle(isEnabled ? .primary : .tertiary)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .glassEffect(in: .circle)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("Go forward")
        .accessibilityAddTraits(.isButton)
    }
}

/// WebView refresh button
struct RefreshButton: View {
    let action: () -> Void

    var body: some View {
        GlassIconButton(
            icon: "arrow.clockwise",
            accessibilityLabel: "Refresh page"
        ) {
            action()
        }
    }
}

// Keep BackButton as alias for backward compatibility
typealias BackButton = HomeButton

#Preview {
    HStack(spacing: 12) {
        HomeButton {}
        WebBackButton(isEnabled: true) {}
        WebForwardButton(isEnabled: false) {}
        RefreshButton {}
    }
}
