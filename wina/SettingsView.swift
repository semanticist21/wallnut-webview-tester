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
    @AppStorage("allowZoom") private var allowZoom: Bool = true

    // Media Settings
    @AppStorage("mediaAutoplay") private var mediaAutoplay: Bool = false
    @AppStorage("inlineMediaPlayback") private var inlineMediaPlayback: Bool = true
    @AppStorage("allowsAirPlay") private var allowsAirPlay: Bool = true
    @AppStorage("allowsPictureInPicture") private var allowsPictureInPicture: Bool = true

    // Content Settings
    @AppStorage("suppressesIncrementalRendering") private var suppressesIncrementalRendering: Bool = false
    @AppStorage("allowsContentJavaScript") private var allowsContentJavaScript: Bool = true
    @AppStorage("javaScriptCanOpenWindows") private var javaScriptCanOpenWindows: Bool = false
    @AppStorage("fraudulentWebsiteWarning") private var fraudulentWebsiteWarning: Bool = true
    @AppStorage("textInteractionEnabled") private var textInteractionEnabled: Bool = true
    @AppStorage("elementFullscreenEnabled") private var elementFullscreenEnabled: Bool = false

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
                    Toggle("JavaScript", isOn: $enableJavaScript)
                    Toggle("Content JavaScript", isOn: $allowsContentJavaScript)
                    Toggle("Ignore Viewport Scale Limits", isOn: $allowZoom)
                } header: {
                    Text("Core")
                } footer: {
                    Text("Content JavaScript controls scripts from web pages only")
                }

                Section {
                    Toggle("Auto-play Media", isOn: $mediaAutoplay)
                    Toggle("Inline Playback", isOn: $inlineMediaPlayback)
                    Toggle("AirPlay", isOn: $allowsAirPlay)
                    Toggle("Picture in Picture", isOn: $allowsPictureInPicture)
                } header: {
                    Text("Media")
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
                    Text("Controls viewport and user agent behavior")
                }

                Section {
                    Toggle("JS Can Open Windows", isOn: $javaScriptCanOpenWindows)
                    Toggle("Fraudulent Website Warning", isOn: $fraudulentWebsiteWarning)
                    Toggle("Text Interaction", isOn: $textInteractionEnabled)
                    Toggle("Element Fullscreen API", isOn: $elementFullscreenEnabled)
                    Toggle("Suppress Incremental Rendering", isOn: $suppressesIncrementalRendering)
                } header: {
                    Text("Behavior")
                }

                Section {
                    TextField("Custom User-Agent", text: $customUserAgent, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.system(size: 14, design: .monospaced))
                } header: {
                    Text("User-Agent")
                } footer: {
                    Text("Leave empty to use default")
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
