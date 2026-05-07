//
//  QRCodeScannerView.swift
//  HaliSahaApp
//
//  AVFoundation tabanlı QR kod tarayıcı (UIViewControllerRepresentable).
//

import AVFoundation
import SwiftUI
import UIKit

// MARK: - QR Code Scanner View
struct QRCodeScannerView: UIViewControllerRepresentable {

    /// Başarılı tarama sonrası tetiklenir. Aynı kod tekrar okunmaz.
    var onCodeScanned: (String) -> Void
    /// Kullanıcı kamera izni vermezse veya cihaz desteklemezse tetiklenir.
    var onError: (ScannerError) -> Void
    /// Flaş açık/kapalı kontrolü.
    @Binding var isTorchOn: Bool

    enum ScannerError: Error, Equatable {
        case permissionDenied
        case unavailable
        case unknown
    }

    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let controller = QRCodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {
        uiViewController.setTorch(on: isTorchOn)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, QRCodeScannerViewControllerDelegate {
        let parent: QRCodeScannerView

        init(_ parent: QRCodeScannerView) {
            self.parent = parent
        }

        func scanner(_ scanner: QRCodeScannerViewController, didScan code: String) {
            parent.onCodeScanned(code)
        }

        func scanner(_ scanner: QRCodeScannerViewController, didFailWith error: ScannerError) {
            parent.onError(error)
        }
    }
}

// MARK: - Delegate Protocol
protocol QRCodeScannerViewControllerDelegate: AnyObject {
    func scanner(_ scanner: QRCodeScannerViewController, didScan code: String)
    func scanner(
        _ scanner: QRCodeScannerViewController, didFailWith error: QRCodeScannerView.ScannerError)
}

// MARK: - Scanner UIViewController
final class QRCodeScannerViewController: UIViewController {

    // MARK: - Properties
    weak var delegate: QRCodeScannerViewControllerDelegate?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureDevice: AVCaptureDevice?
    private var hasReportedScan = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        requestPermissionAndConfigure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasReportedScan = false
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        if let connection = previewLayer?.connection,
            connection.isVideoOrientationSupported
        {
            connection.videoOrientation = .portrait
        }
    }

    // MARK: - Permission
    private func requestPermissionAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureSession()
                    } else {
                        self?.delegate?.scanner(self!, didFailWith: .permissionDenied)
                    }
                }
            }
        case .denied, .restricted:
            delegate?.scanner(self, didFailWith: .permissionDenied)
        @unknown default:
            delegate?.scanner(self, didFailWith: .unknown)
        }
    }

    // MARK: - Configure Capture
    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            delegate?.scanner(self, didFailWith: .unavailable)
            return
        }
        captureDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard captureSession.canAddInput(input) else {
                delegate?.scanner(self, didFailWith: .unavailable)
                return
            }
            captureSession.addInput(input)

            let metadataOutput = AVCaptureMetadataOutput()
            guard captureSession.canAddOutput(metadataOutput) else {
                delegate?.scanner(self, didFailWith: .unavailable)
                return
            }
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]

            // Preview Layer
            let preview = AVCaptureVideoPreviewLayer(session: captureSession)
            preview.frame = view.bounds
            preview.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(preview, at: 0)
            previewLayer = preview

            startSession()
        } catch {
            delegate?.scanner(self, didFailWith: .unknown)
        }
    }

    // MARK: - Session Control
    private func startSession() {
        guard !captureSession.isRunning, captureSession.inputs.isEmpty == false else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    private func stopSession() {
        guard captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    // MARK: - Torch
    func setTorch(on: Bool) {
        guard let device = captureDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            // Sessizce yoksay
        }
    }

    // MARK: - Public — yeni tarama için yeniden hazır hale getir
    func reset() {
        hasReportedScan = false
        startSession()
    }
}

// MARK: - Metadata Delegate
extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasReportedScan,
            let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            metadata.type == .qr,
            let code = metadata.stringValue
        else { return }

        hasReportedScan = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        delegate?.scanner(self, didScan: code)
    }
}
