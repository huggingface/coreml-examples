import CoreImage
import CoreML
import SwiftUI
import UniformTypeIdentifiers
import Vision

let targetSize = CGSize(width: 1536, height: 1536)
let context = CIContext()
let outputOptions = ["Normalized Inverse Depth", "Meters"]

struct ContentView: View {
    @State private var pixelBuffer: CVPixelBuffer?
    @State private var originalSize: CGSize?
    @State private var selectedImage: Image?
    @State private var processedImage: Image?
    @State private var processedCGImage: CGImage?
    @State private var isImagePickerPresented = false
    @State private var isImageExporterPresented = false
    @State private var isProcessing = false
    @State private var selectedOutput = "Normalized Inverse Depth"

    var body: some View {
        HStack {
            VStack {
                GeometryReader { geometry in
                    if let image = selectedImage {
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                            .cornerRadius(10)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                HStack {
                    Button("Select Image") {
                        isImagePickerPresented = true
                    }
                    .fileImporter(
                        isPresented: $isImagePickerPresented, allowedContentTypes: [.png, .jpeg],
                        allowsMultipleSelection: false,
                        onCompletion: { results in
                            switch results {
                            case .success(let fileurls):
                                if fileurls.count > 0 {
                                    isProcessing = true
                                    loadImage(inputURL: fileurls.first!)
                                    Task.detached(priority: .userInitiated) {
                                        do {
                                            try await processImage()
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }

                            case .failure(let error):
                                print(error)
                            }
                        }
                    )
                    .disabled(isProcessing)

                    Picker("Select an option", selection: $selectedOutput) {
                        ForEach(outputOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedOutput) {
                        if selectedImage != nil {
                            isProcessing = true
                            Task.detached(priority: .userInitiated) {
                                do {
                                    try await processImage()
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                    .disabled(isProcessing)
                }

            }
            VStack {
                GeometryReader { geometry in
                    if isProcessing {
                        ProgressView("Processing...")
                            .cornerRadius(10)
                            .foregroundColor(.gray)
                            .shadow(radius: 10)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else if let image = processedImage {
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .foregroundColor(.gray)
                    }
                }

                if processedImage == nil {
                    Button("Save Image") {
                        isImageExporterPresented = true
                    }
                    .disabled(true)
                } else {
                    Button("Save Image") {
                        isImageExporterPresented = true
                    }
                    .fileExporter(
                        isPresented: $isImageExporterPresented,
                        document: ImageDocument(image: processedCGImage!),
                        contentType: .png,
                        onCompletion: { (result) in
                            if case .failure = result {
                                print("Export Failure")
                            }
                        }
                    )
                    .disabled(isProcessing)
                }
            }
        }
        .padding()
    }

    func loadImage(inputURL: URL) {
        guard let inputImage = CIImage(contentsOf: inputURL) else {
            print("Failed to load image.")
            return
        }

        selectedImage = Image(
            decorative: context.createCGImage(inputImage, from: inputImage.extent)!, scale: 1.0,
            orientation: .up)

        self.originalSize = inputImage.extent.size

        let resizedImage = inputImage.resized(to: targetSize)

        guard let pixelBuffer = context.render(resizedImage, pixelFormat: kCVPixelFormatType_32ARGB)
        else {
            print("Failed to create a pixel buffer.")
            return
        }

        self.pixelBuffer = pixelBuffer
    }

    func processImage() async throws {
        guard pixelBuffer != nil else { return }

        switch selectedOutput {
        case "Normalized Inverse Depth":
            try await processImageNID()
        case "Meters":
            try await processImageMeters()
        case _:
            print("output type not supported")
            return
        }

        self.processedImage = Image(
            decorative: self.processedCGImage!, scale: 1.0, orientation: .up)
        isProcessing = false
    }

    private func processImageNID() async throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        let model = try DepthProNormalizedInverseDepth_pruned10_Qlinear(configuration: config)
        let featureProvider = DepthProNormalizedInverseDepth_pruned10_QlinearInput(pixel_values: pixelBuffer!)

        let result = try await model.prediction(input: featureProvider)
        guard
            let outputPixelBuffer = result.featureValue(for: "normalized_inverse_depth")?
                .imageBufferValue
        else {
            print("The model did not return a 'normalized_inverse_depth' feature with an image.")
            return
        }

        let castedBuffer = castPixelBuffer(outputPixelBuffer)!
        let normalizedBuffer = normalizePixelBuffer(castedBuffer)!

        var outputImage = CIImage(cvPixelBuffer: normalizedBuffer)
        outputImage = outputImage.resized(
            to: CGSize(width: originalSize!.width, height: originalSize!.height))

        self.processedCGImage = context.createCGImage(outputImage, from: outputImage.extent)!
    }

    private func processImageMeters() async throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        let model = try DepthPro_pruned10_Qlinear(configuration: config)
        let featureProvider = DepthPro_pruned10_QlinearInput(
            pixel_values: pixelBuffer!,
            original_widths: MLShapedArray(
                repeating: Float16(originalSize!.width), shape: [1, 1, 1, 1]))

        let result = try await model.prediction(input: featureProvider)
        guard
            let outputDepthMeters = result.featureValue(for: "depth_meters")?.multiArrayValue
        else {
            print("The model did not return a 'depth_meters' feature with an image.")
            return
        }

        var outputImage = arrayToColoredMap(outputDepthMeters)!
        outputImage = outputImage.resized(
            to: CGSize(width: originalSize!.width, height: originalSize!.height))!

        self.processedCGImage = outputImage
    }
}

struct ImageDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.png]

    var image: CGImage

    init(image: CGImage) {
        self.image = image
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadCorruptFile)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        else {
            fatalError("Failed to create color space or CIImage.")
        }

        let ciImage = CIImage(cgImage: image)

        guard
            let pngData = context.pngRepresentation(
                of: ciImage, format: .ABGR8, colorSpace: colorSpace)
        else {
            fatalError("Failed to generate PNG representation.")
        }

        return FileWrapper(regularFileWithContents: pngData)
    }

}
