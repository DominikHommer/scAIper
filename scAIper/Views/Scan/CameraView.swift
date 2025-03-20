//
//  CameraView.swift
//  scAIper
//
//  Created by Dominik Hommer on 18.03.25.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isShown: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .black

        let session = AVCaptureSession()
        session.sessionPreset = .photo

        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Fehler: Keine Rückkamera gefunden")
            return viewController
        }

        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            let photoOutput = AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            context.coordinator.photoOutput = photoOutput
        } catch {
            print("Fehler beim Zugriff auf die Kamera: \(error)")
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        previewLayer.frame = viewController.view.bounds
        previewLayer.backgroundColor = UIColor.black.cgColor
        viewController.view.layer.addSublayer(previewLayer)

        let buttonSize: CGFloat = 75
        let captureButton = UIButton(type: .custom)
        captureButton.frame = CGRect(
            x: (viewController.view.frame.width - buttonSize) / 2,
            y: viewController.view.frame.height - buttonSize - 40,
            width: buttonSize,
            height: buttonSize)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = buttonSize / 2
        

        let ringLayer = CAShapeLayer()
        let ringPath = UIBezierPath(
            arcCenter: CGPoint(x: buttonSize / 2, y: buttonSize / 2),
            radius: buttonSize / 2 + 6,
            startAngle: 0,
            endAngle: CGFloat.pi * 2,
            clockwise: true
        )
        ringLayer.path = ringPath.cgPath
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.strokeColor = UIColor.white.cgColor
        ringLayer.lineWidth = 4.0
        captureButton.layer.insertSublayer(ringLayer, below: captureButton.layer)
        
        context.coordinator.captureButtonRing = ringLayer

        captureButton.addTarget(context.coordinator, action: #selector(Coordinator.captureButtonDown(_:)), for: .touchDown)
        captureButton.addTarget(context.coordinator, action: #selector(Coordinator.captureButtonUp(_:)), for: .touchUpInside)
        captureButton.addTarget(context.coordinator, action: #selector(Coordinator.captureButtonUp(_:)), for: .touchUpOutside)
        captureButton.addTarget(context.coordinator, action: #selector(Coordinator.capturePhoto), for: .touchUpInside)
        

        viewController.view.addSubview(captureButton)

        Task.detached(priority: .userInitiated) {
            session.startRunning()
        }

        context.coordinator.captureSession = session
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Keine Aktualisierung nötig
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        let parent: CameraView
        var captureSession: AVCaptureSession?
        var photoOutput = AVCapturePhotoOutput()
        var captureButtonRing: CAShapeLayer?

        init(parent: CameraView) {
            self.parent = parent
            super.init()
        }

        @objc func capturePhoto() {
            guard let captureSession = captureSession, captureSession.isRunning else {
                print("Fehler: Keine aktive Kamera-Session verfügbar")
                return
            }
            
            let settings = AVCapturePhotoSettings()
            Task { @MainActor in
                self.photoOutput.capturePhoto(with: settings, delegate: self)
                self.triggerHapticFeedback()
            }
        }
        @objc func captureButtonDown(_ sender: UIButton) {
            sender.backgroundColor = UIColor.lightGray
            captureButtonRing?.strokeColor = UIColor.lightGray.cgColor
        }

        @objc func captureButtonUp(_ sender: UIButton) {
            UIView.animate(withDuration: 0.2) {
                sender.backgroundColor = UIColor.white
                self.captureButtonRing?.strokeColor = UIColor.white.cgColor
            }
        }
        
        

        func photoOutput(_ output: AVCapturePhotoOutput,
                         didFinishProcessingPhoto photo: AVCapturePhoto,
                         error: Error?) {
            guard let imageData = photo.fileDataRepresentation(),
                  let uiImage = UIImage(data: imageData)
            else {
                print("Fehler: Konnte das Foto nicht verarbeiten")
                return
            }
            parent.image = uiImage
            parent.isShown = false
        }

        func triggerHapticFeedback() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
    }
}

#Preview {
    CameraView(image: .constant(nil), isShown: .constant(true))
}

