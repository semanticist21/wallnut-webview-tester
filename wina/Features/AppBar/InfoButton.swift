//
//  InfoButton.swift
//  wina
//

import SwiftUI

/// Info button with internal sheet management (for standalone use)
struct InfoButton: View {
    var useSafariVC: Bool = false
    @State private var showInfo = false

    var body: some View {
        GlassIconButton(
            icon: "info.circle",
            accessibilityLabel: "API capabilities info"
        ) {
            showInfo = true
        }
        .sheet(isPresented: $showInfo) {
            if useSafariVC {
                SafariVCInfoView()
            } else {
                InfoView()
            }
        }
    }
}

/// Info button with external sheet binding (for OverlayMenuBars)
struct InfoSheetButton: View {
    @Binding var showInfo: Bool

    var body: some View {
        GlassIconButton(
            icon: "info.circle",
            accessibilityLabel: "API capabilities info"
        ) {
            showInfo = true
        }
    }
}

#Preview {
    InfoButton()
}
