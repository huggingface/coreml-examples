import ArgumentParser
import CoreImage
import CoreML
import ImageIO
import UniformTypeIdentifiers

let targetSize = CGSize(width: 686, height: 518)
let context = CIContext()

@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "depth",
        abstract: "Performs depth estimation on an image."
    )

    @Option(name: .shortAndLong, help: "Depth model package file.")
    var model: String

    @Option(name: .shortAndLong, help: "The input image file.")
    var input: String

    @Option(name: .shortAndLong, help: "The output image file.")
    var output: String

    mutating func run() async throws {
        // Compile and load the model
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        let compiledURL = try await MLModel.compileModel(at: URL(filePath: model))
        let model = try MLModel(contentsOf: compiledURL, configuration: config)

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
            print("Failed to create a pixel buffer.")
            throw ExitCode(EXIT_FAILURE)
        }

        // Execute the model
        let clock = ContinuousClock()
        let start = clock.now
        let featureProvider = try MLDictionaryFeatureProvider(dictionary: ["image": pixelBuffer])
        let result = try await model.prediction(from: featureProvider)
        guard let outputPixelBuffer = result.featureValue(for: "depth")?.imageBufferValue else {
            print("The model did not return a 'depth' feature with an image.")
            throw ExitCode(EXIT_FAILURE)
        }
        let duration = clock.now - start
        print("Model inference took \(duration.formatted(.units(allowed: [.seconds, .milliseconds])))")

        // Undo the scale to match the original image size
        var outputImage = CIImage(cvPixelBuffer: outputPixelBuffer)
        outputImage = outputImage.resized(to: CGSize(width: inputImage.extent.width, height: inputImage.extent.height))

        // Save the depth image
        context.writePNG(outputImage, to: URL(filePath: output))
    }
}
