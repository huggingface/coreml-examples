import AVFoundation
import Foundation
import SwiftUI
import UIKit

struct ViewfinderView: UIViewRepresentable {
    var session: AVCaptureSession
    @Binding var prediction: [PredictionResult]?


    init(session: AVCaptureSession, prediction: Binding<[PredictionResult]?>) {
        self.session = session
        self._prediction = prediction
    }

    func makeUIView(context: Context) -> InnerView {
        let view = InnerView()
        view.session = session

        return view
    }

    func updateUIView(_ view: InnerView, context: Context) {
        view.session = session
        view.prediction = prediction ?? []
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

        var prediction: [PredictionResult] = [] {
               didSet {
                   updatePredictionLabel()
               }
           }

           private let predictionLabel: UILabel = {
               let label = UILabel()
               label.numberOfLines = 3
               label.textColor = .white
               label.font = UIFont.systemFont(ofSize: 20)
               label.textAlignment = .center
               label.backgroundColor = UIColor(white: 0, alpha: 0.7)
               label.layer.cornerRadius = 8
               label.clipsToBounds = true
               return label
           }()

           override init(frame: CGRect) {
               super.init(frame: frame)
               setupPredictionLabel()
           }

           required init?(coder: NSCoder) {
               super.init(coder: coder)
               setupPredictionLabel()
           }

           private func setupPredictionLabel() {
               addSubview(predictionLabel)
               predictionLabel.translatesAutoresizingMaskIntoConstraints = false
               NSLayoutConstraint.activate([
                   predictionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                   predictionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                   predictionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32),
                   predictionLabel.heightAnchor.constraint(equalToConstant: 120)
               ])
           }

        private func updatePredictionLabel() {
            let attributedPredictionText = NSMutableAttributedString()

            for (index, result) in prediction.enumerated() {
                let probability = result.probability
                let predictionText = "\(result.label): \(String(format: "%.2f", probability))"

                let color = getColorForProbability(probability)
                let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
                let attributedText = NSAttributedString(string: predictionText, attributes: attributes)

                attributedPredictionText.append(attributedText)

                if index < prediction.count - 1 {
                    attributedPredictionText.append(NSAttributedString(string: "\n"))
                }
            }

            predictionLabel.attributedText = attributedPredictionText
        }

        private func getColorForProbability(_ probability: Double) -> UIColor {
            let mass = 1 + sin(probability * Double.pi)

            if probability >= 0.5 {
                return UIColor(red: mass - 1, green: 1, blue: 0, alpha: 1.0)
            }else {
                return UIColor(red: 1, green: mass - 1, blue: 0, alpha: 1.0)
            }
        }

    }
}
