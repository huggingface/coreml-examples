import ArgumentParser
import CoreImage
import CoreML
import ImageIO
import UniformTypeIdentifiers
import Accelerate // For efficient calculations

func analyzePixelBuffer(_ pixelBuffer: CVPixelBuffer) -> (min: Float, max: Float, mean: Float, median: Float) {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    
    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
        fatalError("Failed to get base address of pixel buffer.")
    }

    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

    guard pixelFormat == kCVPixelFormatType_OneComponent16Half || pixelFormat == kCVPixelFormatType_OneComponent32Float else {
        fatalError("Unsupported pixel format. Only 16-bit half-float or 32-bit float is supported.")
    }

    let count = width * height
    var values: [Float] = []

    if pixelFormat == kCVPixelFormatType_OneComponent32Float {
        // For 32-bit float
        let data = baseAddress.bindMemory(to: Float.self, capacity: count)
        values = Array(UnsafeBufferPointer(start: data, count: count))
    } else if pixelFormat == kCVPixelFormatType_OneComponent16Half {
        // For 16-bit half-float
        let data = baseAddress.bindMemory(to: UInt16.self, capacity: count)
        
        var sourceBuffer = vImage_Buffer(
            data: UnsafeMutableRawPointer(mutating: data),
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: CVPixelBufferGetBytesPerRow(pixelBuffer)
        )
        
        // Create a destination buffer for 32-bit float values
        var floatValues = [Float](repeating: 0, count: count)
        var destinationBuffer = vImage_Buffer(
            data: &floatValues,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: width * MemoryLayout<Float>.size
        )
        
        // Perform the conversion
        vImageConvert_Planar16FtoPlanarF(&sourceBuffer, &destinationBuffer, vImage_Flags(kvImageNoFlags))
        values = floatValues
    }

    // Calculate statistics
    let min = values.min() ?? 0
    let max = values.max() ?? 0
    let mean = values.reduce(0, +) / Float(count)
    let median = values.sorted()[count / 2]

    return (min, max, mean, median)
}

