//
//  SettingsView.swift
//  wina
//
//  Created by Claude on 12/7/25.
//

import SwiftUI
import AVFoundation
import Combine
import CoreLocation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // Core Settings
    @AppStorage("enableJavaScript") private var enableJavaScript: Bool = true
    @AppStorage("allowsContentJavaScript") private var allowsContentJavaScript: Bool = true
    @AppStorage("allowZoom") private var allowZoom: Bool = true
    @AppStorage("minimumFontSize") private var minimumFontSize: Double = 0

    // Media Settings
    @AppStorage("mediaAutoplay") private var mediaAutoplay: Bool = false
    @AppStorage("inlineMediaPlayback") private var inlineMediaPlayback: Bool = true
    @AppStorage("allowsAirPlay") private var allowsAirPlay: Bool = true
    @AppStorage("allowsPictureInPicture") private var allowsPictureInPicture: Bool = true

    // Navigation & Gestures
    @AppStorage("allowsBackForwardGestures") private var allowsBackForwardGestures: Bool = true
    @AppStorage("allowsLinkPreview") private var allowsLinkPreview: Bool = true

    // Content Settings
    @AppStorage("suppressesIncrementalRendering") private var suppressesIncrementalRendering: Bool = false
    @AppStorage("javaScriptCanOpenWindows") private var javaScriptCanOpenWindows: Bool = false
    @AppStorage("fraudulentWebsiteWarning") private var fraudulentWebsiteWarning: Bool = true
    @AppStorage("textInteractionEnabled") private var textInteractionEnabled: Bool = true
    @AppStorage("elementFullscreenEnabled") private var elementFullscreenEnabled: Bool = false

    // Data Detectors
    @AppStorage("detectPhoneNumbers") private var detectPhoneNumbers: Bool = false
    @AppStorage("detectLinks") private var detectLinks: Bool = false
    @AppStorage("detectAddresses") private var detectAddresses: Bool = false
    @AppStorage("detectCalendarEvents") private var detectCalendarEvents: Bool = false

    // Privacy & Security
    @AppStorage("privateBrowsing") private var privateBrowsing: Bool = false
    @AppStorage("upgradeToHTTPS") private var upgradeToHTTPS: Bool = true

    // Content Mode
    @AppStorage("preferredContentMode") private var preferredContentMode: Int = 0  // 0: recommended, 1: mobile, 2: desktop

    // User Agent
    @AppStorage("customUserAgent") private var customUserAgent: String = ""

    @State private var cameraStatus: AVAuthorizationStatus = .notDetermined
    @State private var microphoneStatus: AVAuthorizationStatus = .notDetermined
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    @StateObject private var locationDelegate = LocationManagerDelegate()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SettingToggleRow(
                        title: "JavaScript",
                        isOn: $enableJavaScript,
                        info: "Master switch for all JavaScript execution in WebView."
                    )
                    SettingToggleRow(
                        title: "Content JavaScript",
                        isOn: $allowsContentJavaScript,
                        info: "Controls scripts from web pages only. App-injected scripts still work when disabled."
                    )
                    SettingToggleRow(
                        title: "Ignore Viewport Scale Limits",
                        isOn: $allowZoom,
                        info: "Allows pinch-to-zoom even when the page disables it via viewport meta tag."
                    )
                    HStack {
                        Text("Minimum Font Size")
                        Spacer()
                        TextField("0", value: $minimumFontSize, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("pt")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Core")
                }

                Section {
                    SettingToggleRow(
                        title: "Auto-play Media",
                        isOn: $mediaAutoplay,
                        info: "Allows videos with autoplay attribute to start without user interaction."
                    )
                    SettingToggleRow(
                        title: "Inline Playback",
                        isOn: $inlineMediaPlayback,
                        info: "Plays videos inline instead of fullscreen. Required for background video effects."
                    )
                    SettingToggleRow(
                        title: "AirPlay",
                        isOn: $allowsAirPlay,
                        info: "Enables streaming media to Apple TV and other AirPlay devices."
                    )
                    SettingToggleRow(
                        title: "Picture in Picture",
                        isOn: $allowsPictureInPicture,
                        info: "Allows videos to continue playing in a floating window."
                    )
                } header: {
                    Text("Media")
                }

                Section {
                    SettingToggleRow(
                        title: "Back/Forward Gestures",
                        isOn: $allowsBackForwardGestures,
                        info: "Enables swipe from edge to navigate history."
                    )
                    SettingToggleRow(
                        title: "Link Preview",
                        isOn: $allowsLinkPreview,
                        info: "Shows page preview on long-press or 3D Touch on links."
                    )
                } header: {
                    Text("Navigation")
                }

                Section {
                    Picker("Content Mode", selection: $preferredContentMode) {
                        Text("Recommended").tag(0)
                        Text("Mobile").tag(1)
                        Text("Desktop").tag(2)
                    }
                } header: {
                    Text("Content Mode")
                } footer: {
                    Text("Mobile: optimized for small screens. Desktop: requests full website.")
                }

                Section {
                    SettingToggleRow(
                        title: "JS Can Open Windows",
                        isOn: $javaScriptCanOpenWindows,
                        info: "Allows window.open() without user gesture. Disable to block pop-ups."
                    )
                    SettingToggleRow(
                        title: "Fraudulent Website Warning",
                        isOn: $fraudulentWebsiteWarning,
                        info: "Shows warning for suspected phishing or malware sites."
                    )
                    SettingToggleRow(
                        title: "Text Interaction",
                        isOn: $textInteractionEnabled,
                        info: "Enables text selection, copy, and other text interactions."
                    )
                    SettingToggleRow(
                        title: "Element Fullscreen API",
                        isOn: $elementFullscreenEnabled,
                        info: "Allows web pages to request fullscreen mode for elements like videos."
                    )
                    SettingToggleRow(
                        title: "Suppress Incremental Rendering",
                        isOn: $suppressesIncrementalRendering,
                        info: "Waits for full page load before displaying. May feel slower but cleaner."
                    )
                } header: {
                    Text("Behavior")
                }

                Section {
                    SettingToggleRow(
                        title: "Phone Numbers",
                        isOn: $detectPhoneNumbers,
                        info: "Makes phone numbers tappable to call."
                    )
                    SettingToggleRow(
                        title: "Links",
                        isOn: $detectLinks,
                        info: "Converts URL-like text to tappable links."
                    )
                    SettingToggleRow(
                        title: "Addresses",
                        isOn: $detectAddresses,
                        info: "Makes addresses tappable to open in Maps."
                    )
                    SettingToggleRow(
                        title: "Calendar Events",
                        isOn: $detectCalendarEvents,
                        info: "Detects dates and times, allowing to add to Calendar."
                    )
                } header: {
                    Text("Data Detectors")
                } footer: {
                    Text("Automatically detect and link specific content types")
                }

                Section {
                    SettingToggleRow(
                        title: "Private Browsing",
                        isOn: $privateBrowsing,
                        info: "Uses non-persistent data store. No cookies or cache saved after session."
                    )
                    SettingToggleRow(
                        title: "Upgrade to HTTPS",
                        isOn: $upgradeToHTTPS,
                        info: "Automatically upgrades HTTP requests to HTTPS for known secure hosts."
                    )
                } header: {
                    Text("Privacy & Security")
                }

                Section {
                    TextField("Custom User-Agent", text: $customUserAgent, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.system(size: 14, design: .monospaced))
                } header: {
                    Text("User-Agent")
                } footer: {
                    Text("Override the default browser identification string")
                }

                Section {
                    PermissionRow(
                        title: "Camera",
                        status: permissionText(for: cameraStatus),
                        granted: cameraStatus == .authorized
                    ) {
                        requestCameraPermission()
                    }

                    PermissionRow(
                        title: "Microphone",
                        status: permissionText(for: microphoneStatus),
                        granted: microphoneStatus == .authorized
                    ) {
                        requestMicrophonePermission()
                    }

                    PermissionRow(
                        title: "Location",
                        status: permissionText(for: locationStatus),
                        granted: locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways
                    ) {
                        requestLocationPermission()
                    }
                } header: {
                    Text("Permissions")
                } footer: {
                    Text("Required for WebRTC, Media Devices, and Geolocation APIs")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                updatePermissionStatuses()
            }
        }
    }

    private func updatePermissionStatuses() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        locationStatus = locationDelegate.locationManager.authorizationStatus
    }

    private func permissionText(for status: AVAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Requested"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Granted"
        @unknown default: return "Unknown"
        }
    }

    private func permissionText(for status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Requested"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }

    private func requestCameraPermission() {
        if cameraStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async {
                    cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
                }
            }
        } else {
            openSettings()
        }
    }

    private func requestMicrophonePermission() {
        if microphoneStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                DispatchQueue.main.async {
                    microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                }
            }
        } else {
            openSettings()
        }
    }

    private func requestLocationPermission() {
        if locationStatus == .notDetermined {
            locationDelegate.requestPermission { status in
                locationStatus = status
            }
        } else {
            openSettings()
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Setting Toggle Row

private struct SettingToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let info: String?

    init(title: String, isOn: Binding<Bool>, info: String? = nil) {
        self.title = title
        self._isOn = isOn
        self.info = info
    }

    @State private var showInfo = false

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Text(title)
                if let info {
                    Button {
                        showInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showInfo) {
                        Text(info)
                            .font(.footnote)
                            .padding()
                            .presentationCompactAdaptation(.popover)
                    }
                }
            }
        }
    }
}

// MARK: - Permission Row

private struct PermissionRow: View {
    let title: String
    let status: String
    let granted: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(status)
                .foregroundStyle(granted ? .green : .secondary)
                .font(.subheadline)
            Button {
                action()
            } label: {
                Image(systemName: granted ? "checkmark.circle.fill" : "arrow.right.circle")
                    .foregroundStyle(granted ? .green : .blue)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Location Manager Delegate

private class LocationManagerDelegate: NSObject, ObservableObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    private var completion: ((CLAuthorizationStatus) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestPermission(completion: @escaping (CLAuthorizationStatus) -> Void) {
        self.completion = completion
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.completion?(manager.authorizationStatus)
        }
    }
}

#Preview {
    SettingsView()
}
