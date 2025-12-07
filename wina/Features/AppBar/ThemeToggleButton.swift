//
//  ThemeToggleButton.swift
//  wina
//

import SwiftUI

struct ThemeToggleButton: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        GlassIconButton(icon: isDarkMode ? "moon.fill" : "sun.max.fill") {
            isDarkMode.toggle()
        }
    }
}

#Preview {
    ThemeToggleButton()
}
