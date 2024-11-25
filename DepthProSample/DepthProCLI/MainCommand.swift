import Accelerate
import ArgumentParser
import CoreImage
import CoreML
import ImageIO
import UniformTypeIdentifiers

func castPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
  let width = CVPixelBufferGetWidth(pixelBuffer)
  let height = CVPixelBufferGetHeight(pixelBuffer)
  let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

  guard pixelFormat == kCVPixelFormatType_OneComponent16Half else {
    print("Unsupported pixel format. This function requires a 16-bit half-precision pixel buffer.")
    return nil
  }

  var normalizedPixelBuffer: CVPixelBuffer?
  let attributes: [CFString: Any] = [
    kCVPixelBufferWidthKey: width,
    kCVPixelBufferHeightKey: height,
    kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_OneComponent32Float,
    kCVPixelBufferIOSurfacePropertiesKey: [:],
  ]

  CVPixelBufferCreate(
    kCFAllocatorDefault, width, height, kCVPixelFormatType_OneComponent32Float,
    attributes as CFDictionary, &normalizedPixelBuffer)

  guard let outputBuffer = normalizedPixelBuffer else {
    print("Failed to create output pixel buffer.")
    return nil
  }

  CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
  CVPixelBufferLockBaseAddress(outputBuffer, [])
  defer {
    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    CVPixelBufferUnlockBaseAddress(outputBuffer, [])
  }

  guard let inputBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
    let outputBaseAddress = CVPixelBufferGetBaseAddress(outputBuffer)
  else {
    print("Failed to get the base address of the pixel buffer.")
    return nil
  }

  let inputPointer = inputBaseAddress.bindMemory(to: UInt16.self, capacity: width * height)
  let outputPointer = outputBaseAddress.bindMemory(to: Float.self, capacity: width * height)

  let pixelCount = width * height

  for i in 0..<pixelCount {
    let halfValue = inputPointer[i]
    let floatValue = Float(halfToFloat(halfValue))
    outputPointer[i] = floatValue
  }

  return outputBuffer
}

func normalizePixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
  let width = CVPixelBufferGetWidth(pixelBuffer)
  let height = CVPixelBufferGetHeight(pixelBuffer)
  let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

  guard pixelFormat == kCVPixelFormatType_OneComponent32Float else {
    print("Unsupported pixel format. This function requires a 32-bit half-precision pixel buffer.")
    return nil
  }

  var normalizedPixelBuffer: CVPixelBuffer?
  let attributes: [CFString: Any] = [
    kCVPixelBufferWidthKey: width,
    kCVPixelBufferHeightKey: height,
    kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_OneComponent32Float,
    kCVPixelBufferIOSurfacePropertiesKey: [:],
  ]

  CVPixelBufferCreate(
    kCFAllocatorDefault, width, height, kCVPixelFormatType_OneComponent32Float,
    attributes as CFDictionary, &normalizedPixelBuffer)

  guard let outputBuffer = normalizedPixelBuffer else {
    print("Failed to create output pixel buffer.")
    return nil
  }

  CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
  CVPixelBufferLockBaseAddress(outputBuffer, [])
  defer {
    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    CVPixelBufferUnlockBaseAddress(outputBuffer, [])
  }

  guard let inputBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
    let outputBaseAddress = CVPixelBufferGetBaseAddress(outputBuffer)
  else {
    print("Failed to get the base address of the pixel buffer.")
    return nil
  }

  let inputPointer = inputBaseAddress.bindMemory(to: Float.self, capacity: width * height)
  let outputPointer = outputBaseAddress.bindMemory(to: Float.self, capacity: width * height)

  let pixelCount = width * height

  for i in 0..<pixelCount {
    outputPointer[i] = inputPointer[i] / 255.0
  }

  return outputBuffer
}

func halfToFloat(_ half: UInt16) -> Float {
  let sign = (half & 0x8000) >> 15
  let exponent = (half & 0x7C00) >> 10
  let fraction = half & 0x03FF

  if exponent == 0 {
    // Subnormal number or zero
    if fraction == 0 {
      return sign == 0 ? 0.0 : -0.0
    } else {
      let floatValue = Float(fraction) / 1024.0
      return sign == 0 ? floatValue : -floatValue
    }
  } else if exponent == 0x1F {
    // Inf or NaN
    if fraction == 0 {
      return sign == 0 ? Float.infinity : -Float.infinity
    } else {
      return Float.nan
    }
  }

  let floatExponent = Float(Int(exponent) - 15)
  let floatValue = (1.0 + Float(fraction) / 1024.0) * pow(2.0, floatExponent)

  return sign == 0 ? floatValue : -floatValue
}

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
