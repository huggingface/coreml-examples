import AVFoundation
import SwiftUI
import UIKit

struct ViewfinderView: UIViewRepresentable {
    var session: AVCaptureSession

    init(session: AVCaptureSession) {
        self.session = session
    }

    func makeUIView(context: Context) -> InnerView {
        let view = InnerView()
        view.session = session
        return view
    }

    func updateUIView(_ view: InnerView, context: Context) {
        view.session = session
    }

    final class InnerView: UIView {
        private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
        private var inputsObservation: NSKeyValueObservation?
        private var rotationObservation: NSKeyValueObservation?

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        var session: AVCaptureSession? {
            get {
                previewLayer.session
            }
            set {
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = newValue
                coordinateRotation()
                inputsObservation = previewLayer.session?.observe(\.inputs, options: .new) { [unowned self] _, _ in
                    Task { @MainActor in
                        self.coordinateRotation()
                    }
                }
            }
        }

        func coordinateRotation() {
            guard let input = session?.inputs.first as? AVCaptureDeviceInput else {
                rotationCoordinator = nil
                rotationObservation = nil
                return
            }

            rotationCoordinator = AVCaptureDevice.RotationCoordinator(
                device: input.device,
                previewLayer: layer
            )
            previewLayer.connection?.videoRotationAngle = rotationCoordinator!.videoRotationAngleForHorizonLevelPreview

            rotationObservation = rotationCoordinator!.observe(
                \.videoRotationAngleForHorizonLevelPreview,
                 options: .new
            ) { [unowned self] _, change in
                guard let angle = change.newValue else { return }
                self.previewLayer.connection?.videoRotationAngle = angle
            }
        }
    }
}
