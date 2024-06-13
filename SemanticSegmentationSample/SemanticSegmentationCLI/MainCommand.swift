import ArgumentParser
import CoreImage
import CoreML
import ImageIO
import UniformTypeIdentifiers

let targetSize = CGSize(width: 448, height: 448)
let context = CIContext()

@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "semantic",
        abstract: "Performs semantic segmentation on an image."
    )

    @Option(name: .shortAndLong, help: "Semantic segmentation model package file.")
    var model: String

    @Option(name: .shortAndLong, help: "The input image file.")
    var input: String

    @Option(name: .shortAndLong, help: "The output PNG image file, showing the segmentation map overlaid on top of the original image.")
    var output: String
    
    @Option(name: [.long, .customShort("k")], help: "The output file name for the segmentation mask.")
    var mask: String? = nil

    mutating func run() async throws {
        // Compile and load the model
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        let compiledURL = try await MLModel.compileModel(at: URL(filePath: model))
        let model = try MLModel(contentsOf: compiledURL, configuration: config)
        let postProcessor = try DETRPostProcessor(model: model)

        // Load the input image
        guard let inputImage = CIImage(contentsOf: URL(filePath: input)) else {
            print("Failed to load image.")
            throw ExitCode(EXIT_FAILURE)
        }
        print("Original image size \(inputImage.extent)")

        // Resize the image to match the model's expected input
        let resizedImage = inputImage.resized(to: targetSize)

        // Convert to a pixel buffer
        guard let pixelBuffer = context.render(resizedImage, pixelFormat: kCVPixelFormatType_32ARGB) else {
            print("Failed to create pixel buffer for input image.")
            throw ExitCode(EXIT_FAILURE)
        }

        // Execute the model
        let clock = ContinuousClock()
        let start = clock.now
        let featureProvider = try MLDictionaryFeatureProvider(dictionary: ["image": pixelBuffer])
        let result = try await model.prediction(from: featureProvider)
        guard let semanticPredictions = result.featureValue(for: "semanticPredictions")?.shapedArrayValue(of: Int32.self) else {
            print("The model did not return a 'semanticPredictions' output feature.")
            throw ExitCode(EXIT_FAILURE)
        }
        let duration = clock.now - start
        print("Model inference took \(duration.formatted(.units(allowed: [.seconds, .milliseconds])))")

        guard let semanticImage = try? postProcessor.semanticImage(semanticPredictions: semanticPredictions) else {
            print("Error post-processing semanticPredictions")
            throw ExitCode(EXIT_FAILURE)
        }

        // Undo the scale to match the original image size
        // TODO: Bilinear?
        let outputImage = semanticImage.resized(to: CGSize(width: inputImage.extent.width, height: inputImage.extent.height))
        // Save mask if we need to
        if let mask = mask {
            context.writePNG(outputImage, to: URL(filePath: mask))
        }

        // Display mask over original
        guard let outputImage = outputImage.withAlpha(0.5)?.composited(over: inputImage) else {
            print("Failed to blend mask.")
            throw ExitCode(EXIT_FAILURE)
        }
        context.writePNG(outputImage, to: URL(filePath: output))
    }
}
