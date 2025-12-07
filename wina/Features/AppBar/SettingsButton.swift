//
//  SettingsButton.swift
//  wina
//

import SwiftUI

struct SettingsButton: View {
    @Binding var showSettings: Bool

    var body: some View {
        GlassIconButton(icon: "gearshape") {
            showSettings = true
        }
    }
}

#Preview {
    SettingsButton(showSettings: .constant(false))
}
