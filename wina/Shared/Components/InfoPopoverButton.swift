//
//  InfoPopoverButton.swift
//  wina
//
//  Reusable info button with popover
//

import SwiftUI

// MARK: - Info Popover Button

/// A button that shows an info popover when tapped
struct InfoPopoverButton<S: ShapeStyle>: View {
    let text: String
    let iconColor: S

    @State private var showInfo = false

    var body: some View {
        Button {
            showInfo = true
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(iconColor)
                .font(.footnote)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showInfo) {
            Text(text)
                .font(.footnote)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }
}

// Convenience initializer with default color
extension InfoPopoverButton where S == Color {
    init(text: String) {
        self.text = text
        self.iconColor = .secondary
    }
}

#Preview {
    HStack {
        Text("Setting Name")
        InfoPopoverButton(text: "This is helpful information about the setting.")
        Spacer()
    }
    .padding()
}
