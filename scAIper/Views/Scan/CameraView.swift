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

        // Erstelle den Preview-Layer, der das komplette View ausfüllt
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect  // passt das Bild an, sodass der gesamte Inhalt zu sehen ist
        previewLayer.frame = viewController.view.bounds
        previewLayer.backgroundColor = UIColor.black.cgColor
        viewController.view.layer.addSublayer(previewLayer)

        // Capture-Button positioniert im unteren Bereich
        let captureButton = UIButton(frame: CGRect(
            x: viewController.view.frame.midX - 40,
            y: viewController.view.frame.height * 0.82,
            width: 80,
            height: 80
        ))
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 40
        captureButton.addTarget(
            context.coordinator,
            action: #selector(Coordinator.capturePhoto),
            for: .touchUpInside
        )
        viewController.view.addSubview(captureButton)

        // Starte die Session im Hintergrund
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

