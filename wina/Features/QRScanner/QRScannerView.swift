//
//  QRScannerView.swift
//  wina
//
//  Created by Claude on 12/10/25.
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned, dismiss: dismiss)
    }

    class Coordinator: NSObject, QRScannerViewControllerDelegate {
        let onCodeScanned: (String) -> Void
        let dismiss: DismissAction

        init(onCodeScanned: @escaping (String) -> Void, dismiss: DismissAction) {
            self.onCodeScanned = onCodeScanned
            self.dismiss = dismiss
        }

        func didScanCode(_ code: String) {
            onCodeScanned(code)
            dismiss()
        }

        func didFailWithError(_ error: Error) {
            dismiss()
        }
    }
}

protocol QRScannerViewControllerDelegate: AnyObject {
    func didScanCode(_ code: String)
    func didFailWithError(_ error: Error)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerViewControllerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didFailWithError(NSError(domain: "QRScanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "No camera available"]))
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            delegate?.didFailWithError(NSError(domain: "QRScanner", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot create video input"]))
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            delegate?.didFailWithError(NSError(domain: "QRScanner", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"]))
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.didFailWithError(NSError(domain: "QRScanner", code: 4, userInfo: [NSLocalizedDescriptionKey: "Cannot add metadata output"]))
            return
        }

        captureSession = session

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func setupOverlay() {
        // Scan frame overlay
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .clear
        overlayView.layer.borderColor = UIColor.white.cgColor
        overlayView.layer.borderWidth = 2
        overlayView.layer.cornerRadius = 12
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            overlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            overlayView.widthAnchor.constraint(equalToConstant: 250),
            overlayView.heightAnchor.constraint(equalToConstant: 250)
        ])

        // Instruction label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "QR 코드를 프레임 안에 맞춰주세요"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: overlayView.bottomAnchor, constant: 24)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned else { return }

        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanCode(stringValue)
        }
    }
}

struct QRScannerSheet: View {
    let onCodeScanned: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            QRScannerView(onCodeScanned: onCodeScanned)
                .ignoresSafeArea()
                .navigationTitle("QR 스캔")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("취소") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
