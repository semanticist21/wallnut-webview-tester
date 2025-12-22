//
//  ScrollNavigationButtons.swift
//  wina
//
//  Reusable scroll navigation overlay with minimal design and haptic feedback.
//

import SwiftUI
import SwiftUIBackports

// MARK: - Scroll Navigation Buttons

struct ScrollNavigationButtons: View {
    let scrollOffset: CGFloat
    let contentHeight: CGFloat
    let viewportHeight: CGFloat
    let onScrollUp: () -> Void
    let onScrollDown: () -> Void

    /// Show progress indicator between buttons
    var showProgress: Bool = false

    /// Minimal mode: show only relevant button based on position
    var minimalMode: Bool = true

    // MARK: - Computed Properties

    private var canScroll: Bool {
        contentHeight > viewportHeight + 20
    }

    private var isNearTop: Bool {
        scrollOffset <= 20
    }

    private var isNearBottom: Bool {
        (contentHeight - scrollOffset - viewportHeight) <= 20
    }

    private var scrollProgress: CGFloat {
        guard contentHeight > viewportHeight else { return 0 }
        let maxOffset = contentHeight - viewportHeight
        return min(max(scrollOffset / maxOffset, 0), 1)
    }

    private var progressPercent: Int {
        Int(scrollProgress * 100)
    }

    var body: some View {
        if canScroll {
            VStack(spacing: showProgress ? 4 : 8) {
                // Up button
                if !minimalMode || !isNearTop {
                    scrollButton(
                        icon: "chevron.up.circle.fill",
                        isEnabled: !isNearTop,
                        action: {
                            triggerHaptic()
                            onScrollUp()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Progress indicator
                if showProgress {
                    progressIndicator
                        .transition(.opacity)
                }

                // Down button
                if !minimalMode || !isNearBottom {
                    scrollButton(
                        icon: "chevron.down.circle.fill",
                        isEnabled: !isNearBottom,
                        action: {
                            triggerHaptic()
                            onScrollDown()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 12)
            .animation(.easeInOut(duration: 0.2), value: isNearTop)
            .animation(.easeInOut(duration: 0.2), value: isNearBottom)
        }
    }

    // MARK: - Scroll Button

    @ViewBuilder
    private func scrollButton(
        icon: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.white)
        }
        .backport
        .glassEffect(in: .circle)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.3)
    }

    // MARK: - Progress Indicator

    @ViewBuilder
    private var progressIndicator: some View {
        Text("\(progressPercent)%")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 32, height: 16)
    }

    // MARK: - Haptic

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - View Extension for Easy Integration

extension View {
    /// Adds scroll navigation buttons overlay to a ScrollView
    /// - Parameters:
    ///   - scrollOffset: Current scroll offset (y position)
    ///   - contentHeight: Total content height
    ///   - viewportHeight: Visible viewport height
    ///   - showProgress: Show progress percentage between buttons
    ///   - minimalMode: Show only relevant button based on scroll position
    ///   - onScrollUp: Action when up button tapped
    ///   - onScrollDown: Action when down button tapped
    func scrollNavigationOverlay(
        scrollOffset: CGFloat,
        contentHeight: CGFloat,
        viewportHeight: CGFloat,
        showProgress: Bool = false,
        minimalMode: Bool = true,
        onScrollUp: @escaping () -> Void,
        onScrollDown: @escaping () -> Void
    ) -> some View {
        self.overlay(alignment: .bottomTrailing) {
            ScrollNavigationButtons(
                scrollOffset: scrollOffset,
                contentHeight: contentHeight,
                viewportHeight: viewportHeight,
                onScrollUp: onScrollUp,
                onScrollDown: onScrollDown,
                showProgress: showProgress,
                minimalMode: minimalMode
            )
        }
    }
}

#Preview {
    VStack {
        ScrollNavigationButtons(
            scrollOffset: 100,
            contentHeight: 1000,
            viewportHeight: 400,
            onScrollUp: {},
            onScrollDown: {},
            showProgress: true,
            minimalMode: false
        )

        Divider()

        // Minimal mode - near top
        ScrollNavigationButtons(
            scrollOffset: 10,
            contentHeight: 1000,
            viewportHeight: 400,
            onScrollUp: {},
            onScrollDown: {},
            minimalMode: true
        )

        Divider()

        // Minimal mode - near bottom
        ScrollNavigationButtons(
            scrollOffset: 590,
            contentHeight: 1000,
            viewportHeight: 400,
            onScrollUp: {},
            onScrollDown: {},
            minimalMode: true
        )
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
