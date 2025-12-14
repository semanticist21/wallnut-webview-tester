//
//  CopyButton.swift
//  wina
//
//  Reusable button components for section headers and actions.
//

import SwiftUI

// MARK: - Header Action Button

/// Compact action button for section headers with icon and text label
struct HeaderActionButton: View {
    let label: String
    let icon: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.fill.tertiary, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Copy Button (Header Style)

/// Copy button with icon and text label for section headers
/// Shows "Copied" with checkmark feedback after copying
struct CopyButton: View {
    let text: String
    var label: String = "Copy"
    var onCopy: (() -> Void)?

    @State private var isCopied = false

    var body: some View {
        Button {
            guard !text.isEmpty else { return }
            UIPasteboard.general.string = text
            onCopy?()

            withAnimation(.easeInOut(duration: 0.15)) {
                isCopied = true
            }
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                // No animation on return
                isCopied = false
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                Text(isCopied ? "Copied" : label)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.fill.tertiary, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(text.isEmpty)
    }
}

// MARK: - Copy Icon Button

/// Compact copy button with icon only
/// Shows checkmark feedback after copying
struct CopyIconButton: View {
    let text: String
    var size: GlassIconButton.Size = .small
    var onCopy: (() -> Void)?

    @State private var isCopied = false

    var body: some View {
        GlassIconButton(icon: isCopied ? "checkmark" : "doc.on.doc", size: size) {
            guard !text.isEmpty else { return }
            UIPasteboard.general.string = text
            onCopy?()

            withAnimation(.easeInOut(duration: 0.15)) {
                isCopied = true
            }
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                isCopied = false
            }
        }
        .disabled(text.isEmpty)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            Text("Key")
            Spacer()
            CopyButton(text: "some-key-value")
        }

        HStack {
            Text("Actions")
            Spacer()
            HeaderActionButton(label: "Edit", icon: "pencil") { }
            HeaderActionButton(label: "Encode", icon: "arrow.right.circle") { }
        }

        HStack {
            Text("URL")
            Spacer()
            CopyIconButton(text: "https://example.com")
        }
    }
    .padding()
}
