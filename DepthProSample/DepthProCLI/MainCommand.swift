import Accelerate
import ArgumentParser
import CoreImage
import CoreML
import ImageIO
import UniformTypeIdentifiers

let targetSize = CGSize(width: 1536, height: 1536)
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
    let config = MLModelConfiguration()
    config.computeUnits = .cpuAndNeuralEngine
    let compiledURL = try await MLModel.compileModel(at: URL(filePath: model))
    let model = try MLModel(contentsOf: compiledURL, configuration: config)

    guard let inputImage = CIImage(contentsOf: URL(filePath: input)) else {
      print("Failed to load image.")
      throw ExitCode(EXIT_FAILURE)
    }
    print("Original image size \(inputImage.extent)")

    let resizedImage = inputImage.resized(to: targetSize)

    guard let pixelBuffer = context.render(resizedImage, pixelFormat: kCVPixelFormatType_32ARGB)
    else {
      print("Failed to create a pixel buffer.")
      throw ExitCode(EXIT_FAILURE)
    }

    let clock = ContinuousClock()
    let start = clock.now
    let featureProvider = try MLDictionaryFeatureProvider(dictionary: ["pixel_values": pixelBuffer])
    let result = try await model.prediction(from: featureProvider)
    guard
      let outputPixelBuffer = result.featureValue(for: "normalized_inverse_depth")?.imageBufferValue
    else {
      print("The model did not return a 'normalized_inverse_depth' feature with an image.")
      throw ExitCode(EXIT_FAILURE)
    }
    let duration = clock.now - start
    print("Model inference took \(duration.formatted(.units(allowed: [.seconds, .milliseconds])))")

    let castedBuffer = castPixelBuffer(outputPixelBuffer)!
    let normalizedBuffer = normalizePixelBuffer(castedBuffer)!

    var outputImage = CIImage(cvPixelBuffer: normalizedBuffer)
    outputImage = outputImage.resized(
      to: CGSize(width: inputImage.extent.width, height: inputImage.extent.height))
    context.writePNG(outputImage, to: URL(filePath: output))
  }
}
