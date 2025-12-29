//
//  AppSettingsView.swift
//  wina
//
//  Created by Claude on 12/27/25.
//

import SwiftUI

// MARK: - App Language Enum (App Store Connect Supported Languages)

enum AppLanguage: String, CaseIterable, Identifiable {
    // System default
    case system = ""

    // Major languages (alphabetical by language name)
    case arabic = "ar"
    case catalan = "ca"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case croatian = "hr"
    case czech = "cs"
    case danish = "da"
    case dutch = "nl"
    case english = "en"
    case finnish = "fi"
    case french = "fr"
    case german = "de"
    case greek = "el"
    case hebrew = "he"
    case hindi = "hi"
    case hungarian = "hu"
    case indonesian = "id"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case malay = "ms"
    case norwegian = "nb"
    case polish = "pl"
    case portugueseBrazil = "pt-BR"
    case portuguesePortugal = "pt-PT"
    case romanian = "ro"
    case russian = "ru"
    case slovak = "sk"
    case spanish = "es"
    case swedish = "sv"
    case thai = "th"
    case turkish = "tr"
    case ukrainian = "uk"
    case vietnamese = "vi"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .arabic: return "العربية"
        case .catalan: return "Català"
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        case .croatian: return "Hrvatski"
        case .czech: return "Čeština"
        case .danish: return "Dansk"
        case .dutch: return "Nederlands"
        case .english: return "English"
        case .finnish: return "Suomi"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .greek: return "Ελληνικά"
        case .hebrew: return "עברית"
        case .hindi: return "हिन्दी"
        case .hungarian: return "Magyar"
        case .indonesian: return "Bahasa Indonesia"
        case .italian: return "Italiano"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .malay: return "Bahasa Melayu"
        case .norwegian: return "Norsk"
        case .polish: return "Polski"
        case .portugueseBrazil: return "Português (Brasil)"
        case .portuguesePortugal: return "Português (Portugal)"
        case .romanian: return "Română"
        case .russian: return "Русский"
        case .slovak: return "Slovenčina"
        case .spanish: return "Español"
        case .swedish: return "Svenska"
        case .thai: return "ไทย"
        case .turkish: return "Türkçe"
        case .ukrainian: return "Українська"
        case .vietnamese: return "Tiếng Việt"
        }
    }
}

// MARK: - App Settings View

struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // Storage
    @AppStorage("appLanguage") private var storedAppLanguage: String = ""
    @AppStorage("colorSchemeOverride") private var storedColorScheme: String?

    // Local state
    @State private var appLanguage: String = ""
    @State private var colorScheme: String = ""  // "", "light", "dark"

    private var hasChanges: Bool {
        appLanguage != storedAppLanguage ||
        colorScheme != (storedColorScheme ?? "")
    }

    private var selectedLanguageDisplayName: String {
        AppLanguage(rawValue: appLanguage)?.displayName ?? "System"
    }

    var body: some View {
        List {
            Section {
                Picker(selection: $colorScheme) {
                    Text("System").tag("")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                } label: {
                    Text("Theme")
                }
            } header: {
                Text("Appearance")
            }

            Section {
                NavigationLink {
                    LanguagePickerView(selectedLanguage: $appLanguage)
                } label: {
                    HStack {
                        Text("Language")
                        Spacer()
                        Text(selectedLanguageDisplayName)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Language")
            }

            Section {
                HStack {
                    Spacer()
                    GlassActionButton("Reset", icon: "arrow.counterclockwise", style: .destructive) {
                        resetToDefaults()
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(Text(verbatim: "App Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Apply") { applyChanges() }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges)
            }
        }
        .onAppear { loadFromStorage() }
    }

    private func loadFromStorage() {
        appLanguage = storedAppLanguage
        colorScheme = storedColorScheme ?? ""
    }

    private func applyChanges() {
        storedAppLanguage = appLanguage
        storedColorScheme = colorScheme.isEmpty ? nil : colorScheme
        dismiss()
    }

    private func resetToDefaults() {
        appLanguage = ""
        colorScheme = ""
    }
}

// MARK: - Searchable Language Picker View

struct LanguagePickerView: View {
    @Binding var selectedLanguage: String
    @State private var searchText = ""

    private var filteredLanguages: [AppLanguage] {
        if searchText.isEmpty {
            return Array(AppLanguage.allCases)
        }
        return AppLanguage.allCases.filter { language in
            language.displayName.localizedCaseInsensitiveContains(searchText) ||
            language.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredLanguages) { language in
                HStack {
                    Text(language.displayName)
                    Spacer()
                    if language.rawValue == selectedLanguage {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedLanguage = language.rawValue
                }
            }
        }
        .navigationTitle(Text(verbatim: "Language"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search languages")
    }
}

#Preview {
    NavigationStack {
        AppSettingsView()
    }
}
