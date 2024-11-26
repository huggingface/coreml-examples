import CoreImage
import CoreML
import SwiftUI
import UniformTypeIdentifiers
import Vision

let targetSize = CGSize(width: 1536, height: 1536)
let context = CIContext()

struct ContentView: View {
    @State private var pixelBuffer: CVPixelBuffer?
    @State private var originalSize: CGSize?
    @State private var selectedImage: Image?
    @State private var processedImage: Image?
    @State private var processedCGImage: CGImage?
    @State private var isImagePickerPresented = false
    @State private var isImageExporterPresented = false

    var body: some View {
        HStack {
            VStack {
                if let image = selectedImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .cornerRadius(10)
                }

                Button("Select Image") {
                    isImagePickerPresented = true
                }
                .fileImporter(
                    isPresented: $isImagePickerPresented, allowedContentTypes: [.png, .jpeg],
                    allowsMultipleSelection: false,
                    onCompletion: {
                        results in
                        switch results {
                        case .success(let fileurls):
                            if fileurls.count > 0 {
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
                    })
            }
            VStack {
                if let image = processedImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                        .cornerRadius(10)
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
                            if case .success = result {
                                print("Export Success")
                            } else {
                                print("Export Failure")
                            }
                        }
                    )
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
        guard let pb = pixelBuffer else { return }

        let model = try DepthProNIDPrunedQuantized()
        let featureProvider = DepthProNIDPrunedQuantizedInput(pixel_values: pb)

        let result = try await model.prediction(input: featureProvider)
        guard
            let outputPixelBuffer = result.featureValue(for: "normalized_inverse_depth")?.imageBufferValue
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
        self.processedImage = Image(decorative: self.processedCGImage!, scale: 1.0, orientation: .up)
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
            let pngData = context.pngRepresentation(of: ciImage, format: .ABGR8, colorSpace: colorSpace)
        else {
            fatalError("Failed to generate PNG representation.")
        }

        return FileWrapper(regularFileWithContents: pngData)
    }

}
