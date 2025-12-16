//
//  ShareSheet.swift
//  wina
//
//  Shared UIActivityViewController wrapper for SwiftUI.
//

import SwiftUI

// MARK: - Share Sheet

/// A shared UIActivityViewController wrapper for sharing content
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?

    init(content: String) {
        self.activityItems = [content]
        self.applicationActivities = nil
    }

    init(fileURL: URL) {
        self.activityItems = [fileURL]
        self.applicationActivities = nil
    }

    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
