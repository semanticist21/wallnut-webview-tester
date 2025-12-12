//
//  SettingToggleRow.swift
//  wina
//
//  Shared toggle row component with info popover
//

import SwiftUI

// MARK: - Setting Toggle Row

/// A toggle row with optional info button popover
struct SettingToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var info: String?
    var disabled: Bool = false
    var disabledLabel: String?

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Text(title)
                    .foregroundStyle(disabled ? .secondary : .primary)
                if disabled, let label = disabledLabel {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                if let info {
                    InfoPopoverButton(text: info)
                }
            }
        }
        .disabled(disabled)
    }
}

#Preview {
    List {
        SettingToggleRow(
            title: "JavaScript",
            isOn: .constant(true),
            info: "Master switch for all JavaScript execution."
        )
        SettingToggleRow(
            title: "Element Fullscreen",
            isOn: .constant(false),
            info: "Limited on iPhone.",
            disabled: true,
            disabledLabel: "(iPad only)"
        )
    }
}