//func printPixelFormatTypes() {
//    let pixelFormats: [(String, OSType)] = [
//        ("kCVPixelFormatType_1Monochrome", kCVPixelFormatType_1Monochrome),
//        ("kCVPixelFormatType_2Indexed", kCVPixelFormatType_2Indexed),
//        ("kCVPixelFormatType_4Indexed", kCVPixelFormatType_4Indexed),
//        ("kCVPixelFormatType_8Indexed", kCVPixelFormatType_8Indexed),
//        ("kCVPixelFormatType_1IndexedGray_WhiteIsZero", kCVPixelFormatType_1IndexedGray_WhiteIsZero),
//        ("kCVPixelFormatType_2IndexedGray_WhiteIsZero", kCVPixelFormatType_2IndexedGray_WhiteIsZero),
//        ("kCVPixelFormatType_4IndexedGray_WhiteIsZero", kCVPixelFormatType_4IndexedGray_WhiteIsZero),
//        ("kCVPixelFormatType_8IndexedGray_WhiteIsZero", kCVPixelFormatType_8IndexedGray_WhiteIsZero),
//        ("kCVPixelFormatType_16BE555", kCVPixelFormatType_16BE555),
//        ("kCVPixelFormatType_16LE555", kCVPixelFormatType_16LE555),
//        ("kCVPixelFormatType_16LE5551", kCVPixelFormatType_16LE5551),
//        ("kCVPixelFormatType_16BE565", kCVPixelFormatType_16BE565),
//        ("kCVPixelFormatType_16LE565", kCVPixelFormatType_16LE565),
//        ("kCVPixelFormatType_24RGB", kCVPixelFormatType_24RGB),
//        ("kCVPixelFormatType_24BGR", kCVPixelFormatType_24BGR),
//        ("kCVPixelFormatType_32ARGB", kCVPixelFormatType_32ARGB),
//        ("kCVPixelFormatType_32BGRA", kCVPixelFormatType_32BGRA),
//        ("kCVPixelFormatType_32ABGR", kCVPixelFormatType_32ABGR),
//        ("kCVPixelFormatType_32RGBA", kCVPixelFormatType_32RGBA),
//        ("kCVPixelFormatType_64ARGB", kCVPixelFormatType_64ARGB),
//        ("kCVPixelFormatType_48RGB", kCVPixelFormatType_48RGB),
//        ("kCVPixelFormatType_32AlphaGray", kCVPixelFormatType_32AlphaGray),
//        ("kCVPixelFormatType_16Gray", kCVPixelFormatType_16Gray),
//        ("kCVPixelFormatType_30RGB", kCVPixelFormatType_30RGB),
//        ("kCVPixelFormatType_422YpCbCr8", kCVPixelFormatType_422YpCbCr8),
//        ("kCVPixelFormatType_4444YpCbCrA8", kCVPixelFormatType_4444YpCbCrA8),
//        ("kCVPixelFormatType_4444YpCbCrA8R", kCVPixelFormatType_4444YpCbCrA8R),
//        ("kCVPixelFormatType_4444AYpCbCr8", kCVPixelFormatType_4444AYpCbCr8),
//        ("kCVPixelFormatType_4444AYpCbCr16", kCVPixelFormatType_4444AYpCbCr16),
//        ("kCVPixelFormatType_444YpCbCr8", kCVPixelFormatType_444YpCbCr8),
//        ("kCVPixelFormatType_422YpCbCr16", kCVPixelFormatType_422YpCbCr16),
//        ("kCVPixelFormatType_422YpCbCr10", kCVPixelFormatType_422YpCbCr10),
//        ("kCVPixelFormatType_444YpCbCr10", kCVPixelFormatType_444YpCbCr10),
//        ("kCVPixelFormatType_420YpCbCr8Planar", kCVPixelFormatType_420YpCbCr8Planar),
//        ("kCVPixelFormatType_420YpCbCr8PlanarFullRange", kCVPixelFormatType_420YpCbCr8PlanarFullRange),
//        ("kCVPixelFormatType_422YpCbCr_4A_8BiPlanar", kCVPixelFormatType_422YpCbCr_4A_8BiPlanar),
//        ("kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange", kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),
//        ("kCVPixelFormatType_420YpCbCr8BiPlanarFullRange", kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
//        ("kCVPixelFormatType_422YpCbCr8_yuvs", kCVPixelFormatType_422YpCbCr8_yuvs),
//        ("kCVPixelFormatType_422YpCbCr8FullRange", kCVPixelFormatType_422YpCbCr8FullRange),
//        ("kCVPixelFormatType_OneComponent8", kCVPixelFormatType_OneComponent8),
//        ("kCVPixelFormatType_TwoComponent8", kCVPixelFormatType_TwoComponent8),
//        ("kCVPixelFormatType_OneComponent16Half", kCVPixelFormatType_OneComponent16Half),
//        ("kCVPixelFormatType_OneComponent32Float", kCVPixelFormatType_OneComponent32Float),
//        ("kCVPixelFormatType_TwoComponent16Half", kCVPixelFormatType_TwoComponent16Half),
//        ("kCVPixelFormatType_TwoComponent32Float", kCVPixelFormatType_TwoComponent32Float),
//        ("kCVPixelFormatType_64RGBAHalf", kCVPixelFormatType_64RGBAHalf),
//        ("kCVPixelFormatType_128RGBAFloat", kCVPixelFormatType_128RGBAFloat)
//    ]
//
//    for (name, pixelFormat) in pixelFormats {
//        let fourCC = String(format: "%c%c%c%c",
//                            (pixelFormat >> 24) & 0xFF,
//                            (pixelFormat >> 16) & 0xFF,
//                            (pixelFormat >> 8) & 0xFF,
//                            pixelFormat & 0xFF)
//        print("\(name): \(pixelFormat) (FourCC: \(fourCC))")
//    }
//}


func normalizePixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
    
    guard pixelFormat == kCVPixelFormatType_OneComponent16Half else {
        print("Unsupported pixel format. This function requires a 16-bit half-precision pixel buffer.")
        return nil
    }
    
    // Create a new pixel buffer for the output
    var normalizedPixelBuffer: CVPixelBuffer?
    let attributes: [CFString: Any] = [
        kCVPixelBufferWidthKey: width,
        kCVPixelBufferHeightKey: height,
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_OneComponent32Float,
        kCVPixelBufferIOSurfacePropertiesKey: [:]
    ]
    
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_OneComponent32Float, attributes as CFDictionary, &normalizedPixelBuffer)
    
    guard let outputBuffer = normalizedPixelBuffer else {
        print("Failed to create output pixel buffer.")
        return nil
    }
    
    // Lock the input and output buffers
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    CVPixelBufferLockBaseAddress(outputBuffer, [])
    defer {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        CVPixelBufferUnlockBaseAddress(outputBuffer, [])
    }
    
    guard let inputBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
          let outputBaseAddress = CVPixelBufferGetBaseAddress(outputBuffer) else {
        print("Failed to get the base address of the pixel buffer.")
        return nil
    }
    
    let inputPointer = inputBaseAddress.bindMemory(to: UInt16.self, capacity: width * height)
    let outputPointer = outputBaseAddress.bindMemory(to: Float.self, capacity: width * height)
    
    let pixelCount = width * height

    for i in 0..<pixelCount {
        let halfValue = inputPointer[i]
        let floatValue = Float(halfToFloat(halfValue)) / 255.0
        outputPointer[i] = floatValue
    }
    
    return outputBuffer
}

// Helper function to convert a 16-bit half-precision float to 32-bit float
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

    // Normalized number
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
        
        // Sanity Check initial image
        // var outputImage = CIImage(cvPixelBuffer: pixelBuffer)
        // context.writePNG(outputImage, to: URL(filePath: output))

        // Execute the model
        let clock = ContinuousClock()
        let start = clock.now
        let featureProvider = try MLDictionaryFeatureProvider(dictionary: ["pixel_values": pixelBuffer])
        let result = try await model.prediction(from: featureProvider)
        guard let outputPixelBuffer = result.featureValue(for: "normalized_inverse_depth")?.imageBufferValue else {
            print("The model did not return a 'normalized_inverse_depth' feature with an image.")
            throw ExitCode(EXIT_FAILURE)
        }
        let duration = clock.now - start
        print("Model inference took \(duration.formatted(.units(allowed: [.seconds, .milliseconds])))")
        
        var stats = analyzePixelBuffer(outputPixelBuffer)
        print("Depth Statistics: Min=\(stats.min), Max=\(stats.max), Mean=\(stats.mean), Median=\(stats.median)")
        
        let new_pb = normalizePixelBuffer(outputPixelBuffer)!
        
        stats = analyzePixelBuffer(new_pb)
        print("Depth Statistics2: Min=\(stats.min), Max=\(stats.max), Mean=\(stats.mean), Median=\(stats.median)")
        
        var outputImage = CIImage(cvPixelBuffer: new_pb)
        outputImage = outputImage.resized(to: CGSize(width: inputImage.extent.width, height: inputImage.extent.height))
        context.writePNG(outputImage, to: URL(filePath: output))
//
//        guard let output8BitPixelBuffer = convertTo8BitPixelBuffer(from: outputPixelBuffer) else {
//            print("Failed to convert pixel buffer to 8-bit.")
//            throw ExitCode(EXIT_FAILURE)
//        }
//
//        // Undo the scale to match the original image size
//        var outputImage = CIImage(cvPixelBuffer: output8BitPixelBuffer)
////        outputImage = outputImage.resized(to: CGSize(width: inputImage.extent.width, height: inputImage.extent.height))
//
//        // Save the depth image
//        context.writePNG(outputImage, to: URL(filePath: output))
    }
}
