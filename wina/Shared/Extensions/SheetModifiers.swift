//
//  SheetModifiers.swift
//  wina
//
//  Reusable sheet presentation modifiers.
//

import SwiftUI

// MARK: - DevTools Sheet Modifier

struct DevToolsSheetModifier: ViewModifier {
    @State private var detent: PresentationDetent = BarConstants.defaultSheetDetent

    func body(content: Content) -> some View {
        content
            .presentationDetents(BarConstants.sheetDetents, selection: $detent)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationContentInteraction(.scrolls)
            .presentationDragIndicator(.visible)
    }
}

extension View {
    /// DevTools sheet style with compact option, starts at medium detent
    func devToolsSheet() -> some View {
        modifier(DevToolsSheetModifier())
    }
}
