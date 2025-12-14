//
//  EmulationSettingsView.swift
//  wina
//
//  User preference emulation for testing media query responses.
//  Live setting - applies via JavaScript injection without page reload.
//

import SwiftUI

// MARK: - Emulation Settings View

struct EmulationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let navigator: WebViewNavigator

    // Applied state (currently active emulation)
    @State private var appliedColorScheme: EmulatedColorScheme = .system
    @State private var appliedReducedMotion: EmulatedReducedMotion = .noPreference
    @State private var appliedContrast: EmulatedContrast = .noPreference
    @State private var appliedReducedTransparency: EmulatedReducedTransparency = .noPreference

    // Local state (editing)
    @State private var colorScheme: EmulatedColorScheme = .system
    @State private var reducedMotion: EmulatedReducedMotion = .noPreference
    @State private var contrast: EmulatedContrast = .noPreference
    @State private var reducedTransparency: EmulatedReducedTransparency = .noPreference

    // Track if emulation is active
    @State private var isEmulating: Bool = false

    private var hasChanges: Bool {
        colorScheme != appliedColorScheme ||
        reducedMotion != appliedReducedMotion ||
        contrast != appliedContrast ||
        reducedTransparency != appliedReducedTransparency
    }

    private var isDefault: Bool {
        colorScheme == .system &&
        reducedMotion == .noPreference &&
        contrast == .noPreference &&
        reducedTransparency == .noPreference
    }

    var body: some View {
        List {
            Section {
                Picker("Color Scheme", selection: $colorScheme) {
                    ForEach(EmulatedColorScheme.allCases) { scheme in
                        Text(scheme.label).tag(scheme)
                    }
                }

                HStack {
                    Text("prefers-color-scheme")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(colorScheme.cssValue)
                        .font(.caption.monospaced())
                        .foregroundStyle(.purple)
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text("Emulates dark mode or light mode for pages using @media (prefers-color-scheme).")
            }

            Section {
                Picker("Reduced Motion", selection: $reducedMotion) {
                    ForEach(EmulatedReducedMotion.allCases) { motion in
                        Text(motion.label).tag(motion)
                    }
                }

                HStack {
                    Text("prefers-reduced-motion")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(reducedMotion.cssValue)
                        .font(.caption.monospaced())
                        .foregroundStyle(.purple)
                }
            } header: {
                Text("Motion")
            } footer: {
                Text("Tests accessibility feature that disables animations for users who prefer reduced motion.")
            }

            Section {
                Picker("Contrast", selection: $contrast) {
                    ForEach(EmulatedContrast.allCases) { contrastOption in
                        Text(contrastOption.label).tag(contrastOption)
                    }
                }

                HStack {
                    Text("prefers-contrast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(contrast.cssValue)
                        .font(.caption.monospaced())
                        .foregroundStyle(.purple)
                }
            } header: {
                Text("Contrast")
            } footer: {
                Text("Tests high contrast mode for accessibility. Websites may show higher contrast colors.")
            }

            Section {
                Picker("Reduced Transparency", selection: $reducedTransparency) {
                    ForEach(EmulatedReducedTransparency.allCases) { transparencyOption in
                        Text(transparencyOption.label).tag(transparencyOption)
                    }
                }

                HStack {
                    Text("prefers-reduced-transparency")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(reducedTransparency.cssValue)
                        .font(.caption.monospaced())
                        .foregroundStyle(.purple)
                }
            } header: {
                Text("Transparency")
            } footer: {
                Text("Tests accessibility feature that prefers solid backgrounds over transparent effects.")
            }

            Section {
                Button(role: .destructive) {
                    resetToDefaults()
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset to Defaults")
                        Spacer()
                    }
                }
                .disabled(isDefault && !isEmulating)
            }
        }
        .navigationTitle("Emulation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Apply") { applyEmulation() }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if isEmulating {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(.purple)
                    Text("Emulation Active")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
    }

    private func applyEmulation() {
        // Save to applied state
        appliedColorScheme = colorScheme
        appliedReducedMotion = reducedMotion
        appliedContrast = contrast
        appliedReducedTransparency = reducedTransparency

        // Apply emulation script
        let script = buildEmulationScript()
        Task {
            _ = await navigator.evaluateJavaScript(script)
            await MainActor.run {
                isEmulating = !isDefault
            }
        }
    }

    private func resetToDefaults() {
        // Clear emulation first if active
        if isEmulating {
            let clearScript = """
                (function() {
                    if (window.__winaEmulationCleanup) {
                        window.__winaEmulationCleanup();
                    }
                })();
            """
            Task {
                _ = await navigator.evaluateJavaScript(clearScript)
            }
        }

        // Reset all states to defaults
        colorScheme = .system
        reducedMotion = .noPreference
        contrast = .noPreference
        reducedTransparency = .noPreference
        appliedColorScheme = .system
        appliedReducedMotion = .noPreference
        appliedContrast = .noPreference
        appliedReducedTransparency = .noPreference
        isEmulating = false
    }

    private func buildEmulationScript() -> String {
        var overrides: [String] = []

        if colorScheme != .system {
            overrides.append("'(prefers-color-scheme: \(colorScheme.cssValue))': true")
            overrides.append("'(prefers-color-scheme: \(colorScheme == .dark ? "light" : "dark"))': false")
        }

        if reducedMotion != .noPreference {
            overrides.append("'(prefers-reduced-motion: reduce)': true")
            overrides.append("'(prefers-reduced-motion: no-preference)': false")
        }

        if contrast != .noPreference {
            overrides.append("'(prefers-contrast: \(contrast.cssValue))': true")
            overrides.append("'(prefers-contrast: no-preference)': false")
        }

        if reducedTransparency != .noPreference {
            overrides.append("'(prefers-reduced-transparency: reduce)': true")
            overrides.append("'(prefers-reduced-transparency: no-preference)': false")
        }

        return """
            (function() {
                // Clean up previous emulation
                if (window.__winaEmulationCleanup) {
                    window.__winaEmulationCleanup();
                }

                const overrides = {
                    \(overrides.joined(separator: ",\n            "))
                };

                const originalMatchMedia = window.matchMedia.bind(window);

                window.matchMedia = function(query) {
                    const result = originalMatchMedia(query);

                    // Check if we have an override for this query
                    const normalizedQuery = query.replace(/\\s+/g, ' ').trim().toLowerCase();
                    for (const [pattern, matches] of Object.entries(overrides)) {
                        const normalizedPattern = pattern.replace(/\\s+/g, ' ').trim().toLowerCase();
                        if (normalizedQuery.includes(normalizedPattern.slice(1, -1))) {
                            return {
                                matches: matches,
                                media: query,
                                onchange: null,
                                addListener: function(cb) { result.addListener(cb); },
                                removeListener: function(cb) { result.removeListener(cb); },
                                addEventListener: function(type, cb) { result.addEventListener(type, cb); },
                                removeEventListener: function(type, cb) { result.removeEventListener(type, cb); },
                                dispatchEvent: function(e) { return result.dispatchEvent(e); }
                            };
                        }
                    }
                    return result;
                };

                // Store cleanup function
                window.__winaEmulationCleanup = function() {
                    window.matchMedia = originalMatchMedia;
                    delete window.__winaEmulationCleanup;
                    // Remove injected style
                    const style = document.getElementById('wina-emulation-style');
                    if (style) style.remove();
                };

                // Inject CSS override for immediate visual effect
                let css = '';
                \(colorScheme != .system ? """
                css += ':root { color-scheme: \(colorScheme.cssValue); }';
                """ : "")

                if (css) {
                    const style = document.createElement('style');
                    style.id = 'wina-emulation-style';
                    style.textContent = css;
                    document.head.appendChild(style);
                }

                console.log('[Wina] Emulation applied:', Object.keys(overrides).length, 'overrides');
            })();
        """
    }
}

// MARK: - Emulation Types

enum EmulatedColorScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var cssValue: String {
        switch self {
        case .system: return "system"
        case .light: return "light"
        case .dark: return "dark"
        }
    }
}

