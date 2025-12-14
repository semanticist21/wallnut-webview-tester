//
//  ThemeToggleButton.swift
//  wina
//

import SwiftUI

struct ThemeToggleButton: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        GlassIconButton(
            icon: isDarkMode ? "moon.fill" : "sun.max.fill",
            accessibilityLabel: isDarkMode ? "Switch to light mode" : "Switch to dark mode"
        ) {
            isDarkMode.toggle()
        }
    }
}

#Preview {
    ThemeToggleButton()
}
