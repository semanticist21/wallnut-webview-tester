//
//  AboutButton.swift
//  wina
//

import SwiftUI

struct AboutButton: View {
    @Binding var showAbout: Bool

    var body: some View {
        GlassIconButton(
            icon: "sparkles",
            accessibilityLabel: "About"
        ) {
            showAbout = true
        }
    }
}

#Preview {
    AboutButton(showAbout: .constant(false))
}
