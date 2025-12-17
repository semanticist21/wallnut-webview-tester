//
//  SheetModifiers.swift
//  wina
//
//  Reusable sheet presentation modifiers.
//

import SwiftUI

// MARK: - DevTools Sheet Modifier

struct DevToolsSheetModifier: ViewModifier {
    @State private var detent: PresentationDetent = UIDevice.current.isIPad ? .large : BarConstants.defaultSheetDetent

    func body(content: Content) -> some View {
        content
            .presentationDetents(BarConstants.sheetDetents, selection: $detent)
            .presentationSizing(.form)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationContentInteraction(.scrolls)
            .presentationDragIndicator(.visible)
    }
}

// MARK: - Full Size Sheet Modifier

struct FullSizeSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationDetents([.large])
            .presentationSizing(.page)
            .presentationContentInteraction(.scrolls)
            .presentationDragIndicator(.visible)
    }
}

extension View {
    /// DevTools sheet style with compact option, starts at medium detent
    func devToolsSheet() -> some View {
        modifier(DevToolsSheetModifier())
    }

    /// Full size sheet for Settings/Info, always large on both iOS and iPad
    func fullSizeSheet() -> some View {
        modifier(FullSizeSheetModifier())
    }
}
