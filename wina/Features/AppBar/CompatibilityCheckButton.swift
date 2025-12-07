//
//  CompatibilityCheckButton.swift
//  wina
//

import SwiftUI

struct CompatibilityCheckButton: View {
    @State private var showCompatibility = false

    var body: some View {
        GlassIconButton(icon: "checkmark.shield") {
            showCompatibility = true
        }
        .sheet(isPresented: $showCompatibility) {
            CompatibilityView()
        }
    }
}

#Preview {
    CompatibilityCheckButton()
}