enum EmulatedReducedMotion: String, CaseIterable, Identifiable {
    case noPreference
    case reduce

    var id: String { rawValue }

    var label: String {
        switch self {
        case .noPreference: return "No Preference"
        case .reduce: return "Reduce"
        }
    }

    var cssValue: String {
        switch self {
        case .noPreference: return "no-preference"
        case .reduce: return "reduce"
        }
    }
}

enum EmulatedContrast: String, CaseIterable, Identifiable {
    case noPreference
    case more

    var id: String { rawValue }

    var label: String {
        switch self {
        case .noPreference: return "No Preference"
        case .more: return "More (High Contrast)"
        }
    }

    var cssValue: String {
        switch self {
        case .noPreference: return "no-preference"
        case .more: return "more"
        }
    }
}

enum EmulatedReducedTransparency: String, CaseIterable, Identifiable {
    case noPreference
    case reduce

    var id: String { rawValue }

    var label: String {
        switch self {
        case .noPreference: return "No Preference"
        case .reduce: return "Reduce"
        }
    }

    var cssValue: String {
        switch self {
        case .noPreference: return "no-preference"
        case .reduce: return "reduce"
        }
    }
}

#Preview {
    NavigationStack {
        EmulationSettingsView(navigator: WebViewNavigator())
    }
}
