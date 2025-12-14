//
//  GlassActionButton.swift
//  wina
//

import SwiftUI

/// Capsule-shaped glass effect button for actions like Reset, Apply, Done
/// Used in Settings views as inline action buttons
struct GlassActionButton: View {
    let title: String
    let icon: String?
    let style: ActionStyle
    let action: () -> Void

    enum ActionStyle {
        case `default`
        case destructive
        case primary

        var foregroundColor: Color {
            switch self {
            case .default: return .primary
            case .destructive: return .red
            case .primary: return .accentColor
            }
        }
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: ActionStyle = .default,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if let icon {
                    Label(title, systemImage: icon)
                } else {
                    Text(title)
                }
            }
            .font(.subheadline)
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .glassEffect(in: .capsule)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 20) {
        GlassActionButton("Reset to Defaults", icon: "arrow.counterclockwise", style: .destructive) {}
        GlassActionButton("Apply", icon: "checkmark", style: .primary) {}
        GlassActionButton("Done") {}
    }
    .padding()
}
