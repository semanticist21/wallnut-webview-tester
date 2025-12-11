//
//  InfoButton.swift
//  wina
//

import SwiftUI

struct InfoButton: View {
    var useSafariVC: Bool = false
    @State private var showInfo = false

    var body: some View {
        GlassIconButton(icon: "info.circle") {
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

#Preview {
    InfoButton()
}
