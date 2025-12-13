//
//  OverlayMenuBars.swift
//  wina
//
//  Created by Claude on 12/13/25.
//

import SwiftUI

struct OverlayMenuBars: View {
    let showWebView: Bool
    let hasBookmarks: Bool
    let useSafariVC: Bool
    let isOverlayMode: Bool  // true: pull menu, false: fixed position
    let onBack: () -> Void
    @Binding var showSettings: Bool
    @Binding var showBookmarks: Bool

    @State private var isExpanded: Bool = false
    @State private var dragOffset: CGFloat = 0

    private let topBarHeight: CGFloat = 64
    private let bottomBarHeight: CGFloat = 56
    private let topHandleVisible: CGFloat = 6  // Tiny peek for top bar

    // Top bar offset (comes down from top)
    private var topOffset: CGFloat {
        guard isOverlayMode else { return 0 }  // Fixed position
        if isExpanded {
            return dragOffset
        } else {
            return -topBarHeight + topHandleVisible + dragOffset
        }
    }

    // Bottom bar offset (comes up from bottom)
    private var bottomOffset: CGFloat {
        guard isOverlayMode else { return 0 }  // Fixed position
        if isExpanded {
            return -dragOffset
        } else {
            return bottomBarHeight - dragOffset  // Fully hidden
        }
    }

    // Show bottom bar?
    private var showBottomBar: Bool {
        !isOverlayMode || isExpanded
    }

    var body: some View {
        ZStack {
            // Top bar
            topBar
                .frame(maxHeight: .infinity, alignment: .top)

            // Bottom bar (hidden in overlay mode when collapsed)
            if showBottomBar {
                bottomBar
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: dragOffset)
        .onAppear {
            isExpanded = !isOverlayMode  // Expanded by default in fixed mode
        }
        .onChange(of: isOverlayMode) { _, newValue in
            isExpanded = !newValue
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 6) {
            // Menu buttons
            HStack(spacing: 12) {
                if showWebView {
                    BackButton(action: onBack)
                } else {
                    ThemeToggleButton()
                    BookmarkButton(showBookmarks: $showBookmarks, hasBookmarks: hasBookmarks)
                }

                Spacer()

                if !showWebView {
                    InfoButton(useSafariVC: useSafariVC)
                }
                SettingsButton(showSettings: $showSettings)
            }
            .padding(.horizontal, 16)

            // Handle (drag area) - only in overlay mode
            if isOverlayMode {
                Capsule()
                    .frame(width: 36, height: 4)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .glassEffect(in: .capsule)
        .padding(.horizontal, 8)
        .offset(y: topOffset)
        .highPriorityGesture(isOverlayMode ? dragGesture : nil)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
            }
            .frame(height: bottomBarHeight)
            .frame(maxWidth: .infinity)
            .glassEffect(in: .capsule)
            .padding(.horizontal, 8)
            // Dynamic: push down by half of safe area to sit nicely above home indicator
            .padding(.bottom, -(geometry.safeAreaInsets.bottom * 0.6))
            .offset(y: bottomOffset)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.height

                if isExpanded {
                    // When expanded, allow dragging up (negative) to close
                    dragOffset = min(0, translation)
                } else {
                    // When collapsed, allow dragging down (positive) to open
                    dragOffset = max(0, min(topBarHeight, translation))
                }
            }
            .onEnded { value in
                let translation = value.translation.height
                let velocity = value.predictedEndTranslation.height - translation

                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isExpanded {
                        // Close if dragged up enough or with velocity
                        if translation < -30 || velocity < -100 {
                            isExpanded = false
                        }
                    } else {
                        // Open if dragged down enough or with velocity
                        if translation > 30 || velocity > 100 {
                            isExpanded = true
                        }
                    }
                    dragOffset = 0
                }
            }
    }
}

#Preview("Overlay Mode (Fullscreen)") {
    ZStack {
        Color.blue.opacity(0.3)
            .ignoresSafeArea()

        OverlayMenuBars(
            showWebView: true,
            hasBookmarks: true,
            useSafariVC: false,
            isOverlayMode: true,
            onBack: {},
            showSettings: .constant(false),
            showBookmarks: .constant(false)
        )
    }
}

#Preview("Fixed Mode (App Preset)") {
    ZStack {
        Color.blue.opacity(0.3)
            .ignoresSafeArea()

        OverlayMenuBars(
            showWebView: true,
            hasBookmarks: true,
            useSafariVC: false,
            isOverlayMode: false,
            onBack: {},
            showSettings: .constant(false),
            showBookmarks: .constant(false)
        )
    }
}
